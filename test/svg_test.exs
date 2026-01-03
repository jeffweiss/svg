defmodule SvgTest do
  use ExUnit.Case
  doctest Svg
  doctest Svg.Canvas
  doctest Svg.Units
  doctest Svg.PaperSize
  doctest Svg.Resolution
  doctest Svg.Elements
  doctest Svg.Elements.Line
  doctest Svg.Elements.Rect
  doctest Svg.Elements.Circle
  doctest Svg.Elements.Ellipse
  doctest Svg.Elements.Polyline
  doctest Svg.Elements.Polygon
  doctest Svg.Elements.Path
  doctest Svg.Calibration

  describe "Svg.canvas/2" do
    test "creates a canvas with paper size" do
      canvas = Svg.canvas(:a6)
      assert canvas.width_mm == 105.0
      assert canvas.height_mm == 148.0
    end

    test "creates a canvas with custom resolution" do
      canvas = Svg.canvas(:a6, resolution: :axidraw_fine)
      assert canvas.dpi == 2870
    end

    test "creates a canvas in landscape orientation" do
      canvas = Svg.canvas(:a6, orientation: :landscape)
      assert canvas.width_mm == 148.0
      assert canvas.height_mm == 105.0
    end
  end

  describe "Svg.to_svg/1" do
    test "renders a valid SVG document" do
      svg =
        Svg.canvas(:a6)
        |> Svg.line(x1: 0, y1: 0, x2: 100, y2: 100, stroke: "black")
        |> Svg.to_svg()

      assert svg =~ ~s(xmlns="http://www.w3.org/2000/svg")
      assert svg =~ ~s(width="105.0mm")
      assert svg =~ ~s(height="148.0mm")
      assert svg =~ "<line"
    end
  end

  describe "element helpers" do
    test "adds line elements" do
      canvas = Svg.canvas(:a6) |> Svg.line(x1: 10, y1: 20, x2: 30, y2: 40)
      assert length(canvas.elements) == 1
      [line] = canvas.elements
      assert line.x1 == 10
      assert line.x2 == 30
    end

    test "adds rect elements" do
      canvas = Svg.canvas(:a6) |> Svg.rect(x: 10, y: 20, width: 100, height: 50)
      assert length(canvas.elements) == 1
      [rect] = canvas.elements
      assert rect.width == 100
    end

    test "adds circle elements" do
      canvas = Svg.canvas(:a6) |> Svg.circle(cx: 50, cy: 50, r: 25)
      assert length(canvas.elements) == 1
      [circle] = canvas.elements
      assert circle.r == 25
    end

    test "adds multiple elements" do
      canvas =
        Svg.canvas(:a6)
        |> Svg.line(x1: 0, y1: 0, x2: 100, y2: 100)
        |> Svg.rect(x: 10, y: 10, width: 50, height: 50)
        |> Svg.circle(cx: 100, cy: 100, r: 20)

      assert length(canvas.elements) == 3
    end
  end

  describe "Svg.Calibration" do
    test "generates a calibration pattern" do
      canvas = Svg.Calibration.generate()

      assert canvas.width_mm == 105.0
      assert canvas.height_mm == 148.0
      # 4 sections x 5 lines each = 20 lines
      assert length(canvas.elements) == 20
    end

    test "accepts custom resolution" do
      canvas = Svg.Calibration.generate(resolution: :illustrator)
      assert canvas.dpi == 72
    end
  end
end
