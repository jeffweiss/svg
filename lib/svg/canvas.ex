defmodule Svg.Canvas do
  @moduledoc """
  SVG document container with physical dimensions and resolution.

  The Canvas manages the SVG document structure, calculating the viewBox
  from physical dimensions (in millimeters) and DPI resolution settings.
  """

  alias Svg.{Elements, PaperSize, Resolution, Units}

  @typedoc """
  The Canvas struct representing an SVG document.

  ## Fields

    * `:width_mm` - Width in millimeters
    * `:height_mm` - Height in millimeters
    * `:dpi` - Resolution in dots per inch
    * `:elements` - List of SVG elements to render
    * `:viewbox` - Calculated viewBox dimensions {width_px, height_px}

  """
  @type t :: %__MODULE__{
          width_mm: number(),
          height_mm: number(),
          dpi: pos_integer(),
          elements: [struct()],
          viewbox: {non_neg_integer(), non_neg_integer()}
        }

  @enforce_keys [:width_mm, :height_mm, :dpi, :viewbox]
  defstruct [:width_mm, :height_mm, :dpi, :viewbox, elements: []]

  @doc """
  Creates a new canvas with the given paper size and resolution.

  ## Options

    * `:resolution` - DPI preset atom or custom integer (default: `:illustrator`)
    * `:orientation` - `:portrait` or `:landscape` (default: `:portrait`)

  ## Examples

      iex> canvas = Svg.Canvas.new(:a6)
      iex> canvas.width_mm
      105.0
      iex> canvas.height_mm
      148.0
      iex> canvas.dpi
      72

      iex> canvas = Svg.Canvas.new(:a6, resolution: :axidraw_fine)
      iex> canvas.dpi
      2870
      iex> {width, height} = canvas.viewbox
      iex> width > 11800 and height > 16700
      true

      iex> canvas = Svg.Canvas.new(:a6, orientation: :landscape)
      iex> canvas.width_mm
      148.0
      iex> canvas.height_mm
      105.0

  """
  @spec new(PaperSize.size_name(), keyword()) :: t()
  def new(paper_size, opts \\ []) do
    orientation = Keyword.get(opts, :orientation, :portrait)
    resolution = Keyword.get(opts, :resolution, :illustrator)

    {width_mm, height_mm} = PaperSize.dimensions(paper_size, orientation)
    dpi = Resolution.dpi(resolution)

    viewbox = calculate_viewbox(width_mm, height_mm, dpi)

    %__MODULE__{
      width_mm: width_mm,
      height_mm: height_mm,
      dpi: dpi,
      viewbox: viewbox,
      elements: []
    }
  end

  @doc """
  Creates a new canvas with custom dimensions in millimeters.

  ## Options

    * `:resolution` - DPI preset atom or custom integer (default: `:illustrator`)

  ## Examples

      iex> canvas = Svg.Canvas.new_custom(100, 200)
      iex> canvas.width_mm
      100
      iex> canvas.height_mm
      200

      iex> canvas = Svg.Canvas.new_custom(100, 200, resolution: 300)
      iex> canvas.dpi
      300

  """
  @spec new_custom(number(), number(), keyword()) :: t()
  def new_custom(width_mm, height_mm, opts \\ []) do
    resolution = Keyword.get(opts, :resolution, :illustrator)
    dpi = Resolution.dpi(resolution)
    viewbox = calculate_viewbox(width_mm, height_mm, dpi)

    %__MODULE__{
      width_mm: width_mm,
      height_mm: height_mm,
      dpi: dpi,
      viewbox: viewbox,
      elements: []
    }
  end

  @doc """
  Adds an element to the canvas.

  Elements are rendered in the order they are added (painter's algorithm).

  ## Examples

      iex> canvas = Svg.Canvas.new(:a6)
      iex> line = %Svg.Elements.Line{x1: 0, y1: 0, x2: 100, y2: 100}
      iex> canvas = Svg.Canvas.add(canvas, line)
      iex> length(canvas.elements)
      1

  """
  @spec add(t(), struct()) :: t()
  def add(%__MODULE__{elements: elements} = canvas, element) do
    %{canvas | elements: elements ++ [element]}
  end

  @doc """
  Adds multiple elements to the canvas.

  ## Examples

      iex> canvas = Svg.Canvas.new(:a6)
      iex> elements = [
      ...>   %Svg.Elements.Line{x1: 0, y1: 0, x2: 100, y2: 100},
      ...>   %Svg.Elements.Line{x1: 0, y1: 100, x2: 100, y2: 0}
      ...> ]
      iex> canvas = Svg.Canvas.add_all(canvas, elements)
      iex> length(canvas.elements)
      2

  """
  @spec add_all(t(), [struct()]) :: t()
  def add_all(%__MODULE__{elements: elements} = canvas, new_elements)
      when is_list(new_elements) do
    %{canvas | elements: elements ++ new_elements}
  end

  @doc """
  Renders the canvas to an SVG string.

  ## Examples

      iex> canvas = Svg.Canvas.new(:a6, resolution: :illustrator)
      iex> svg = Svg.Canvas.to_svg(canvas)
      iex> svg =~ ~s(width="105.0mm")
      true
      iex> svg =~ ~s(height="148.0mm")
      true
      iex> svg =~ ~s(viewBox="0 0)
      true

  """
  @spec to_svg(t()) :: String.t()
  def to_svg(%__MODULE__{} = canvas) do
    {vb_width, vb_height} = canvas.viewbox

    elements_svg = Enum.map_join(canvas.elements, "\n  ", &render_element/1)

    """
    <svg xmlns="http://www.w3.org/2000/svg" \
    width="#{Elements.format_value(canvas.width_mm)}mm" \
    height="#{Elements.format_value(canvas.height_mm)}mm" \
    viewBox="0 0 #{vb_width} #{vb_height}">
      #{elements_svg}
    </svg>
    """
    |> String.trim()
  end

  @doc """
  Converts a physical measurement in millimeters to viewBox pixels.

  This is useful for positioning elements using physical measurements.

  ## Examples

      iex> canvas = Svg.Canvas.new(:a6, resolution: :axidraw_fine)
      iex> pixels = Svg.Canvas.mm_to_px(canvas, 10)
      iex> round(pixels)
      1130

  """
  @spec mm_to_px(t(), number()) :: float()
  def mm_to_px(%__MODULE__{dpi: dpi}, mm) do
    Units.to_pixels(mm, dpi, :mm)
  end

  @doc """
  Converts viewBox pixels to physical millimeters.

  ## Examples

      iex> canvas = Svg.Canvas.new(:a6, resolution: :axidraw_fine)
      iex> mm = Svg.Canvas.px_to_mm(canvas, 1130)
      iex> Float.round(mm, 2)
      10.0

  """
  @spec px_to_mm(t(), number()) :: float()
  def px_to_mm(%__MODULE__{dpi: dpi}, px) do
    Units.pixels_to_mm(px, dpi)
  end

  # Private functions

  defp calculate_viewbox(width_mm, height_mm, dpi) do
    width_px = Units.to_pixels(width_mm, dpi, :mm) |> round()
    height_px = Units.to_pixels(height_mm, dpi, :mm) |> round()
    {width_px, height_px}
  end

  defp render_element(element) do
    module = element.__struct__
    module.to_svg(element)
  end
end
