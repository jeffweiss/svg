defmodule Svg.Elements do
  @moduledoc """
  Behaviour and utilities for SVG elements.

  All shape modules implement this behaviour to provide a consistent
  interface for rendering elements to SVG markup.
  """

  @typedoc """
  Common SVG presentation attributes that can be applied to any element.
  """
  @type presentation_attrs :: %{
          optional(:stroke) => String.t(),
          optional(:stroke_width) => number(),
          optional(:stroke_opacity) => number(),
          optional(:stroke_linecap) => :butt | :round | :square,
          optional(:stroke_linejoin) => :miter | :round | :bevel,
          optional(:fill) => String.t(),
          optional(:fill_opacity) => number(),
          optional(:opacity) => number(),
          optional(:transform) => String.t()
        }

  @doc """
  Converts an element struct to its SVG string representation.
  """
  @callback to_svg(element :: struct()) :: String.t()

  @doc """
  Formats common presentation attributes into SVG attribute strings.

  Converts snake_case attribute names to kebab-case for SVG compatibility.
  Attributes are sorted alphabetically for consistent output.

  ## Examples

      iex> Svg.Elements.format_attrs(%{stroke: "black", stroke_width: 2})
      ~s(stroke-width="2" stroke="black")

      iex> Svg.Elements.format_attrs(%{fill: "none", opacity: 0.5})
      ~s(fill="none" opacity="0.5")

  """
  @spec format_attrs(map()) :: String.t()
  def format_attrs(attrs) when is_map(attrs) do
    attrs
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.map(fn {key, value} ->
      attr_name = key |> to_string() |> String.replace("_", "-")
      ~s(#{attr_name}="#{format_value(value)}")
    end)
    |> Enum.sort()
    |> Enum.join(" ")
  end

  @doc """
  Formats a list of points for polyline or polygon elements.

  ## Examples

      iex> Svg.Elements.format_points([{0, 0}, {10, 10}, {20, 0}])
      "0,0 10,10 20,0"

      iex> Svg.Elements.format_points([{0.5, 1.5}, {10.0, 20.0}])
      "0.5,1.5 10.0,20.0"

  """
  @spec format_points([{number(), number()}]) :: String.t()
  def format_points(points) when is_list(points) do
    Enum.map_join(points, " ", fn {x, y} -> "#{format_value(x)},#{format_value(y)}" end)
  end

  @doc """
  Formats a numeric value, removing trailing zeros for floats.

  ## Examples

      iex> Svg.Elements.format_value(10)
      "10"

      iex> Svg.Elements.format_value(10.0)
      "10.0"

      iex> Svg.Elements.format_value(10.500)
      "10.5"

  """
  @spec format_value(any()) :: String.t()
  def format_value(value) when is_integer(value), do: Integer.to_string(value)

  def format_value(value) when is_float(value) do
    # Format with reasonable precision, removing trailing zeros
    :erlang.float_to_binary(value, [:compact, decimals: 10])
  end

  def format_value(value) when is_atom(value), do: Atom.to_string(value)
  def format_value(value), do: to_string(value)

  @doc """
  Extracts presentation attributes from a keyword list or map.

  Returns a tuple of {presentation_attrs, remaining_attrs}.

  ## Examples

      iex> {pres, rest} = Svg.Elements.extract_presentation_attrs(stroke: "black", x1: 0, y1: 0)
      iex> pres
      %{stroke: "black"}
      iex> rest
      [x1: 0, y1: 0]

  """
  @spec extract_presentation_attrs(keyword() | map()) :: {map(), keyword()}
  def extract_presentation_attrs(attrs) when is_list(attrs) do
    presentation_keys = [
      :stroke,
      :stroke_width,
      :stroke_opacity,
      :stroke_linecap,
      :stroke_linejoin,
      :stroke_dasharray,
      :fill,
      :fill_opacity,
      :opacity,
      :transform
    ]

    {presentation, rest} = Keyword.split(attrs, presentation_keys)
    {Map.new(presentation), rest}
  end

  def extract_presentation_attrs(attrs) when is_map(attrs) do
    extract_presentation_attrs(Map.to_list(attrs))
  end
end
