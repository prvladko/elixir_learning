defmodule Chat.DbRoom.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string,
      null: false, size: 35, autogenerate: {__MODULE__, :generate_name, []}
    field :messages, :string,
      size: nil, default: ""
    has_many :members, Chat.DbRoom.Member
    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :messages])
    |> validate_required([:name])
  end

  def generate_name() do
    "room" <> (System.os_time() |> to_string())
  end
end
