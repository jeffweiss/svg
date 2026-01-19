defmodule Svg.PaperSize do
  @moduledoc """
  Standard paper size definitions for print-ready SVGs.

  All sizes are stored internally in millimeters with portrait orientation
  (width < height). Use `dimensions/2` with `:landscape` to swap dimensions.
  """

  @typedoc """
  A paper size identifier.
  """
  @type size_name :: :a4 | :a5 | :a6 | :us_letter | :nine_by_twelve | :four_by_six | :eight_by_ten

  @typedoc """
  Paper orientation.
  """
  @type orientation :: :portrait | :landscape

  @typedoc """
  Dimensions as {width, height} in millimeters.
  """
  @type dimensions_mm :: {number(), number()}

  # Paper sizes in millimeters (portrait orientation: width < height)
  @sizes %{
    a4: {210.0, 297.0},
    a5: {148.0, 210.0},
    a6: {105.0, 148.0},
    us_letter: {215.9, 279.4},
    nine_by_twelve: {228.6, 304.8},
    four_by_six: {101.6, 152.4},
    eight_by_ten: {203.2, 254.0}
  }

  @doc """
  Returns a list of all available paper size names.

  ## Examples

      iex> Svg.PaperSize.available_sizes()
      [:a4, :a5, :a6, :eight_by_ten, :four_by_six, :nine_by_twelve, :us_letter]

  """
  @spec available_sizes() :: [size_name()]
  def available_sizes do
    @sizes |> Map.keys() |> Enum.sort()
  end

  @doc """
  Returns the dimensions {width, height} in millimeters for a given paper size.

  The default orientation is `:portrait`. Use `:landscape` to swap width and height.

  ## Examples

      iex> Svg.PaperSize.dimensions(:a6)
      {105.0, 148.0}

      iex> Svg.PaperSize.dimensions(:a6, :landscape)
      {148.0, 105.0}

      iex> Svg.PaperSize.dimensions(:us_letter)
      {215.9, 279.4}

      iex> Svg.PaperSize.dimensions(:us_letter, :portrait)
      {215.9, 279.4}

  """
  @spec dimensions(size_name(), orientation()) :: dimensions_mm()
  def dimensions(size, orientation \\ :portrait)

  def dimensions(size, :portrait) when is_map_key(@sizes, size) do
    Map.fetch!(@sizes, size)
  end

  def dimensions(size, :landscape) when is_map_key(@sizes, size) do
    {width, height} = Map.fetch!(@sizes, size)
    {height, width}
  end

  @doc """
  Returns the width in millimeters for a given paper size and orientation.

  ## Examples

      iex> Svg.PaperSize.width(:a6)
      105.0

      iex> Svg.PaperSize.width(:a6, :landscape)
      148.0

  """
  @spec width(size_name(), orientation()) :: number()
  def width(size, orientation \\ :portrait) do
    {w, _h} = dimensions(size, orientation)
    w
  end

  @doc """
  Returns the height in millimeters for a given paper size and orientation.

  ## Examples

      iex> Svg.PaperSize.height(:a6)
      148.0

      iex> Svg.PaperSize.height(:a6, :landscape)
      105.0

  """
  @spec height(size_name(), orientation()) :: number()
  def height(size, orientation \\ :portrait) do
    {_w, h} = dimensions(size, orientation)
    h
  end

  @doc """
  Checks if a given atom is a valid paper size name.

  ## Examples

      iex> Svg.PaperSize.valid_size?(:a4)
      true

      iex> Svg.PaperSize.valid_size?(:letter)
      false

  """
  @spec valid_size?(atom()) :: boolean()
  def valid_size?(size) when is_atom(size) do
    Map.has_key?(@sizes, size)
  end

  def valid_size?(_), do: false
end
