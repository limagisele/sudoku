defmodule Sudoku.Game do
  alias Sudoku.State

  @sudoku_to_solve {
    0, 4, 0, 0, 0, 0, 1, 7, 9,
    0, 0, 2, 0, 0, 8, 0, 5, 4,
    0, 0, 6, 0, 0, 5, 0, 0, 8,
    0, 8, 0, 0, 7, 0, 9, 1, 0,
    0, 5, 0, 0, 9, 0, 0, 3, 0,
    0, 1, 9, 0, 6, 0, 0, 4, 0,
    3, 0, 0, 4, 0, 0, 7, 0, 0,
    5, 7, 0, 1, 0, 0, 2, 0, 0,
    9, 2, 8, 0, 0, 0, 0, 6, 0
  }

  @sudoku_solved {
    8, 4, 5, 6, 3, 2, 1, 7, 9,
    7, 3, 2, 9, 1, 8, 6, 5, 4,
    1, 9, 6, 7, 4, 5, 3, 2, 8,
    6, 8, 3, 5, 7, 4, 9, 1, 2,
    4, 5, 7, 2, 9, 1, 8, 3, 6,
    2, 1, 9, 8, 6, 3, 5, 4, 7,
    3, 6, 1, 4, 2, 9, 7, 8, 5,
    5, 7, 4, 1, 8, 6, 2, 9, 3,
    9, 2, 8, 3, 5, 7, 4, 6, 1
  }

  def new, do: @sudoku_to_solve

  def start(ui) do
    with {:ok, game} <- State.new(ui),
         {:ok, game} <- State.event(game, {:start_game}),
    do: game, else: (error -> error)
  end

  def solved?(board), do: board == @sudoku_solved

  def check_pos(pos) do
    cond do
      pos < 0 or pos > 80 -> {:error, :invalid_position}
      !pos_editable?(pos) -> {:error, :position_not_editable}
      true -> {:ok, pos}
    end
  end

  def check_number(guess) do
    cond do
      guess < 1 or guess > 9 -> {:error, :invalid_number}
      true -> {:ok, guess}
    end
  end

  @spec valid?([integer]) :: boolean
  def valid?(area) do
    area
    |> Enum.reduce_while(
      [],
      fn
        0, seen -> {:cont, seen}
        number, seen -> if number in seen, do: {:halt, :error}, else: {:cont, [number | seen]}
      end
    )
    |> case do
      :error -> false
      _ -> true
    end
  end

  def extract_row(board, row) do
    0..8
    |> Enum.map(fn col ->
      row * 9 + col
    end)
    |> Enum.map(&elem(board, &1))
  end

  def extract_col(board, col) do
    0..8
    |> Enum.map(fn row ->
      row * 9 + col
    end)
    |> Enum.map(&elem(board, &1))
  end

  def extract_grid(board, row, col) do
    row_offset = div(row, 3) * 3
    col_offset = div(col, 3) * 3

    0..2
    |> Enum.flat_map(fn row ->
      0..2
      |> Enum.map(fn col ->
        elem(board, (row + row_offset) * 9 + col + col_offset)
      end)
    end)
  end

  def valid_row?(board, row) do
    board
    |> extract_row(row)
    |> valid?()
  end

  def valid_col?(board, col) do
    board
    |> extract_col(col)
    |> valid?()
  end

  def valid_grid?(board, row, col) do
    board
    |> extract_grid(row, col)
    |> valid?()
  end

  def handle(%{status: :playing} = game) do
    with {pos, guess} <- game.ui.(game, :get_input),
         {:ok, updated_board, message} <- play_at(game.board, pos, guess),
         {:ok, game} <- State.event(%{game | board: updated_board}, {:board_solved?, updated_board})
    do
      IO.puts(message)
      handle(game)
    else
      (error -> error)
    end
  end

  def add_guess(board, pos, guess) do
    row = div(pos, 9)
    col = rem(pos, 9)
    possible_board = put_elem(board, pos, guess)
    guess_in_row? = !valid_row?(possible_board, row)
    guess_in_col? = !valid_col?(possible_board, col)
    guess_in_grid? = !valid_grid?(possible_board, row, col)

    cond do
      guess == elem(@sudoku_solved, pos) -> {:ok, put_elem(board, pos, guess), "Good guess"}
      guess_in_col? and guess_in_row? and guess_in_grid? -> {:ok, put_elem(board, pos, guess), "Number already present on row #{row}, col #{col} and grid"}
      guess_in_col? and guess_in_row? -> {:ok, put_elem(board, pos, guess), "Number already present on row #{row} and col #{col}"}
      guess_in_col? and guess_in_grid? -> {:ok, put_elem(board, pos, guess), "Number already present on col #{col} and grid"}
      guess_in_row? and guess_in_grid? -> {:ok, put_elem(board, pos, guess), "Number already present on row #{row} and grid"}
      guess_in_row? -> {:ok, put_elem(board, pos, guess), "Number already present on row #{row}"}
      guess_in_col? -> {:ok, put_elem(board, pos, guess), "Number already present on col #{col}"}
      guess_in_grid? -> {:ok, put_elem(board, pos, guess), "Number already present on grid"}
      true -> {:ok, put_elem(board, pos, guess), ""}
    end
  end

  def play_at(board, pos, guess) do
    with {:ok, valid_pos}     <- check_pos(pos),
         {:ok, valid_guess}   <- check_number(guess),
         {:ok, updated_board, message} <- add_guess(board, valid_pos, valid_guess),
    do: {:ok, updated_board, message}
  end

  def all_editable_pos do
    @sudoku_to_solve
    |> Tuple.to_list
    |> Enum.with_index
    |> Enum.filter(fn x -> elem(x, 0) == 0 end)
    |> Enum.map(fn x -> elem(x, 1) end)
  end

  def pos_editable?(pos), do: pos in all_editable_pos()

  def undo_play(board, pos) do
    editable? = pos_editable?(pos)

    case editable? do
      true  -> put_elem(board, pos, 0)
      false -> {:error, "Position is not editable."}
    end
  end
end