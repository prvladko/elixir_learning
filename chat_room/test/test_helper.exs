defmodule MockCbModule do

  def create(_admin, name, state) when is_binary(name) do
    {:ok, state}
  end

  def add_member(member, _type, _admin, state) do
    {:ok, put_in(state.member, [member | state.member])}
  end

  def remove_member(member, state) do
    {:ok, update_in(state.member, &(List.delete(&1, member)))}
  end

  def member?(member, state) do
    member in state.member
  end

  def send_message(member, message, state) do
    if member in state.member do
      {:ok, update_in(state.messages, &(&1 <> message))}
    else
      {:error, :not_a_member}
    end
  end

  def messages(state) do
    state.messages
  end

  def search_room(_param) do
    :ok
  end

  def close(_state) do
    :ok
  end

  def is_admin?(_member, _state) do
    true # member.admin
  end

  def persist(_room) do
    :ok
  end

end

defmodule MockUser do
  defstruct [:id, :name, :login, :password, :admin]
end

# ExUnit.configure(max_failures: 3)
ExUnit.start()
