defmodule Chat.Room.RegistryTest do
  use ExUnit.Case
  alias Chat.Room.Registry

  setup :no_rush

  test "saves new room process under member id" do
    room = form_room_record(true)
    assert :ok == Registry.add(Rooms, room)
    kill_room(room)
  end

  test "returns a list of processes matching member id" do
    member_id = 2
    room1 = form_room_record()
    room2 = form_room_record()
    :ok = Registry.add(Rooms, room1)
    :ok = Registry.add(Rooms, room2)
    assert Registry.lookup(Rooms, member_id) == [strip_id(room1), strip_id(room2)]
    kill_room(room1)
    kill_room(room2)
  end

  test "removes terminated process" do
      member_id = 2
           room = form_room_record()
            :ok = Registry.add(Rooms, room)
                  kill_room(room)
                  no_rush(nil)
           assert Registry.lookup(Rooms, member_id)
               == []
  end

  test "removes all records for the given key" do
    member_id = 2
           room1 = form_room_record()
           room2 = form_room_record()
             :ok = Registry.add(Rooms, room1)
             :ok = Registry.add(Rooms, room2)
             :ok = Registry.remove(Rooms, member_id)
            assert Registry.lookup(Rooms, member_id) == []
                   kill_room(room1)
                   kill_room(room2)
  end

  defp no_rush(_), do: Process.sleep(100)

  defp form_room_record(entered \\ true) do
    member_id = 2
    room_pid = spawn_room()
    room_name = "test_room"
    {member_id, room_pid, room_name, entered}
  end

  defp spawn_room() do
    spawn(fn ->
      {:ok, _room} = Chat.Room.start_link(Chat.DbRoom)
      Process.sleep(1000)
    end)
  end

  defp kill_room(room) do
    room
    |> elem(1)
    |> Process.exit(:kill)
  end

  defp strip_id(room) do
    {_id, pid, name, entered} = room
    {pid, name, entered}
  end

end
