defmodule Chat.Room.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    name = Application.get_env(:chat_room, :registry)
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Chat.Room.DynamicSupervisor},
      {Chat.Room.Registry, [name: name]}
    ]
    Supervisor.start_link(children, strategy: :one_for_one,
      name: Chat.Room.Supervisor)
  end
end
