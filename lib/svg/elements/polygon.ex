defmodule Svg.Elements.Polygon do
  @moduledoc """
  SVG polygon element.

  Represents a closed shape consisting of straight line segments.

  ## SVG Reference

  The `<polygon>` element defines a closed shape consisting of a set of
  connected straight line segments. The last point is connected to the first.
  See: https://developer.mozilla.org/en-US/docs/Web/SVG/Element/polygon
  """

  @behaviour Svg.Elements

  alias Svg.Elements

  @typedoc """
  A polygon element struct.
  """
  @type t :: %__MODULE__{
          points: [{number(), number()}],
          attrs: map()
        }

  defstruct points: [], attrs: %{}

  @doc """
  Creates a new polygon element.

  ## Options

    * `:points` - List of {x, y} tuples defining the vertices (default: [])
    * Other presentation attributes

  ## Examples

      iex> polygon = Svg.Elements.Polygon.new(points: [{0, 0}, {100, 0}, {50, 100}])
      iex> polygon.points
      [{0, 0}, {100, 0}, {50, 100}]

      iex> polygon = Svg.Elements.Polygon.new(points: [{0, 0}, {100, 0}, {50, 100}], fill: "red")
      iex> polygon.attrs.fill
      "red"

  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {attrs, coords} = Elements.extract_presentation_attrs(opts)

    %__MODULE__{
      points: Keyword.get(coords, :points, []),
      attrs: attrs
    }
  end

  @doc """
  Renders the polygon to an SVG string.

  ## Examples

      iex> polygon = Svg.Elements.Polygon.new(points: [{0, 0}, {100, 0}, {50, 100}], fill: "blue", stroke: "black")
      iex> Svg.Elements.Polygon.to_svg(polygon)
      ~s(<polygon points="0,0 100,0 50,100" fill="blue" stroke="black"/>)

  """
  @impl Svg.Elements
  @spec to_svg(t()) :: String.t()
  def to_svg(%__MODULE__{} = polygon) do
    points_str = Elements.format_points(polygon.points)
    attrs_str = Elements.format_attrs(polygon.attrs)

    if attrs_str == "" do
      ~s(<polygon points="#{points_str}"/>)
    else
      ~s(<polygon points="#{points_str}" #{attrs_str}/>)
    end
  end
end
