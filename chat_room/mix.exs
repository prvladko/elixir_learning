defmodule ChatRoom.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat_room,
      build_path: "../../_build",
      deps_path: "../../deps",
      test_paths: ["test", "apps/chat_dbroom/test"],
      lockfile: "../../mix.lock",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [test_all: :test]
    ]
  end

  def aliases() do
    [test_all: ["test apps/chat_dbroom/test", "test test"]]
  end

  def application do
    [
      registered: [Chat.Room.DynamicSupervisor],
      extra_applications: [:logger],
      mod: {Chat.Room.Application, []}
    ]
  end
  
  defp deps do
    [
      {:chat_dbroom, path: "apps/chat_dbroom"}
    ]
  end
end
