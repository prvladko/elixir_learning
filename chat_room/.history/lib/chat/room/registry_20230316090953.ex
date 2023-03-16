defmodule Chat.Room.Registry do
  @moduledoc """
  A simple registry storage to store `Chat.Room` records.

  Records include `Chat.Base` member identifiers, `Chat.Room` process identifiers,
  `Chat.Room` names, and boolean *entered?* values. The registry is started by
  `Chat.Room.Application` with the name found in the application configuration
  under **:registry** key.
  """

  @typedoc """
  A valid room record MUST be this.
  """
  @type room :: {pos_integer(), pid(), String.t(), boolean()}

  use GenServer

  @doc """
  Starts an ets table and stores it's reference to the state.

  The table is  public. Interaction is done through GenServer that takes it's
  name from opts argument. Returns {:ok, pid}.
  """
  @spec start_link(opts :: keyword()) :: {:ok, pid()} | {:error, String.t()}

  def start_link(opts) do
    name = opts[:name]
    GenServer.start_link(__MODULE__, name, name: name)
  end

  @doc """
  A function to add room records to the registry.

  The record must be {member_id, room_pid, room_name, entered}. Returns :ok or
  :error or  {:error | reason}.
  """
  @spec add(registry :: GenServer.name(), record :: room()) :: :ok | :error

  def add(registry, record) do
    GenServer.call(registry, {:add, record})
  end

  @doc """
  A search function that takes registry name and a member id.

  Returns a list of records of all rooms belonging to the member or an empty
  list. The records are {pid, name, entered}.
  """
  @spec lookup(registry :: GenServer.name(), member_id :: pos_integer())
  :: :ok | :error

  def lookup(registry, member_id) do
    GenServer.call(registry, {:lookup, member_id})
  end

  @doc """
  A search function that takes registry name, member id and a room's name.

  It searches the registry and returns a {pid, entered} tuple or nil. Every user
  can have only unique room names, so the result is always a single.
  """
  @spec lookup(registry  :: GenServer.name(),
               member_id :: pos_integer(),
               room_name :: String.t())
                         :: :ok | :error

  def lookup(registry, member_id, room_name) do
    GenServer.call(registry, {:lookup, member_id, room_name})
  end

  @doc """
  Updates the entered state of a room record.

  Takes a registry name, a member id, a room name to match a record and an
  entered boolean to update the record.
  """
  @spec update(registry  :: GenServer.name(),
               member_id :: pos_integer(),
               room_name :: String.t(),
               entered   :: boolean())
                         :: :ok | :error

  def update(registry, member_id, room_name, entered) do
    GenServer.call(registry, {:update, member_id, room_name, entered})
  end

  @doc """
  Removes records that start with passed member_id.

  Returns :ok or :error.
  """
  @spec remove(registry :: GenServer.name(), member_id :: pos_integer())
  :: :ok | :error

  def remove(registry, member_id) do
    GenServer.call(registry, {:remove, member_id})
  end

  @doc """
  Removes a single entry from the registry.

  The first argument must be a registry, the second is a member id and the third
  is a room name. Returns :ok or :error.
  """
  @spec remove(registry  :: GenServer.name(),
               member_id :: pos_integer(),
               room_name :: String.t())
                         :: :ok | :error

  def remove(registry, member_id, room_name) do
    GenServer.call(registry, {:remove, member_id, room_name})
  end

  @doc """
  Stores entire registry to a file.

  Requires both registry name and file name as arguments. Triggering must be
  designed by the user.
  """
  @spec persist(registry :: GenServer.name(), filename :: Path.t())
  :: :ok | :error

  def persist(registry, filename) do
    GenServer.cast(registry, {:persist, filename})
  end

  @doc """
  Loads registry from the file into GenServer state, so it can be used right away
  .
  """
  @spec load(registry  :: GenServer.name(), filename :: Path.t())
  :: :ok | :error

  def load(registry, filename) do
    GenServer.call(registry, {:load, filename})
  end

  @impl true
  def init(name) do
    tab = :ets.new(name, [:bag, :private, read_concurrency: true])
    {:ok, tab}
  end

  @impl true
  def handle_call({:add, record}, _from, tab) do
    if valid_record?(record) do
      record
      |> elem(1)
      |> Process.monitor()
      insert = fn -> :ets.insert(tab, record) end
      reply = ok_error_response(insert)
      {:reply, reply, tab}
    else
      {:error, "invalid record"}
    end
  end

  @impl true
  def handle_call({:lookup, member_id}, _from, tab) do
    reply =
      tab
      |> :ets.match({member_id, :'$1', :'$2', :'$3'})
      |> Enum.map(& List.to_tuple(&1))
    {:reply, reply, tab}
  end

  @impl true
  def handle_call({:update, member_id, room_name, entered}, _from, tab) do
    case :ets.match_object(tab, {member_id, :_, room_name, :'$1'}) do
      [old_data] ->
        :ets.delete_object(tab, old_data)
        new_data = put_elem(old_data, 3, entered)
        insert = fn -> :ets.insert(tab, new_data) end
        reply = ok_error_response(insert)
        {:reply, reply, tab}
      [] ->
        {:error, "Room not found"}
    end
  end

  @impl true
  def handle_call({:lookup, member_id, room_name}, _from, tab) do
    reply = :ets.match(tab, {member_id, :'$1', room_name, :'$2'})
    case reply do
      [reply] ->
          reply = List.to_tuple(reply)
        {:reply, reply, tab}
      [] ->
        {:reply, reply, tab}
    end
  end

  @impl true
  def handle_call({:remove, member_id}, _from, tab) do
    delete = fn -> :ets.delete(tab, member_id) end
    reply = ok_error_response(delete)
    {:reply, reply, tab}
  end

  @impl true
  def handle_call({:remove, member_id, room_name}, _from, tab) do
    delete = fn -> :ets.match_delete(tab, {member_id, :_, room_name, :_}) end
    reply = ok_error_response(delete)
    {:reply, reply, tab}
  end


  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, tab) do
    :ets.match_delete(tab, {:_, pid, :_, :_})
    {:noreply, tab}
  end

  @impl true
  def handle_cast({:persist, filename}, tab) do
    :ets.tab2file(tab, filename)
    {:noreply, tab}
  end

  @impl true
  def handle_info({:persist, filename}, tab) do
    :ets.tab2file(tab, filename)
    {:noreply, tab}
  end

  @impl true
  def handle_call({:load, filename}, _from, tab) do
    tab = :ets.file2tab(tab, filename)
    {:noreply, tab}
  end

  defp ok_error_response(fun) do
    if true = apply(fun, []), do: :ok, else: :error
  end

  defp valid_record?(record) do
    try do
      {id, pid, name, entered?} = record
      is_integer(id) and id > 0
      and is_pid(pid)
      and is_binary(name)
      and is_boolean(entered?)
    rescue
      MatchError ->
        false
    end
  end
end
