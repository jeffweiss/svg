defmodule Svg.Calibration do
  @moduledoc """
  Generates calibration test patterns for plotter/printer accuracy testing.

  The calibration SVG uses an A6 canvas and includes sections comparing clean
  geometric shapes with their perturbed counterparts.

  ## Layout

  Two-column layout comparing clean vs. perturbed shapes:

  ### Lines Section
    * Left column: Clean straight lines at various spacings (0.4mm to 1.5mm)
    * Right column: Perturbed versions using Perlin noise
    * Each spacing section contains 5 horizontal lines, each 40mm long

  ### Circles Section
    * Left column: Clean circles at various radii (3mm, 5mm, 8mm, 12mm)
    * Right column: Perturbed versions using polar Perlin noise
  """

  alias Svg.Canvas
  alias Svg.Elements.{Circle, Line}
  alias Svg.Perturb
  alias Svg.Units

  @line_length_mm 40
  @lines_per_section 5
  @spacings_mm [0.4, 0.5, 0.7, 0.9, 1.0, 1.2]

  # Circle radii in mm
  @circle_radii_mm [3, 5, 8, 12]

  # Perturbation settings for calibration
  @perturb_amplitude_mm 1.0
  @perturb_frequency 0.001
  @perturb_seed 42
  @perturb_samples @line_length_mm * 2
  @circle_perturb_samples 360

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

    # Generate line elements
    {straight_lines, perturbed_lines, circles_start_y} =
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

    # Generate circle elements
    {clean_circles, perturbed_circles} =
      generate_circle_sections(left_x, right_x, circles_start_y, dpi, amplitude_px)

    all_elements = straight_lines ++ perturbed_lines ++ clean_circles ++ perturbed_circles
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

  # Generates circle sections with clean and perturbed versions
  defp generate_circle_sections(left_x, right_x, start_y, dpi, amplitude_px) do
    # Calculate column centers for circles
    column_width_px = Units.to_pixels(40, dpi)
    left_center_x = left_x + column_width_px / 2
    right_center_x = right_x + column_width_px / 2

    # Spacing between circle rows
    row_gap_mm = 5

    {clean, perturbed, _final_y} =
      Enum.reduce(@circle_radii_mm, {[], [], start_y}, fn radius_mm,
                                                          {clean_acc, perturb_acc, y} ->
        radius_px = Units.to_pixels(radius_mm, dpi)

        # Center Y for this row (offset by radius so circles don't overlap)
        center_y = y + radius_px

        # Clean circle
        clean_circle =
          Circle.new(
            cx: left_center_x,
            cy: center_y,
            r: radius_px,
            stroke: "black",
            stroke_width: 1,
            fill: "none"
          )

        # Perturbed circle
        perturbed_circle =
          Circle.new(
            cx: right_center_x,
            cy: center_y,
            r: radius_px,
            stroke: "black",
            stroke_width: 2,
            fill: "none"
          )

        seed = @perturb_seed + round(radius_px) * 1000

        perturbed_path =
          Perturb.perturb(perturbed_circle,
            amplitude: amplitude_px * 2,
            frequency: @perturb_frequency,
            seed: seed,
            samples: @circle_perturb_samples
          )

        # Next row starts after this circle plus gap
        next_y = center_y + radius_px + Units.to_pixels(row_gap_mm, dpi)

        {clean_acc ++ [clean_circle], perturb_acc ++ [perturbed_path], next_y}
      end)

    {clean, perturbed}
  end
end
