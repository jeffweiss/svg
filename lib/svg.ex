defmodule Svg do
  @moduledoc """
  A library for creating and composing print-ready SVGs.

  This library provides a fluent API for building SVG documents with physical
  dimensions (millimeters, inches) and configurable DPI resolution. The primary
  use case is generating graphics for plotters and printers.

  ## Quick Start

      # Create an A6 canvas at AxiDraw Fine resolution
      Svg.canvas(:a6, resolution: :axidraw_fine)
      |> Svg.line(x1: 100, y1: 100, x2: 500, y2: 500, stroke: "black")
      |> Svg.rect(x: 200, y: 200, width: 100, height: 50, stroke: "red", fill: "none")
      |> Svg.to_svg()

  ## Paper Sizes

  Available paper sizes: `:a4`, `:a5`, `:a6`, `:us_letter`, `:nine_by_twelve`, `:four_by_six`

  ## Resolutions

  Available resolution presets:
    * `:axidraw_fine` - 2870 DPI
    * `:axidraw_fast` - 1435 DPI
    * `:illustrator` - 72 DPI (default)
    * `:inkscape` - 96 DPI

  Custom integer DPI values are also supported.

  ## Coordinate System

  All element coordinates are in viewBox units (pixels). Use `Svg.Canvas.mm_to_px/2`
  to convert physical measurements to pixels if needed.
  """

  alias Svg.Canvas
  alias Svg.Elements.{Circle, Ellipse, Line, Path, Polygon, Polyline, Rect}
  alias Svg.Perturb

  # Canvas creation and rendering

  @doc """
  Creates a new canvas with the given paper size and options.

  ## Options

    * `:resolution` - DPI preset or custom integer (default: `:illustrator`)
    * `:orientation` - `:portrait` or `:landscape` (default: `:portrait`)

  ## Examples

      iex> canvas = Svg.canvas(:a6)
      iex> canvas.width_mm
      105.0

      iex> canvas = Svg.canvas(:a6, resolution: :axidraw_fine, orientation: :landscape)
      iex> canvas.width_mm
      148.0
      iex> canvas.dpi
      2870

  """
  @spec canvas(Svg.PaperSize.size_name(), keyword()) :: Canvas.t()
  defdelegate canvas(paper_size, opts \\ []), to: Canvas, as: :new

  @doc """
  Creates a new canvas with custom dimensions in millimeters.

  ## Options

    * `:resolution` - DPI preset or custom integer (default: `:illustrator`)

  ## Examples

      iex> canvas = Svg.canvas_custom(100, 200)
      iex> canvas.width_mm
      100

  """
  @spec canvas_custom(number(), number(), keyword()) :: Canvas.t()
  defdelegate canvas_custom(width_mm, height_mm, opts \\ []), to: Canvas, as: :new_custom

  @doc """
  Renders the canvas to an SVG string.

  ## Examples

      iex> canvas = Svg.canvas(:a6)
      iex> svg = Svg.to_svg(canvas)
      iex> svg =~ "<svg"
      true

  """
  @spec to_svg(Canvas.t()) :: String.t()
  defdelegate to_svg(canvas), to: Canvas

  # Element creation helpers

  @doc """
  Adds a line element to the canvas.

  ## Options

    * `:x1` - Starting x coordinate (default: 0)
    * `:y1` - Starting y coordinate (default: 0)
    * `:x2` - Ending x coordinate (default: 0)
    * `:y2` - Ending y coordinate (default: 0)
    * `:stroke` - Stroke color
    * `:stroke_width` - Stroke width
    * Other presentation attributes

  ## Examples

      iex> canvas = Svg.canvas(:a6) |> Svg.line(x1: 0, y1: 0, x2: 100, y2: 100, stroke: "black")
      iex> length(canvas.elements)
      1

  """
  @spec line(Canvas.t(), keyword()) :: Canvas.t()
  def line(canvas, opts \\ []) do
    Canvas.add(canvas, Line.new(opts))
  end

  @doc """
  Adds a rectangle element to the canvas.

  ## Options

    * `:x` - X coordinate of top-left corner (default: 0)
    * `:y` - Y coordinate of top-left corner (default: 0)
    * `:width` - Width of the rectangle (default: 0)
    * `:height` - Height of the rectangle (default: 0)
    * `:rx` - Horizontal corner radius (optional)
    * `:ry` - Vertical corner radius (optional)
    * Other presentation attributes

  ## Examples

      iex> canvas = Svg.canvas(:a6) |> Svg.rect(x: 10, y: 10, width: 100, height: 50, fill: "blue")
      iex> length(canvas.elements)
      1

  """
  @spec rect(Canvas.t(), keyword()) :: Canvas.t()
  def rect(canvas, opts \\ []) do
    Canvas.add(canvas, Rect.new(opts))
  end

  @doc """
  Adds a circle element to the canvas.

  ## Options

    * `:cx` - X coordinate of center (default: 0)
    * `:cy` - Y coordinate of center (default: 0)
    * `:r` - Radius (default: 0)
    * Other presentation attributes

  ## Examples

      iex> canvas = Svg.canvas(:a6) |> Svg.circle(cx: 50, cy: 50, r: 25, fill: "red")
      iex> length(canvas.elements)
      1

  """
  @spec circle(Canvas.t(), keyword()) :: Canvas.t()
  def circle(canvas, opts \\ []) do
    Canvas.add(canvas, Circle.new(opts))
  end

  @doc """
  Adds an ellipse element to the canvas.

  ## Options

    * `:cx` - X coordinate of center (default: 0)
    * `:cy` - Y coordinate of center (default: 0)
    * `:rx` - Horizontal radius (default: 0)
    * `:ry` - Vertical radius (default: 0)
    * Other presentation attributes

  ## Examples

      iex> canvas = Svg.canvas(:a6) |> Svg.ellipse(cx: 50, cy: 50, rx: 40, ry: 20)
      iex> length(canvas.elements)
      1

  """
  @spec ellipse(Canvas.t(), keyword()) :: Canvas.t()
  def ellipse(canvas, opts \\ []) do
    Canvas.add(canvas, Ellipse.new(opts))
  end

  @doc """
  Adds a polyline element to the canvas.

  ## Options

    * `:points` - List of {x, y} tuples defining the line segments (default: [])
    * Other presentation attributes

  ## Examples

      iex> canvas = Svg.canvas(:a6) |> Svg.polyline(points: [{0, 0}, {50, 25}, {100, 0}], stroke: "green")
      iex> length(canvas.elements)
      1

  """
  @spec polyline(Canvas.t(), keyword()) :: Canvas.t()
  def polyline(canvas, opts \\ []) do
    Canvas.add(canvas, Polyline.new(opts))
  end

  @doc """
  Adds a polygon element to the canvas.

  ## Options

    * `:points` - List of {x, y} tuples defining the vertices (default: [])
    * Other presentation attributes

  ## Examples

      iex> canvas = Svg.canvas(:a6) |> Svg.polygon(points: [{0, 0}, {100, 0}, {50, 100}], fill: "yellow")
      iex> length(canvas.elements)
      1

  """
  @spec polygon(Canvas.t(), keyword()) :: Canvas.t()
  def polygon(canvas, opts \\ []) do
    Canvas.add(canvas, Polygon.new(opts))
  end

  @doc """
  Adds a path element to the canvas.

  ## Options

    * `:d` - Path data string containing drawing commands (default: "")
    * Other presentation attributes

  ## Examples

      iex> canvas = Svg.canvas(:a6) |> Svg.path(d: "M 10 10 L 90 90", stroke: "black")
      iex> length(canvas.elements)
      1

  """
  @spec path(Canvas.t(), keyword()) :: Canvas.t()
  def path(canvas, opts \\ []) do
    Canvas.add(canvas, Path.new(opts))
  end

  @doc """
  Adds a pre-built element struct to the canvas.

  ## Examples

      iex> line = Svg.Elements.Line.new(x1: 0, y1: 0, x2: 100, y2: 100)
      iex> canvas = Svg.canvas(:a6) |> Svg.add(line)
      iex> length(canvas.elements)
      1

  """
  @spec add(Canvas.t(), struct()) :: Canvas.t()
  defdelegate add(canvas, element), to: Canvas

  @doc """
  Adds multiple pre-built element structs to the canvas.

  ## Examples

      iex> elements = [
      ...>   Svg.Elements.Line.new(x1: 0, y1: 0, x2: 100, y2: 100),
      ...>   Svg.Elements.Line.new(x1: 0, y1: 100, x2: 100, y2: 0)
      ...> ]
      iex> canvas = Svg.canvas(:a6) |> Svg.add_all(elements)
      iex> length(canvas.elements)
      2

  """
  @spec add_all(Canvas.t(), [struct()]) :: Canvas.t()
  defdelegate add_all(canvas, elements), to: Canvas

  @doc """
  Converts a physical measurement in millimeters to viewBox pixels.

  ## Examples

      iex> canvas = Svg.canvas(:a6, resolution: :axidraw_fine)
      iex> pixels = Svg.mm_to_px(canvas, 10)
      iex> round(pixels)
      1130

  """
  @spec mm_to_px(Canvas.t(), number()) :: float()
  defdelegate mm_to_px(canvas, mm), to: Canvas

  @doc """
  Converts viewBox pixels to physical millimeters.

  ## Examples

      iex> canvas = Svg.canvas(:a6, resolution: :axidraw_fine)
      iex> mm = Svg.px_to_mm(canvas, 1130)
      iex> Float.round(mm, 2)
      10.0

  """
  @spec px_to_mm(Canvas.t(), number()) :: float()
  defdelegate px_to_mm(canvas, px), to: Canvas

  # Perturbation functions

  @doc """
  Perturbs an element using Perlin noise to create organic, hand-drawn paths.

  Returns a new Path element with the perturbed shape.

  ## Options

    * `:amplitude` - Maximum displacement in pixels (default: 10.0)
    * `:frequency` - Noise frequency, higher = more variation (default: 0.1)
    * `:octaves` - Number of noise layers for detail (default: 1)
    * `:persistence` - Amplitude falloff per octave (default: 0.5)
    * `:seed` - Random seed for reproducibility (default: 0)
    * `:samples` - Number of sample points (default: 100)
    * `:mode` - Force `:cartesian` or `:polar`, or `:auto` (default: :auto)

  ## Examples

      iex> line = Svg.Elements.Line.new(x1: 0, y1: 0, x2: 100, y2: 0, stroke: "black")
      iex> path = Svg.perturb(line, amplitude: 5.0, seed: 42)
      iex> path.d != ""
      true

  """
  @spec perturb(struct(), keyword()) :: Path.t()
  defdelegate perturb(element, opts \\ []), to: Perturb

  @doc """
  Perturbs the last element added to the canvas.

  Replaces the last element with its perturbed version.

  ## Options

  Same as `perturb/2`.

  ## Examples

      iex> canvas = Svg.canvas(:a6)
      ...>   |> Svg.line(x1: 0, y1: 0, x2: 100, y2: 0, stroke: "black")
      ...>   |> Svg.perturb_last(amplitude: 5.0, seed: 42)
      iex> [element] = canvas.elements
      iex> element.__struct__
      Svg.Elements.Path

  """
  @spec perturb_last(Canvas.t(), keyword()) :: Canvas.t()
  def perturb_last(%Canvas{elements: []} = canvas, _opts), do: canvas

  def perturb_last(%Canvas{elements: elements} = canvas, opts) do
    {last, rest} = List.pop_at(elements, -1)
    perturbed = Perturb.perturb(last, opts)
    %{canvas | elements: rest ++ [perturbed]}
  end
end
