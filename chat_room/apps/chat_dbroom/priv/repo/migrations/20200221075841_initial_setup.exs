defmodule Chat.DbRoom.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do

    create table(:rooms) do
      add :name, :string,
        null: false, size: 35
      add :messages, :string,
        size: nil, default: nil
      timestamps()
    end

    create table(:types) do
      add :name, :string
    end

    create table(:members, prmary_key: false) do
      add :member_id, :id,
        null: false
      add :name, :string,
        null: false
      add :admin, :boolean
      add :room_id, references("rooms", on_delete: :delete_all)
      add :type_id, references("types", on_delete: :nilify_all)
    end

    create index(:members, :room_id)

    create index(:members,
                 [:room_id, :member_id, :type_id],
                 name: "unique members",
                 unique: true)

  end
end
