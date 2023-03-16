import Config

config :chat_dbroom, Chat.DbRoom.Repo,
  database: "chat_dbroom_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true
