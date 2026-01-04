defmodule Svg.Calibration do
  @moduledoc """
  Generates calibration test patterns for plotter/printer accuracy testing.

  The calibration SVG uses an A6 canvas and includes sections comparing clean
  geometric lines with their perturbed counterparts at different line spacings.

  ## Layout

  Two-column layout comparing straight vs. perturbed lines:
    * Left column: Clean straight lines (0.5mm, 0.7mm, 1.0mm, 1.5mm spacing)
    * Right column: Perturbed versions of the same lines using Perlin noise

  Each section contains 5 horizontal lines, each 40mm long.
  """

  alias Svg.Canvas
  alias Svg.Elements.Line
  alias Svg.Perturb
  alias Svg.Units

  @line_length_mm 40
  @lines_per_section 5
  @spacings_mm [0.5, 0.7, 1.0, 1.5]

  # Perturbation settings for calibration
  @perturb_amplitude_mm 1.0
  @perturb_frequency 0.02
  @perturb_seed 42
  @perturb_samples 50

  @doc """
  Generates a calibration test pattern SVG.

  The pattern includes both straight and perturbed lines for visual comparison.

  ## Options

    * `:resolution` - DPI preset or custom integer (default: `:axidraw_fine`)

  ## Examples

      iex> canvas = Svg.Calibration.generate()
      iex> canvas.width_mm
      105.0
      iex> length(canvas.elements) > 0
      true

      iex> canvas = Svg.Calibration.generate(resolution: :illustrator)
      iex> canvas.dpi
      72

  """
  @spec generate(keyword()) :: Canvas.t()
  def generate(opts \\ []) do
    resolution = Keyword.get(opts, :resolution, :axidraw_fine)
    canvas = Canvas.new(:a6, resolution: resolution)
    dpi = canvas.dpi

    # Calculate positions in pixels
    line_length_px = Units.to_pixels(@line_length_mm, dpi)

    # Margins
    margin_mm = 8
    margin_px = Units.to_pixels(margin_mm, dpi)

    # Column positions
    left_x = margin_px
    right_x = margin_px + Units.to_pixels(50, dpi)

    # Section gap between different spacings
    section_gap_mm = 8
    section_gap_px = Units.to_pixels(section_gap_mm, dpi)

    # Starting Y position
    start_y = margin_px

    # Perturbation amplitude in pixels
    amplitude_px = Units.to_pixels(@perturb_amplitude_mm, dpi)

    # Generate all elements
    {straight_elements, perturbed_elements, _final_y} =
      Enum.reduce(@spacings_mm, {[], [], start_y}, fn spacing_mm,
                                                      {straight_acc, perturb_acc, y} ->
        spacing_px = Units.to_pixels(spacing_mm, dpi)

        # Generate straight lines for this section
        straight =
          generate_section_lines(left_x, y, line_length_px, spacing_px)

        # Generate perturbed lines for this section
        perturbed =
          generate_perturbed_section(right_x, y, line_length_px, spacing_px, amplitude_px)

        # Calculate next section start
        section_height = spacing_px * (@lines_per_section - 1)
        next_y = y + section_height + section_gap_px

        {straight_acc ++ straight, perturb_acc ++ perturbed, next_y}
      end)

    all_elements = straight_elements ++ perturbed_elements
    Canvas.add_all(canvas, all_elements)
  end

  # Generates straight lines for a single section
  defp generate_section_lines(x, start_y, line_length, spacing_px) do
    Enum.map(0..(@lines_per_section - 1), fn i ->
      y = start_y + i * spacing_px

      Line.new(
        x1: x,
        y1: y,
        x2: x + line_length,
        y2: y,
        stroke: "black",
        stroke_width: 1
      )
    end)
  end

  # Generates perturbed lines for a single section
  defp generate_perturbed_section(x, start_y, line_length, spacing_px, amplitude_px) do
    Enum.map(0..(@lines_per_section - 1), fn i ->
      y = start_y + i * spacing_px

      # Create a line and perturb it
      line =
        Line.new(
          x1: x,
          y1: y,
          x2: x + line_length,
          y2: y,
          stroke: "black",
          stroke_width: 1
        )

      # Use a different seed for each line to get variety
      seed = @perturb_seed + i * 100 + round(spacing_px)

      Perturb.perturb(line,
        amplitude: amplitude_px,
        frequency: @perturb_frequency,
        seed: seed,
        samples: @perturb_samples
      )
    end)
  end
end
