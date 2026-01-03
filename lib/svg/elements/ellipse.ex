defmodule Svg.Elements.Ellipse do
  @moduledoc """
  SVG ellipse element.

  Represents an ellipse with a center point and two radii.

  ## SVG Reference

  The `<ellipse>` element draws an ellipse based on a center coordinate
  and both x and y radii.
  See: https://developer.mozilla.org/en-US/docs/Web/SVG/Element/ellipse
  """

  @behaviour Svg.Elements

  alias Svg.Elements

  @typedoc """
  An ellipse element struct.
  """
  @type t :: %__MODULE__{
          cx: number(),
          cy: number(),
          rx: number(),
          ry: number(),
          attrs: map()
        }

  defstruct cx: 0, cy: 0, rx: 0, ry: 0, attrs: %{}

  @doc """
  Creates a new ellipse element.

  ## Options

    * `:cx` - X coordinate of center (default: 0)
    * `:cy` - Y coordinate of center (default: 0)
    * `:rx` - Horizontal radius (default: 0)
    * `:ry` - Vertical radius (default: 0)
    * Other presentation attributes

  ## Examples

      iex> ellipse = Svg.Elements.Ellipse.new(cx: 50, cy: 50, rx: 40, ry: 20)
      iex> ellipse.rx
      40
      iex> ellipse.ry
      20

      iex> ellipse = Svg.Elements.Ellipse.new(cx: 100, cy: 100, rx: 50, ry: 30, fill: "purple")
      iex> ellipse.attrs.fill
      "purple"

  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {attrs, coords} = Elements.extract_presentation_attrs(opts)

    %__MODULE__{
      cx: Keyword.get(coords, :cx, 0),
      cy: Keyword.get(coords, :cy, 0),
      rx: Keyword.get(coords, :rx, 0),
      ry: Keyword.get(coords, :ry, 0),
      attrs: attrs
    }
  end

  @doc """
  Renders the ellipse to an SVG string.

  ## Examples

      iex> ellipse = Svg.Elements.Ellipse.new(cx: 50, cy: 50, rx: 40, ry: 20, stroke: "black")
      iex> Svg.Elements.Ellipse.to_svg(ellipse)
      ~s(<ellipse cx="50" cy="50" rx="40" ry="20" stroke="black"/>)

  """
  @impl Svg.Elements
  @spec to_svg(t()) :: String.t()
  def to_svg(%__MODULE__{} = ellipse) do
    coords = %{
      cx: ellipse.cx,
      cy: ellipse.cy,
      rx: ellipse.rx,
      ry: ellipse.ry
    }

    all_attrs = Map.merge(coords, ellipse.attrs)
    attrs_str = Elements.format_attrs(all_attrs)

    "<ellipse #{attrs_str}/>"
  end
end
