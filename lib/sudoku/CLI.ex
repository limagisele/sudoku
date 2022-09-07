defmodule Sudoku.CLI do
  alias Sudoku.{State, Game, CLI}

  def play() do
    Game.start(&CLI.handle/2)
  end

  def handle(%State{status: :initial}, :start) do
    IO.puts("Game Started")
  end

  def handle(%State{status: :playing} = state, :get_input) do
    display(state.board)

    IO.puts("What position to fill?")
    pos = IO.gets("Position: ") |> String.trim |> String.to_integer
    IO.puts("With what number?")
    guess = IO.gets("Guess: ") |> String.trim |> String.to_integer

    {pos, guess}
  end

  def display(board) do
    0..8
    |> Enum.map(fn row ->
      0..8
      |> Enum.map(fn col ->
        elem(board, row * 9 + col)
      end)
      |> Enum.join(" ")
    end)
    |> Enum.join("\n")
    |> IO.puts()
  end
end
