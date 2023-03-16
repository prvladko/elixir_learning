defmodule Chat.DbRoom do
  @moduledoc """
  A `Chat.Room` behaviour implementation.

  It uses a Postgres database underneath, so standard configuration is required,
  could be in a `Chat.Room` application. Please note that rooms do **NOT** get
  persisted on every message. Please set a task to persist room with `persist/1`
  function.

  All callbacks are documented in `Chat.Room` module, please refer to it for
  functions documentation.
  """
  @behaviour Chat.Room
  alias Chat.DbRoom.{Room, Member, Repo}
  require Ecto.Query

  @typedoc """
  Chat room state type which is a tuple of a Room struct and a list of Member
  structs.
  """
  @type state :: {%Room{}, list(%Member{})}

  @typedoc """
  A standard :error, reason tuple telling that the member passed to a function
  does not belong to the room.
  """
  @type not_a_member_error() :: {:error, String.t()}

  @spec create(admin :: pos_integer(),
               name  :: String.t() | nil,
               state :: state())
                     :: {:ok, state()}
  @impl true
  def create(member_id, name, _state) do
    Repo.transaction(fn ->
      {:ok, room} =
        %Room{}
        |> Room.changeset(%{name: name})
        |> Repo.insert()
      IO.inspect type = Repo.get_by!(Member.Type, [name: "admin"])
      {:ok, member} =
        %Member{}
        |> Member.changeset(%{
          room_id: room.id,
          member_id: member_id,
          admin: true,
          type_id: type.id})
        |> Repo.insert()
      {room, [member]}
    end)
  end

  @spec list(member_id :: pos_integer()) :: [String.t()]
  @impl true
  def list(member_id) do
    rooms =
      Ecto.Query.from(
        m in Member,
        inner_join: r in Room,
        on: m.member_id == ^member_id and r.id == m.room_id,
        select: r.name)
      |> Repo.all()
    {:ok, rooms}
  end

  @doc """
  Please make sure you pass an existing member struct to this function as it's
  not possible to check it from it! Adds the member to a members list with
  type specified in opts argument. Returns {:ok, ecto_stru}
  """
  @spec add_member(member_id :: pos_integer(),
                   type      :: String.t(),
                   admin     :: boolean(),
                   state     :: state())
                             :: {:ok, state()} | {:error, String.t()}
  @impl true
  def add_member(member_id, type \\ "spectrator", admin, {room, members}) do
    type = Repo.get_by!(Member.Type, [name: type])
    {:ok, member} =
      %Member{}
      |> Member.changeset(%{room_id: room.id,
                            member_id: member_id,
                            admin: admin,
                            type_id: type.id})
      |> Repo.insert()
    {:ok, {room, [member | members]}}
  end

  @spec remove_member(member_id :: pos_integer(), state :: state())
  ::{:ok, state()} | not_a_member_error()
  @impl true

  def remove_member(member_id, {room, members}) do
    member = fetch_member(member_id, members)
    if member != nil and member in members do
      Ecto.Adapters.SQL.query(Repo,
        "delete from members where member_id = #{member_id}
         and room_id = #{room.id}")
      members = List.delete(members, member)
      {:ok, {room, members}}
    else
      not_a_member_error(member_id, room.id)
    end
  end

  @spec member?(member :: pos_integer(), state :: state()) :: boolean()
  @impl true
  def member?(member, {_room, members}) do
    member in members
  end

  @spec send_message(member_id :: pos_integer(),
                     message   :: String.t(),
                     state :: state()) :: {:ok, state()} | not_a_member_error()
  @impl true
  def send_message(member_id, message, {room, members}) when is_binary(message) do
    member = fetch_member(member_id, members)
    if member != nil and member in members do
      room = update_in(room.messages, &(Enum.join([&1, message], "\n")))
      {:ok, {room, members}}
    else
      not_a_member_error(member, room.id)
    end
  end

  @spec messages(state :: state()) :: String.t()
  @impl true
  def messages({room, _members}) do
    {:ok, room.messages}
  end

  @spec persist(state :: state()) :: :ok | :error
  @impl true
  def persist({room, _members}) do
    stored_room = Repo.get(Room, room.id)
    {status, _} = stored_room \
    |> Room.changeset(%{messages: room.messages})
    |> Repo.update()
    status
  end

  @spec list_members(state :: state()) :: [String.t()]
  @impl true
  def list_members({_room, members}) do
    members = for %_Member{name: name} <- members, do: name
    {:ok, members}
  end

  @spec search_room(params :: keyword()) :: list(%Room{})
  @impl true
  def search_room(params) when is_list(params) do
    name = params[:name]
    member_id = params[:member_id]
    Ecto.Query.from(
      m in Member,
      inner_join: r in Room,
      on: m.member_id == ^member_id and r.name == ^name and r.id == m.room_id,
      select: {r.name, m.admin})
    |> Repo.all()
  end

  @spec is_admin?(member_id :: pos_integer(), state :: state()) :: boolean()
  @impl true
  def is_admin?(member_id, {_room, members}) do
    case fetch_member(member_id, members) do
      nil -> false
      member -> member in members and member.admin == true
    end
  end

  @spec close(state :: state()) :: :ok | :error
  @impl true
  def close({room, _members}) do
    Repo.delete(room)
  end

  @spec invite_member({member_id    :: pos_integer(),
                       member_login :: String.t(),
                       member_type  :: String.t()},
                      state :: state())
                            :: :ok | :error
  @impl true
  def invite_member({member_id, member_login, member_type}, {room, members}) do
    %Member.Type{id: type_id} = Repo.get_by!(Member.Type, [name: member_type])
    params = %{member_id: member_id, name: member_login,
     room_id: room.id, type_id: type_id, admin: false}
    member =
      %Member{}
      |> Member.changeset(params)
      |> Repo.insert()
    case member do
      {:ok, member} ->
        {:ok, {room, [member | members]}}
      {:error, changeset} ->
        {:error, changeset.errors}
    end
  end

  @spec not_a_member_error(member_id :: pos_integer(), room_id :: pos_integer())
  :: {:error, String.t()}

  defp not_a_member_error(member_id, room_id) do
    {:error, "member: #{inspect(member_id)} \
      is not a member of room: #{inspect(room_id)}"}
  end

  @spec fetch_member(member_id :: pos_integer, members :: [%Member{}])
  :: %Member{} | nil
  defp fetch_member(member_id, members) do
    Enum.find(members, fn(%_Member{member_id: id}) -> member_id == id end)
  end

end
