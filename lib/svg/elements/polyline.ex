defmodule Svg.Elements.Polyline do
  @moduledoc """
  SVG polyline element.

  Represents a connected series of straight line segments (open shape).

  ## SVG Reference

  The `<polyline>` element creates straight lines connecting several points.
  Unlike polygon, it does not connect the last point back to the first.
  See: https://developer.mozilla.org/en-US/docs/Web/SVG/Element/polyline
  """

  @behaviour Svg.Elements

  alias Svg.Elements

  @typedoc """
  A polyline element struct.
  """
  @type t :: %__MODULE__{
          points: [{number(), number()}],
          attrs: map()
        }

  defstruct points: [], attrs: %{}

  @doc """
  Creates a new polyline element.

  ## Options

    * `:points` - List of {x, y} tuples defining the line segments (default: [])
    * Other presentation attributes

  ## Examples

      iex> polyline = Svg.Elements.Polyline.new(points: [{0, 0}, {50, 25}, {100, 0}])
      iex> polyline.points
      [{0, 0}, {50, 25}, {100, 0}]

      iex> polyline = Svg.Elements.Polyline.new(points: [{0, 0}, {100, 100}], stroke: "blue")
      iex> polyline.attrs.stroke
      "blue"

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
  Renders the polyline to an SVG string.

  ## Examples

      iex> polyline = Svg.Elements.Polyline.new(points: [{0, 0}, {50, 25}, {100, 0}], stroke: "black", fill: "none")
      iex> Svg.Elements.Polyline.to_svg(polyline)
      ~s(<polyline points="0,0 50,25 100,0" fill="none" stroke="black"/>)

  """
  @impl Svg.Elements
  @spec to_svg(t()) :: String.t()
  def to_svg(%__MODULE__{} = polyline) do
    points_str = Elements.format_points(polyline.points)
    attrs_str = Elements.format_attrs(polyline.attrs)

    if attrs_str == "" do
      ~s(<polyline points="#{points_str}"/>)
    else
      ~s(<polyline points="#{points_str}" #{attrs_str}/>)
    end
  end
end
