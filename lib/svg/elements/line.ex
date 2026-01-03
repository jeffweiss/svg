defmodule Svg.Elements.Line do
  @moduledoc """
  SVG line element.

  Represents a straight line between two points (x1, y1) and (x2, y2).

  ## SVG Reference

  The `<line>` element draws a straight line connecting two points.
  See: https://developer.mozilla.org/en-US/docs/Web/SVG/Element/line
  """

  @behaviour Svg.Elements

  alias Svg.Elements

  @typedoc """
  A line element struct.
  """
  @type t :: %__MODULE__{
          x1: number(),
          y1: number(),
          x2: number(),
          y2: number(),
          attrs: map()
        }

  defstruct x1: 0, y1: 0, x2: 0, y2: 0, attrs: %{}

  @doc """
  Creates a new line element.

  ## Options

    * `:x1` - Starting x coordinate (default: 0)
    * `:y1` - Starting y coordinate (default: 0)
    * `:x2` - Ending x coordinate (default: 0)
    * `:y2` - Ending y coordinate (default: 0)
    * `:stroke` - Stroke color (default: none)
    * `:stroke_width` - Stroke width (default: 1)
    * Other presentation attributes

  ## Examples

      iex> line = Svg.Elements.Line.new(x1: 0, y1: 0, x2: 100, y2: 100)
      iex> line.x1
      0
      iex> line.x2
      100

      iex> line = Svg.Elements.Line.new(x1: 10, y1: 20, x2: 30, y2: 40, stroke: "black")
      iex> line.attrs.stroke
      "black"

  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {attrs, coords} = Elements.extract_presentation_attrs(opts)

    %__MODULE__{
      x1: Keyword.get(coords, :x1, 0),
      y1: Keyword.get(coords, :y1, 0),
      x2: Keyword.get(coords, :x2, 0),
      y2: Keyword.get(coords, :y2, 0),
      attrs: attrs
    }
  end

  @doc """
  Renders the line to an SVG string.

  ## Examples

      iex> line = Svg.Elements.Line.new(x1: 0, y1: 0, x2: 100, y2: 100, stroke: "black")
      iex> svg = Svg.Elements.Line.to_svg(line)
      iex> svg =~ "x1=" and svg =~ "x2=" and svg =~ "stroke="
      true

  """
  @impl Svg.Elements
  @spec to_svg(t()) :: String.t()
  def to_svg(%__MODULE__{} = line) do
    coords = %{
      x1: line.x1,
      y1: line.y1,
      x2: line.x2,
      y2: line.y2
    }

    all_attrs = Map.merge(coords, line.attrs)
    attrs_str = Elements.format_attrs(all_attrs)

    "<line #{attrs_str}/>"
  end
end
