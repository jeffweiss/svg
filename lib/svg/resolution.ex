defmodule Svg.Resolution do
  @moduledoc """
  DPI (dots per inch) resolution presets for SVG rendering.

  Provides preset resolutions for common plotting and design tools,
  as well as utilities for working with custom DPI values.
  """

  @typedoc """
  A resolution preset identifier.
  """
  @type preset :: :axidraw_fine | :axidraw_fast | :illustrator | :inkscape

  @typedoc """
  A resolution value - either a preset atom or a positive integer DPI.
  """
  @type resolution :: preset() | pos_integer()

  # DPI presets for common tools
  @presets %{
    axidraw_fine: 2870,
    axidraw_fast: 1435,
    illustrator: 72,
    inkscape: 96
  }

  @doc """
  Returns a list of all available resolution preset names.

  ## Examples

      iex> Svg.Resolution.available_presets()
      [:axidraw_fast, :axidraw_fine, :illustrator, :inkscape]

  """
  @spec available_presets() :: [preset()]
  def available_presets do
    @presets |> Map.keys() |> Enum.sort()
  end

  @doc """
  Returns the DPI value for a given resolution.

  Accepts either a preset atom or a custom positive integer DPI value.

  ## Examples

      iex> Svg.Resolution.dpi(:axidraw_fine)
      2870

      iex> Svg.Resolution.dpi(:illustrator)
      72

      iex> Svg.Resolution.dpi(300)
      300

  """
  @spec dpi(resolution()) :: pos_integer()
  def dpi(preset) when is_map_key(@presets, preset) do
    Map.fetch!(@presets, preset)
  end

  def dpi(custom_dpi) when is_integer(custom_dpi) and custom_dpi > 0 do
    custom_dpi
  end

  @doc """
  Checks if a given value is a valid resolution preset name.

  ## Examples

      iex> Svg.Resolution.valid_preset?(:axidraw_fine)
      true

      iex> Svg.Resolution.valid_preset?(:high_res)
      false

  """
  @spec valid_preset?(atom()) :: boolean()
  def valid_preset?(preset) when is_atom(preset) do
    Map.has_key?(@presets, preset)
  end

  def valid_preset?(_), do: false

  @doc """
  Checks if a given value is a valid resolution (preset or custom DPI).

  ## Examples

      iex> Svg.Resolution.valid_resolution?(:axidraw_fine)
      true

      iex> Svg.Resolution.valid_resolution?(300)
      true

      iex> Svg.Resolution.valid_resolution?(-1)
      false

      iex> Svg.Resolution.valid_resolution?("72")
      false

  """
  @spec valid_resolution?(any()) :: boolean()
  def valid_resolution?(resolution) when is_atom(resolution) do
    valid_preset?(resolution)
  end

  def valid_resolution?(dpi) when is_integer(dpi) and dpi > 0, do: true
  def valid_resolution?(_), do: false

  @doc """
  Returns a description of the preset resolution.

  ## Examples

      iex> Svg.Resolution.description(:axidraw_fine)
      "AxiDraw Fine (2870 DPI)"

      iex> Svg.Resolution.description(:illustrator)
      "Adobe Illustrator (72 DPI)"

  """
  @spec description(preset()) :: String.t()
  def description(:axidraw_fine), do: "AxiDraw Fine (2870 DPI)"
  def description(:axidraw_fast), do: "AxiDraw Fast (1435 DPI)"
  def description(:illustrator), do: "Adobe Illustrator (72 DPI)"
  def description(:inkscape), do: "Inkscape (96 DPI)"
end
