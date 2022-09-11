defmodule Sudoku.State do
  alias Sudoku.Game

  defstruct status: :initial,
            player: nil,
            winner: false,
            board: Game.new(),
            wrong_pos_filled: {},
            ui: nil
end
