defmodule Chat.DbRoomTest do
  use ExUnit.Case
  doctest Chat.DbRoom
  alias Chat.DbRoom
  alias Chat.DbRoom.{Room, Member, Repo}

  defmodule MockUser do
    @enforce_keys [:member_id]
    defstruct [:member_id, login: "dummy_user", password: 12345678]
  end

  setup_all %{} do
    on_exit(fn() ->
      Repo.delete_all(Room)
      Repo.delete_all(Member)
    end)
    create_room()
  end


  test "creates new room", context do
    {room, [admin]} = context[:state]
    assert is_struct(room)
    assert is_struct(admin)
  end

  test "adds a user to a room", context do
    context = add_id(context)
    {_room, init_memb} = context[:state]
    {:ok, {_room, upd_memb}} =
      DbRoom.add_member(context[:member_id], "user", false, context[:state])
    assert length(init_memb) < length(upd_memb)
    assert List.first(upd_memb).member_id == context[:member_id]
  end

  test "removes a member from a room", context do
    context = add_id(context) |> add_member()
    {:ok, {_room, upd_memb}} = DbRoom.remove_member(
      context[:member_id],
      context[:state]
    )
    assert context[:member] not in upd_memb
  end

  test "sends a message to a room", context do
    context = add_id(context) |> add_member()
    {:ok, {%Room{messages: upd_mess}, _member}} =
      DbRoom.send_message(context.member_id, "hello", context.state)
    assert upd_mess == "\nhello"
  end

  test "persists accumulated data to a storage", context do
    context = context |> add_message()
    :ok = DbRoom.persist(context.state)
    {%Room{id: id}, _members} = context.state
    %Room{messages: message} = Repo.get!(Room, id)
    assert message == "hello"
  end

  test "searches for rooms" do
    %{state: {room, _members}} = create_room()
    assert Repo.get(Room, room.id).name == room.name
  end

################################################################################
##########################      HELPER FUNCTIONS        ########################
################################################################################

  defp create_room() do
    {:ok, state} = DbRoom.create(random_int(), "testroom#{random_int()}", nil)
    %{state: state}
  end

  defp add_id(context) do
    # {_room, members} = context[:state]
    # member_id = List.first(members).member_id
    Map.put(context, :member_id, random_int())
  end

  defp add_member(context) do
    {:ok, {_room, members} = state} =
      DbRoom.add_member(context[:member_id], "user", false, context[:state])
    Map.merge(context, %{
      member: List.first(members),
      state: state})
  end

  defp add_message(context) do
    {room, members} = context.state
    put_in(room.messages, "hello")
    %{context | state: {put_in(room.messages, "hello"), members}}
  end

  defp random_int() do
    Enum.random(1..10000)
  end

end
