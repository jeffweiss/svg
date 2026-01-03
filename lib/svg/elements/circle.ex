defmodule Svg.Elements.Circle do
  @moduledoc """
  SVG circle element.

  Represents a circle with a center point and radius.

  ## SVG Reference

  The `<circle>` element draws a circle based on a center point and a radius.
  See: https://developer.mozilla.org/en-US/docs/Web/SVG/Element/circle
  """

  @behaviour Svg.Elements

  alias Svg.Elements

  @typedoc """
  A circle element struct.
  """
  @type t :: %__MODULE__{
          cx: number(),
          cy: number(),
          r: number(),
          attrs: map()
        }

  defstruct cx: 0, cy: 0, r: 0, attrs: %{}

  @doc """
  Creates a new circle element.

  ## Options

    * `:cx` - X coordinate of center (default: 0)
    * `:cy` - Y coordinate of center (default: 0)
    * `:r` - Radius (default: 0)
    * Other presentation attributes

  ## Examples

      iex> circle = Svg.Elements.Circle.new(cx: 50, cy: 50, r: 25)
      iex> circle.r
      25

      iex> circle = Svg.Elements.Circle.new(cx: 100, cy: 100, r: 50, fill: "green")
      iex> circle.attrs.fill
      "green"

  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {attrs, coords} = Elements.extract_presentation_attrs(opts)

    %__MODULE__{
      cx: Keyword.get(coords, :cx, 0),
      cy: Keyword.get(coords, :cy, 0),
      r: Keyword.get(coords, :r, 0),
      attrs: attrs
    }
  end

  @doc """
  Renders the circle to an SVG string.

  ## Examples

      iex> circle = Svg.Elements.Circle.new(cx: 50, cy: 50, r: 25, stroke: "black", fill: "none")
      iex> svg = Svg.Elements.Circle.to_svg(circle)
      iex> svg =~ ~s(cx="50") and svg =~ ~s(r="25") and svg =~ ~s(stroke="black")
      true

  """
  @impl Svg.Elements
  @spec to_svg(t()) :: String.t()
  def to_svg(%__MODULE__{} = circle) do
    coords = %{
      cx: circle.cx,
      cy: circle.cy,
      r: circle.r
    }

    all_attrs = Map.merge(coords, circle.attrs)
    attrs_str = Elements.format_attrs(all_attrs)

    "<circle #{attrs_str}/>"
  end
end
