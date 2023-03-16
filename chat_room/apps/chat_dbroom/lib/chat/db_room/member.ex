defmodule Chat.DbRoom.Member do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "members" do
    field :member_id, :id 
    field :name, :string,
      null: false, size: 25, autogenerate: {__MODULE__, :generate_name, []}
    field :admin, :boolean
    belongs_to :room, Chat.DbRoom.Room
    belongs_to :type, Chat.DbRoom.Member.Type
  end

  def changeset(member, params) do
    member
    |> cast(params, [:member_id, :name, :room_id, :type_id, :admin])
    |> validate_required([:member_id, :room_id, :type_id, :admin])
  end

  def generate_name() do
    "member" <> (System.os_time() |> to_string())
  end

end
