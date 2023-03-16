defmodule Chat.DbRoom.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat_dbroom,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps_path: "../../../../deps",
      lockfile: "../../../../mix.lock",
      build_path: "../../../../_build",
      config_path: "../../config/config.exs",
      deps: deps()
    ]
  end

  def aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"]]
  end

  def application do
    [
      registered: [Chat.DbRoom.Supervisor],
      extra_applications: [:logger],
      mod: {Chat.DbRoom.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.3.3"},
      {:postgrex, "~> 0.15.0"}
    ]
  end
end
