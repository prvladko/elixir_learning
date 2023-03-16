defmodule Chat.RoomTest do
  use ExUnit.Case
  alias Chat.Room

  @moduletag timeout: 5000

  setup :start_link


  test "stores callback module name", context do
    assert Room.callback_module(context.room) == MockCbModule
  end

  test "creates a room using callback module", context do
    context = add_member(context, 3)
    assert :ok = Room.create(context.room, context.member.id, "chattest")
  end

  test "closes a room", context do
    context = add_member(context, 2)
    :ok = Room.close(context.room, context.member.id)
    assert {:error, _msg} = Room.callback_module(context.room)
  end

  test "adds a member to a room", context do
    context = add_member(context, 2)
    :ok = Room.add_member(context.room, context.member.id, "user", false)
    assert Room.member?(context.room, context.member.id)
  end

  test "removes a member from a room", context do
    context = add_member(context, 2)
    :ok = Room.add_member(context.room, context.member.id, "user", false)
    :ok = Room.remove_member(context.room, context.member.id)
    refute Room.member?(context.room, context.member.id)
  end

  test "sends a message to a room", context do
    context = add_member(context, 2)
    :ok = Room.add_member(context.room, context.member.id, "user", false)
    :ok = Room.send_message(context.room, context.member.id, "hello")
    assert "hello" == Room.messages(context.room)
  end

  test "searches a room using params", context do
    assert :ok = Room.search_room(context.room, [name: "testroom"])
  end

  test "persists a room to a permanent storage", context do
    assert :ok = Room.persist(context.room)
  end

  defp start_link(context) do
    {:ok, room} =
       DynamicSupervisor.start_child(Chat.Room.DynamicSupervisor,
                                    {Chat.Room, [MockCbModule,
                                      %{member: [], messages: ""}]})
    Map.put(context, :room, room)
  end

  defp add_member(context, id) do
    Map.put(context, :member, %MockUser{id: id, admin: true})
  end

end
