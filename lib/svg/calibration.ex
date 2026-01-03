defmodule Svg.Calibration do
  @moduledoc """
  Generates calibration test patterns for plotter/printer accuracy testing.

  The calibration SVG uses an A6 canvas and includes multiple sections with
  different line spacings to verify precision at various scales.

  ## Layout

  The pattern is organized in two columns:
    * Left column: 0.5mm and 0.7mm spacing (tighter tolerances)
    * Right column: 1.0mm and 1.5mm spacing (wider tolerances)

  Each section contains 5 horizontal lines, each 40mm long.
  """

  alias Svg.Canvas
  alias Svg.Elements.Line

  @line_length_mm 40
  @lines_per_section 5

  @doc """
  Generates a calibration test pattern SVG.

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

    # Calculate positions in pixels
    dpi = canvas.dpi
    line_length_px = mm_to_px(@line_length_mm, dpi)

    # Margins and column layout
    margin_mm = 10
    margin_px = mm_to_px(margin_mm, dpi)

    # Column width: roughly half the page minus margins
    column_width_mm = 40

    # Section spacing (vertical gap between sections in same column)
    section_gap_mm = 15
    section_gap_px = mm_to_px(section_gap_mm, dpi)

    # Left column: x = margin
    left_x = margin_px
    # Right column: x = margin + column_width + gap
    right_x = margin_px + mm_to_px(column_width_mm + 10, dpi)

    # Starting Y position
    start_y = margin_px

    # Generate all line elements
    elements =
      generate_column_elements(left_x, start_y, line_length_px, 0.5, 0.7, dpi, section_gap_px) ++
        generate_column_elements(right_x, start_y, line_length_px, 1.0, 1.5, dpi, section_gap_px)

    Canvas.add_all(canvas, elements)
  end

  # Generates lines for both sections in a column
  defp generate_column_elements(x, start_y, line_length, top_spacing, bottom_spacing, dpi, gap) do
    top_section = generate_section_lines(x, start_y, line_length, top_spacing, dpi)

    # Calculate where the bottom section starts
    top_section_height = mm_to_px(top_spacing * (@lines_per_section - 1), dpi)
    bottom_start_y = start_y + top_section_height + gap

    bottom_section = generate_section_lines(x, bottom_start_y, line_length, bottom_spacing, dpi)

    top_section ++ bottom_section
  end

  # Generates lines for a single section
  defp generate_section_lines(x, start_y, line_length, spacing_mm, dpi) do
    spacing_px = mm_to_px(spacing_mm, dpi)

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

  defp mm_to_px(mm, dpi) do
    mm * dpi / 25.4
  end
end
