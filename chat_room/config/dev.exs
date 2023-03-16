import Config

config :chat_dbroom, Chat.DbRoom.Repo,
  database: "chat_dbroom_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
