defmodule Chat.DbRoom.Repo do
  use Ecto.Repo,
    otp_app: :chat_dbroom,
    adapter: Ecto.Adapters.Postgres
end
