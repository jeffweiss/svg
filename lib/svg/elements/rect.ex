defmodule Svg.Elements.Rect do
  @moduledoc """
  SVG rectangle element.

  Represents a rectangle with optional rounded corners.

  ## SVG Reference

  The `<rect>` element draws a rectangle with a given position, width, and height.
  See: https://developer.mozilla.org/en-US/docs/Web/SVG/Element/rect
  """

  @behaviour Svg.Elements

  alias Svg.Elements

  @typedoc """
  A rectangle element struct.
  """
  @type t :: %__MODULE__{
          x: number(),
          y: number(),
          width: number(),
          height: number(),
          rx: number() | nil,
          ry: number() | nil,
          attrs: map()
        }

  defstruct x: 0, y: 0, width: 0, height: 0, rx: nil, ry: nil, attrs: %{}

  @doc """
  Creates a new rectangle element.

  ## Options

    * `:x` - X coordinate of top-left corner (default: 0)
    * `:y` - Y coordinate of top-left corner (default: 0)
    * `:width` - Width of the rectangle (default: 0)
    * `:height` - Height of the rectangle (default: 0)
    * `:rx` - Horizontal corner radius (optional)
    * `:ry` - Vertical corner radius (optional)
    * Other presentation attributes

  ## Examples

      iex> rect = Svg.Elements.Rect.new(x: 10, y: 20, width: 100, height: 50)
      iex> rect.width
      100

      iex> rect = Svg.Elements.Rect.new(width: 100, height: 50, rx: 5, fill: "blue")
      iex> rect.rx
      5
      iex> rect.attrs.fill
      "blue"

  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {attrs, coords} = Elements.extract_presentation_attrs(opts)

    %__MODULE__{
      x: Keyword.get(coords, :x, 0),
      y: Keyword.get(coords, :y, 0),
      width: Keyword.get(coords, :width, 0),
      height: Keyword.get(coords, :height, 0),
      rx: Keyword.get(coords, :rx),
      ry: Keyword.get(coords, :ry),
      attrs: attrs
    }
  end

  @doc """
  Renders the rectangle to an SVG string.

  ## Examples

      iex> rect = Svg.Elements.Rect.new(x: 10, y: 20, width: 100, height: 50, fill: "red")
      iex> svg = Svg.Elements.Rect.to_svg(rect)
      iex> svg =~ ~s(width="100") and svg =~ ~s(height="50") and svg =~ ~s(fill="red")
      true

      iex> rect = Svg.Elements.Rect.new(width: 100, height: 50, rx: 5)
      iex> svg = Svg.Elements.Rect.to_svg(rect)
      iex> svg =~ ~s(rx="5")
      true

  """
  @impl Svg.Elements
  @spec to_svg(t()) :: String.t()
  def to_svg(%__MODULE__{} = rect) do
    coords =
      %{
        x: rect.x,
        y: rect.y,
        width: rect.width,
        height: rect.height,
        rx: rect.rx,
        ry: rect.ry
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    all_attrs = Map.merge(coords, rect.attrs)
    attrs_str = Elements.format_attrs(all_attrs)

    "<rect #{attrs_str}/>"
  end
end
