defmodule Svg.Samples do
  @moduledoc """
  Generates sample SVGs demonstrating progressive perturbation effects.

  Each sample shows a grid of shapes where perturbation increases continuously
  from the first cell to the last, allowing visual comparison of the full
  range of perturbation settings.

  ## Layout

  6 rows × 4 columns = 24 shapes per sample, read left-to-right, top-to-bottom:

    * Cell 1 (Row 1, Col 1): Clean, unperturbed shape
    * Cell 2-4 (Row 1, Col 2-4): Progressively more perturbed
    * Cell 5 (Row 2, Col 1): Slightly more perturbed than Cell 4
    * ... and so on, with each cell more perturbed than the previous

  The perturbation (amplitude and frequency) increases linearly across all 24 cells,
  providing a smooth visual progression from clean geometry to maximum perturbation.
  """

  alias Svg.Canvas
  alias Svg.Elements.{Circle, Rect}
  alias Svg.Perturb
  alias Svg.Units

  @rows 6
  @cols 4
  @total_cells @rows * @cols

  # Perturbation range - linearly interpolated across all 24 cells
  # Cell 0 (row 0, col 0) = unperturbed
  # Cell 23 (row 5, col 3) = maximum perturbation
  @min_amplitude_mm 0.0
  @max_amplitude_mm 3.0
  @min_frequency 0.0
  @max_frequency 0.015

  @doc """
  Generates a sample SVG showing circles with progressive perturbation.

  ## Options

    * `:resolution` - DPI preset or custom integer (default: `:axidraw_fine`)
    * `:radius_mm` - Circle radius in mm (default: 8)

  ## Examples

      iex> canvas = Svg.Samples.circles()
      iex> length(canvas.elements) > 0
      true

  """
  @spec circles(keyword()) :: Canvas.t()
  def circles(opts \\ []) do
    resolution = Keyword.get(opts, :resolution, :axidraw_fine)
    radius_mm = Keyword.get(opts, :radius_mm, 8)

    canvas = Canvas.new(:a6, resolution: resolution)
    dpi = canvas.dpi

    radius_px = Units.to_pixels(radius_mm, dpi)
    elements = generate_circle_grid(canvas, radius_px, dpi)

    Canvas.add_all(canvas, elements)
  end

  @doc """
  Generates a sample SVG showing squares with progressive perturbation.

  ## Options

    * `:resolution` - DPI preset or custom integer (default: `:axidraw_fine`)
    * `:size_mm` - Square side length in mm (default: 14)

  ## Examples

      iex> canvas = Svg.Samples.squares()
      iex> length(canvas.elements) > 0
      true

  """
  @spec squares(keyword()) :: Canvas.t()
  def squares(opts \\ []) do
    resolution = Keyword.get(opts, :resolution, :axidraw_fine)
    size_mm = Keyword.get(opts, :size_mm, 14)

    canvas = Canvas.new(:a6, resolution: resolution)
    dpi = canvas.dpi

    size_px = Units.to_pixels(size_mm, dpi)
    elements = generate_square_grid(canvas, size_px, dpi)

    Canvas.add_all(canvas, elements)
  end

  # Generates a grid of circles with progressive perturbation
  defp generate_circle_grid(canvas, radius_px, dpi) do
    {cell_width, cell_height, margin_x, margin_y} = calculate_grid_layout(canvas, dpi)

    for row <- 0..(@rows - 1), col <- 0..(@cols - 1) do
      # Cell index (0 to 23) for linear interpolation
      cell_index = row * @cols + col

      # Center of this cell
      cx = margin_x + col * cell_width + cell_width / 2
      cy = margin_y + row * cell_height + cell_height / 2

      circle =
        Circle.new(
          cx: cx,
          cy: cy,
          r: radius_px,
          stroke: "black",
          stroke_width: 2,
          fill: "none"
        )

      {amplitude_mm, frequency} = interpolate_perturbation(cell_index)

      if amplitude_mm == 0.0 do
        # Unperturbed (first cell only)
        circle
      else
        amplitude_px = Units.to_pixels(amplitude_mm, dpi)
        seed = 1000 + row * 100 + col

        Perturb.perturb(circle,
          amplitude: amplitude_px,
          frequency: frequency,
          seed: seed,
          samples: 80,
          octaves: 4
        )
      end
    end
  end

  # Generates a grid of squares with progressive perturbation
  defp generate_square_grid(canvas, size_px, dpi) do
    {cell_width, cell_height, margin_x, margin_y} = calculate_grid_layout(canvas, dpi)

    for row <- 0..(@rows - 1), col <- 0..(@cols - 1) do
      # Cell index (0 to 23) for linear interpolation
      cell_index = row * @cols + col

      # Top-left of this cell, centered
      x = margin_x + col * cell_width + (cell_width - size_px) / 2
      y = margin_y + row * cell_height + (cell_height - size_px) / 2

      rect =
        Rect.new(
          x: x,
          y: y,
          width: size_px,
          height: size_px,
          stroke: "black",
          stroke_width: 2,
          fill: "none"
        )

      {amplitude_mm, frequency} = interpolate_perturbation(cell_index)

      if amplitude_mm == 0.0 do
        # Unperturbed (first cell only)
        rect
      else
        amplitude_px = Units.to_pixels(amplitude_mm, dpi)
        seed = 2000 + row * 100 + col

        Perturb.perturb(rect,
          amplitude: amplitude_px,
          frequency: frequency,
          seed: seed,
          samples: 80,
          octaves: 4
        )
      end
    end
  end

  # Calculates grid layout dimensions
  defp calculate_grid_layout(canvas, dpi) do
    margin_mm = 8
    margin_px = Units.to_pixels(margin_mm, dpi)

    {vb_width, vb_height} = canvas.viewbox

    usable_width = vb_width - 2 * margin_px
    usable_height = vb_height - 2 * margin_px

    cell_width = usable_width / @cols
    cell_height = usable_height / @rows

    {cell_width, cell_height, margin_px, margin_px}
  end

  # Linear interpolation of perturbation based on cell index (0 to 23)
  # Cell 0 = unperturbed, Cell 23 = maximum perturbation
  defp interpolate_perturbation(0), do: {0.0, 0.0}

  defp interpolate_perturbation(cell_index) do
    # t goes from 0 to 1 across cells 1-23
    t = cell_index / (@total_cells - 1)

    amplitude = @min_amplitude_mm + t * (@max_amplitude_mm - @min_amplitude_mm)
    frequency = @min_frequency + t * (@max_frequency - @min_frequency)

    {amplitude, frequency}
  end
end
