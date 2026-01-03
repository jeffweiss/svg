defmodule Svg.Elements.Path do
  @moduledoc """
  SVG path element.

  Represents a complex shape defined by path commands.

  ## SVG Reference

  The `<path>` element is the most powerful element in SVG. It can draw
  anything from simple lines to complex curves using path commands.
  See: https://developer.mozilla.org/en-US/docs/Web/SVG/Element/path

  ## Path Commands

    * `M x y` - Move to (absolute)
    * `m dx dy` - Move to (relative)
    * `L x y` - Line to (absolute)
    * `l dx dy` - Line to (relative)
    * `H x` - Horizontal line to (absolute)
    * `h dx` - Horizontal line to (relative)
    * `V y` - Vertical line to (absolute)
    * `v dy` - Vertical line to (relative)
    * `Q x1 y1 x y` - Quadratic Bézier curve (absolute)
    * `C x1 y1 x2 y2 x y` - Cubic Bézier curve (absolute)
    * `A rx ry rotation large-arc sweep x y` - Arc (absolute)
    * `Z` or `z` - Close path

  """

  @behaviour Svg.Elements

  alias Svg.Elements

  @typedoc """
  A path element struct.
  """
  @type t :: %__MODULE__{
          d: String.t(),
          attrs: map()
        }

  defstruct d: "", attrs: %{}

  @doc """
  Creates a new path element.

  ## Options

    * `:d` - Path data string containing drawing commands (default: "")
    * Other presentation attributes

  ## Examples

      iex> path = Svg.Elements.Path.new(d: "M 10 10 L 90 90")
      iex> path.d
      "M 10 10 L 90 90"

      iex> path = Svg.Elements.Path.new(d: "M 0 0 L 100 100", stroke: "black", fill: "none")
      iex> path.attrs.stroke
      "black"

  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {attrs, coords} = Elements.extract_presentation_attrs(opts)

    %__MODULE__{
      d: Keyword.get(coords, :d, ""),
      attrs: attrs
    }
  end

  @doc """
  Renders the path to an SVG string.

  ## Examples

      iex> path = Svg.Elements.Path.new(d: "M 10 10 L 90 90", stroke: "black", fill: "none")
      iex> Svg.Elements.Path.to_svg(path)
      ~s(<path d="M 10 10 L 90 90" fill="none" stroke="black"/>)

  """
  @impl Svg.Elements
  @spec to_svg(t()) :: String.t()
  def to_svg(%__MODULE__{} = path) do
    attrs_str = Elements.format_attrs(path.attrs)

    if attrs_str == "" do
      ~s(<path d="#{path.d}"/>)
    else
      ~s(<path d="#{path.d}" #{attrs_str}/>)
    end
  end

  @doc """
  Builds a path data string from a list of commands.

  This is a convenience function for building path data programmatically.

  ## Examples

      iex> commands = [{:M, 10, 10}, {:L, 90, 90}, :Z]
      iex> Svg.Elements.Path.build_d(commands)
      "M 10 10 L 90 90 Z"

      iex> commands = [{:M, 0, 0}, {:Q, 50, 0, 50, 50}, {:T, 100, 100}]
      iex> Svg.Elements.Path.build_d(commands)
      "M 0 0 Q 50 0 50 50 T 100 100"

  """
  @spec build_d([tuple() | atom()]) :: String.t()
  def build_d(commands) when is_list(commands) do
    Enum.map_join(commands, " ", &format_command/1)
  end

  defp format_command(:Z), do: "Z"
  defp format_command(:z), do: "z"

  defp format_command({cmd, x, y}) when cmd in [:M, :m, :L, :l, :T, :t] do
    "#{cmd} #{Elements.format_value(x)} #{Elements.format_value(y)}"
  end

  defp format_command({cmd, x}) when cmd in [:H, :h, :V, :v] do
    "#{cmd} #{Elements.format_value(x)}"
  end

  defp format_command({cmd, x1, y1, x, y}) when cmd in [:Q, :q, :S, :s] do
    "#{cmd} #{Elements.format_value(x1)} #{Elements.format_value(y1)} #{Elements.format_value(x)} #{Elements.format_value(y)}"
  end

  defp format_command({cmd, x1, y1, x2, y2, x, y}) when cmd in [:C, :c] do
    "#{cmd} #{Elements.format_value(x1)} #{Elements.format_value(y1)} #{Elements.format_value(x2)} #{Elements.format_value(y2)} #{Elements.format_value(x)} #{Elements.format_value(y)}"
  end

  defp format_command({cmd, rx, ry, rotation, large_arc, sweep, x, y}) when cmd in [:A, :a] do
    "#{cmd} #{Elements.format_value(rx)} #{Elements.format_value(ry)} #{Elements.format_value(rotation)} #{large_arc} #{sweep} #{Elements.format_value(x)} #{Elements.format_value(y)}"
  end
end
