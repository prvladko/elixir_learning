defmodule Chat.DbRoom.Repo.InitialData do
  alias Chat.DbRoom.{Member, Repo}

  defp type_changeset(name) do
    Member.Type.changeset(%Member.Type{}, %{name: name})
  end

  def generate_types(names, list \\ [])

  def generate_types([], list) do
    list
  end

  def generate_types(names, list) do
    {name, names} = List.pop_at(names, -1)
    generate_types(names,
      [type_changeset(name) | list]
    )
  end

  def insert_types(list) do
    Enum.each(list, fn(type) -> Repo.insert!(type) end)
  end

end

alias Chat.DbRoom.Repo

Repo.InitialData.insert_types(
  Repo.InitialData.generate_types(
    ~w(user admin spectrator)
  )
)
