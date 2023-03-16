defmodule Chat.DbRoom.Member.Type do
  use Ecto.Schema
  import Ecto.Changeset

  schema "types" do
    field :name, :string
    has_many :members, Chat.DbRoom.Member
  end

  def changeset(type, params) do
    type
    |> cast(params, [:name])
    |> validate_required([:name])
  end
  
end
