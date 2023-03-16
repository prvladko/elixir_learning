defmodule Chat.Room do
  @moduledoc """
  A module and behaviour for interacting with rooms in your chat application.
  It acts similar to the GenServer. It introduces callbacks to be implemented in
  release modules, holds a callback module name and a state(if you need one).
  Any room adapter that releases `Chat.Room` callbacks can be used in a Chat
  application. Every `Chat.Room` process is added to a registry. The application
  requires **:room_type** and **registry** configuration keys set in *config.exs*.
  Room type must be atoms. Registry value will later be used for
  `Chat.Room.Registy` calls.
  """
  require Logger

  def child_spec(opts) do
    %{
       id: __MODULE__,
       start: {__MODULE__, :start_link, opts},
       type: :worker,
       restart: :transient,
       shutdown: 500
     }
  end

  @doc """
  Optional callback for creating a room. DbRoom uses it to create a room in it's
  repo. If yor room adapter is in-memory type, then you dont need it.
  """
  @callback create(admin     :: term(),
                   room_name :: String.t(),
                   state     :: term())
                             :: {:ok, term()} | {:error, String.t()}

  @doc """
  Lists all rooms for the specified member. This function should return a list.
  """
  @callback list(member :: term()) :: [term()]

  @doc """
  Lists all members belonging to the room. This function should return a list.
  """
  @callback list_members(state :: term()) :: [term()]

  @doc """
  Adds a member to your room. Member is a struct of a chat application
  participant, state is anything you passed to initialize the room. It should
  check the member for belonging to the room. Accepts opts as a third parameter
  which is a keyword list. It must return an {:ok, state} tuple or raise an error.
  """
  @callback add_member(member  :: term(),
                       type    :: String.t(),
                       admin   :: boolean(),
                       state   :: term()
                      )        :: {atom(), term()}

  @doc """
  Removes the member from the room. It should check for member belonging to the
  room. Should accept member struct and state as arguments. Should return an
  {:ok, state} tuple or raise an error.
  """
  @callback remove_member(member :: struct(),
                          state  :: term()
                         )       :: {atom(), term()}

  @doc """
  A callback for checking if the member is a member of the room.
  """
  @callback member?(member :: term(),
                    state  :: term()
                  )        :: boolean()

  @doc """
  Checks if passed member is an admin of the room. It should return a boolean.
  """
  @callback is_admin?(member :: term(), state :: term()) :: boolean()

  @doc """
  Invites a member to the room. Even though it's called an invitation, actually
  it should add a member to the room in case the member exists. Should return
  {:ok, new_state} or {:error, reason}.
  """
  @callback invite_member(member :: term(), state :: term())
  :: {:ok, term()} | {:error, String.t( )}

  @doc """
  This callback should perform all the closing functionality, cleanups, shut-
  downs and so on. It should return :ok upon completing.
  """
  @callback close(member :: term(), state :: term()) :: :ok

  @doc """
  Sends the message to a room. It should check for member belonging to a room.
  member is a struct representing chat application participant. message can be
  anything that suits your release module. So does the third argument - state.
  It must return an {:ok, state} tuple or raise an error.
  """
  @callback send_message(member  :: term(),
                         message :: term(),
                         state   :: term()
                        )        :: {atom(), term()}
  @doc """
  A callback that returns all the messages stored in the room
  """
  @callback messages(state :: term()) :: term()

  @doc """
  An implementation of room searching algorithm. param is a keyword list for
  Ecto.get_by function. It should return a list of room structures.
  """
  @callback search_room(params :: keyword()) :: [term()]

  @doc """
  An implementation of persisting algorithm. Should return :ok or {:error,
  reason}.
  """
  @callback persist(state :: term()) :: :ok | {:error, String.t()}

  alias Chat.Room.Registry

  @doc """
  Starts a linked room process. It requires a callback module name which will be
  used with all the further calls. Optionally accepts a state if you need one
  for your stateful release module.
  """
  @spec start_link(callback_mod :: module(), state :: term()) :: {:ok, pid()}

  def start_link(callback_mod, state \\ nil) when is_atom(callback_mod) do
    :proc_lib.start_link(__MODULE__, :init, [callback_mod, state, self()])
  end

  @spec init(callback_mod :: module(), state :: term(), parent :: pid())
  :: {:ok, state :: term()} | {:error, term()}

  def init(callback_mod, state, parent) do
    debug = :sys.debug_options([])
    :proc_lib.init_ack(parent, {:ok, self()})
    config({callback_mod, state}, parent, debug)
  end

  @doc """
  Please refer to `Chat.Room.Registy.lookup/2` documentation.
  """
  @spec lookup(registry :: GenServer.name(), member :: term())
  :: [{pid :: pid(), name :: String.t(), entered :: boolean()}]

  def lookup(registry, member) do
    Registry.lookup(registry, member)
  end

  @doc """
  Please refer to `Chat.Room.Registy.lookup/3` documentation.
  """
  @spec lookup(registry :: GenServer.name(), term())
  :: [{pid(), boolean()}]

  def lookup(registry, member, room_name) do
    Registry.lookup(registry, member, room_name)
  end

  @doc """
  Please refer to `Chat.Room.Registy.add/2` documentation.
  """
  @spec add(registry :: GenServer.name(),
             {member :: term(),
              room_pid  :: pid(),
              room_name :: String.t(),
              entered   :: boolean()})
  :: :ok | :error | {:error, String.t()}

  def add(registry, record) do
    Registry.add(registry, record)
  end

  @doc """
  Please refer to `Chat.Room.Registy.remove/2` documentation.
  """
  @spec remove(registry :: GenServer.name(), member :: term())
  :: :ok | :error

  def remove(registry, member) do
    Registry.remove(registry, member)
  end

  @doc """
  Please refer to `Chat.Room.Registy.remove/3` documentation.
  """
  @spec remove(registry  :: GenServer.name(),
               member :: term(),
               room_name :: String.t())
  :: :ok | :error

  def remove(registry, member, room_name) do
    Registry.remove(registry, member, room_name)
  end

  @doc """
  Please refer to `Chat.Room.Registy.persist/2` documentation.
  """
  @spec persist(registry :: GenServer.name(), filename :: Path.t()) :: :ok
  def persist(registry, filename) do
    Registry.persist(registry, filename)
  end

  @doc """
  Please refer to `Chat.Room.Registy.load/2` documentation.
  """
  @spec load(registry :: GenServer.name(), filename :: Path.t()) :: :ok
  def load(registry, filename) do
    Registry.load(registry, filename)
  end

  @doc """
  Starts a room under DynamicSupervisor and returns it's pid. Same requirements
  and outputs as `start_link/2`.
  """
  @spec start_supervised(callback_mod :: module(), state :: term())
  :: {:ok, pid()} | {:error, term()}

  def start_supervised(callback_mod, state \\ nil) when is_atom(callback_mod) do
    DynamicSupervisor.start_child(Chat.Room.DynamicSupervisor,
      {Chat.Room, [callback_mod, state]})
  end

  @doc """
  A function for implementations that require extra step for creating a room (
  adapters with SQL database persistence). Requires a pid with stored callback
  module, user structure which is assigned to be an admin of a new room. Last
  argument name is optional, wil be autogenerated in case it's absent.
  """
  @spec create(room :: pid(), admin :: term(), name :: String.t() | nil)
  :: {:ok, term()} | {:error, String.t()}

  def create(room, admin, name \\ nil) when is_pid(room) do
    forward(:create, room, [admin, name])
  end

  @doc """
  Lists all the rooms stored for specified member. Returns a list of room names
  as strings.
  """
  @spec list(callback_mod :: module(), member :: term())
  :: [String.t()]

  def list(callback_mod, member) do
    callback_mod.list(member)
  end

  @doc """
  Returns a list of members' names of the room.
  """
  @spec list_members(room :: pid()) :: [String.t()]

  def list_members(room) do
    {mod, state} = config(room)
    mod.list_members(state)
  end

  @doc """
  Sends exit signal to the specified room. Always returns true.
  """
  @spec close(room :: pid(), member :: term()) :: true

  def close(room, member) when is_pid(room) do
    {mod, state} = config(room)
    if mod.is_admin?(member, state) do
      send(room, {:identify, self()})
      receive do
        :room ->
          mod.close(state)
          send(room, :shutdown)
          :ok
      after
        100 ->
          {:error, "#{inspect(room)} is dead or not a Chat.Room process"}
      end
    else
      {:error, "You are not the room administrator"}
    end
  end

  @doc """
  Invites a system member to the passed room. Takes room pid and a member record
  to build a Member. Reurns :ok or :error.
  """
  @spec invite_member(room :: pid(), member :: term()) :: :ok | :error

  def invite_member(room, member) do
    forward(:invite_member, room, [member])
  end

  @doc """
  Adds a member to your room. Uses add_member callback implementation. room is a
  pid of target room process, member is a struct representing chat application
  participant, opts is a keyword list which defaults to *[admin: false]*. Updates
  the state and returns :ok.
  """
  @spec add_member(room   :: pid(),
                   member :: term(),
                   type   :: String.t(),
                   admin  :: boolean())
                          :: :ok | :error

  def add_member(room, member, type, admin) when is_pid(room) do
    forward(:add_member, room, [member, type, admin])
  end

  @doc """
  Removers the member from the room. Uses remove_member callback implementation.
  room is a pid of target room process, member is a struct representing chat
  application. Updates config and returns :ok.
  """
  @spec remove_member(room :: pid(), member :: term()) :: :ok

  def remove_member(room, member) do
    forward(:remove_member, room, [member])
  end

  @doc """
  Checks whenever the member is a member of the room. Returns boolean value.
  """
  @spec member?(room :: pid(), member :: term()) :: boolean()

  def member?(room, member) when is_pid(room) do
    forward(:member?, room, [member])
  end

  @doc """
  Sends the message to the room. Uses send_message callback implementation.
  room is a pid of target room process, member is a struct representing chat
  application, message can be anything suitable for your room module
  implementation. Updates config and returns :ok.
  """
  @spec send_message(room    :: pid(),
                     member  :: term(),
                     message :: String.t())
                             :: :ok

  def send_message(room, member, message) do
    forward(:send_message, room, [member, message])
  end

  @doc """
  Returns all messages stored in the room.
  """
  @spec messages(room :: pid()) :: String.t()

  def messages(room) do
    {mod, state} = config(room)
    mod.messages(state)
  end

  @doc """
  Searches and returns a list of rooms if there are any matching the param
  argument. Requires relise module name as the first argument to search with. The
  search itself is done by search_room callback.
  """
  @spec search_room(room :: pid(), params :: keyword()) :: list(struct())

  def search_room(room, params) do
    {mod, _state} = config(room)
    mod.search_room(params)
  end

  @doc """
  Persistts the room. The algorithm itself is relised by relise module. Requires
  room's pid as an argument.
  """
  @spec persist(room :: pid()) :: :ok | {:error, reason :: String.t()}

  def persist(room) do
    {mod, state} = config(room)
    mod.persist(state)
  end

  @doc """
  Simply returns callback module name for the room's pid.
  """
  @spec callback_module(room :: pid()) :: module()

  def callback_module(room) do
    case config(room) do
      {:error, message} ->
        {:error, message}
      {mod, _state} ->
        mod
    end
  end

  # private

  @spec config(pid()) :: {:ok, term()} | {:error, String.t()}
  defp config(room) when is_pid(room) do
    if Process.alive?(room) do
      send(room, {:get, self()})
      receive do
        {:ok, value} ->
          value
        {:error, message} ->
          Logger.error(message)
      after
        400 ->
          {:error, "no response from #{inspect(room)}"}
      end
    else
      {:error, "room #{inspect(room)} is dead"}
    end
  end

  @spec config(pid(), term()) :: :ok
  defp config(room, values) do
    send(room, {:set, values})
    :ok
  end

  @spec config(values :: tuple(), parent :: pid(), debug :: [term()] )
  :: no_return()
  defp config(values, parent, debug) when is_tuple(values) do
    receive do
      {:get, caller} when is_pid(caller) ->
        debug = :sys.handle_debug(debug, &write_debug/2,
           __MODULE__, {:get, caller})
        send(caller, {:ok, values})
        config(values, parent, debug)
      {:set, {mod, _state} = new_values} when is_atom(mod) ->
        debug = :sys.handle_debug(debug, &write_debug/2,
           __MODULE__, {:set, mod})
        config(new_values, parent, debug)
      {:identify, caller} when is_pid(caller) ->
        debug = :sys.handle_debug(debug, &write_debug/2,
           __MODULE__, {:identify, caller})
        send(caller, :room)
        config(values, parent, debug)
      :shutdown ->
        :sys.handle_debug(debug, &write_debug/2,
           __MODULE__, {:shutdown})
        exit(:normal)
      {:system, caller, request} ->
        :sys.handle_system_msg(request, caller, parent,
          __MODULE__, debug, values)
      {other, caller} when is_pid(caller) ->
        send(caller, {:error, "unknown request: #{other}"})
        config(values, parent, debug)
      unknown ->
        Logger.error("Unkown request to #{inspect(self())}: #{inspect(unknown)}")
        config(values,  parent, debug)
    end
  end

  @spec forward(fun :: atom(), room :: pid(), args :: list()) :: :ok
  defp forward(fun, room, args) do
    {mod, state} = config(room)
    args = List.insert_at(args, -1, state)
    res = apply(mod, fun, args)
    case res do
      {:ok, state} ->
        config(room, {mod, state})
      {:error, reason} ->
        {:error, reason}
      true ->
        true
      false ->
        false
    end
  end

  def write_debug(event, name) do
    Logger.debug("Received event: #{event}, name: #{name}")
  end

  def system_continue(parent, debug, values) do
    config(values, parent, debug)
  end

  def system_terminate(reason, _parent, _debug, _values) do
    exit(reason)
  end

  def system_get_state(values) do
    {:ok, values}
  end

  def system_replace_state(function, values) do
    values = function.(values)
    {:ok, values, values}
  end

end
