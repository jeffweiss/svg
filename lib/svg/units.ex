defmodule Svg.Units do
  @moduledoc """
  Unit conversion utilities for SVG dimensions.

  Provides functions to convert between physical units (millimeters, inches)
  and pixel values based on DPI (dots per inch) settings.
  """

  @mm_per_inch 25.4

  @doc """
  Converts millimeters to inches.

  ## Examples

      iex> Svg.Units.mm_to_inches(25.4)
      1.0

      iex> inches = Svg.Units.mm_to_inches(105)
      iex> Float.round(inches, 4)
      4.1339

  """
  @spec mm_to_inches(number()) :: float()
  def mm_to_inches(mm) when is_number(mm) do
    mm / @mm_per_inch
  end

  @doc """
  Converts inches to millimeters.

  ## Examples

      iex> Svg.Units.inches_to_mm(1.0)
      25.4

      iex> mm = Svg.Units.inches_to_mm(8.5)
      iex> Float.round(mm, 1)
      215.9

  """
  @spec inches_to_mm(number()) :: float()
  def inches_to_mm(inches) when is_number(inches) do
    inches * @mm_per_inch
  end

  @doc """
  Converts a physical measurement to pixels based on DPI.

  Accepts measurements in millimeters (default) or inches.

  ## Examples

      iex> Svg.Units.to_pixels(25.4, 72)
      72.0

      iex> Svg.Units.to_pixels(1.0, 72, :inches)
      72.0

      iex> pixels = Svg.Units.to_pixels(105, 2870)
      iex> round(pixels)
      11864

  """
  @spec to_pixels(number(), number(), :mm | :inches) :: float()
  def to_pixels(value, dpi, unit \\ :mm)

  def to_pixels(value, dpi, :mm) when is_number(value) and is_number(dpi) do
    inches = mm_to_inches(value)
    inches * dpi
  end

  def to_pixels(value, dpi, :inches) when is_number(value) and is_number(dpi) do
    value * dpi
  end

  @doc """
  Converts pixels to millimeters based on DPI.

  ## Examples

      iex> Svg.Units.pixels_to_mm(72, 72)
      25.4

      iex> mm = Svg.Units.pixels_to_mm(11864, 2870)
      iex> Float.round(mm, 1)
      105.0

  """
  @spec pixels_to_mm(number(), number()) :: float()
  def pixels_to_mm(pixels, dpi) when is_number(pixels) and is_number(dpi) do
    inches = pixels / dpi
    inches_to_mm(inches)
  end

  @doc """
  Converts pixels to inches based on DPI.

  ## Examples

      iex> Svg.Units.pixels_to_inches(72, 72)
      1.0

      iex> Svg.Units.pixels_to_inches(300, 300)
      1.0

  """
  @spec pixels_to_inches(number(), number()) :: float()
  def pixels_to_inches(pixels, dpi) when is_number(pixels) and is_number(dpi) do
    pixels / dpi
  end

  @doc """
  Returns the number of millimeters per inch.

  ## Examples

      iex> Svg.Units.mm_per_inch()
      25.4

  """
  @spec mm_per_inch() :: float()
  def mm_per_inch, do: @mm_per_inch
end
