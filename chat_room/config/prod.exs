import Config

config :chat_dbroom, Chat.DbRoom.Repo,
  database: "chat_dbroom_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :chat_dbroom,
  ecto_repos: [Chat.DbRoom.Repo]
