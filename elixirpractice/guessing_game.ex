defmodule GuessingGame do
  # guess between a low number and a high -> guess middle number
  # TELL USER OUR GUESS
  # "yes" -> game over
  # "bigger" -> bigger(low, high)
  # "smaller" -> smaller(low, high)
  # anything else -> tell user to enter a valid response
  def guess(a, b) when a > b, do: guess(b, a)

  def guess(low, high) do
    answer = IO.gets("Hmm... maybe you're thinking of #{mid(low, high)}?\n")

    case String.trim(answer) do
      "bigger" ->
        bigger(low, high)

      "smaller" ->
        smaller(low, high)

      "yes" ->
        "I knew I could guess your number!"

      _ ->
        IO.puts ~s{Type "bigger", "smaller" or "yes"}
        guess(low, high)
    end
  end

  def mid(low, high) do
    div low + high, 2
  end

  def bigger(low, high) do
    new_low = min(high, mid(low, high) + 1)
    guess(new_low, high)
  end

  def smaller(low, high) do
    new_high = max(low, mid(low, high) - 1)
    guess(low, new_high)
  end
end
