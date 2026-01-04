defmodule SvgTest do
  use ExUnit.Case

  alias Svg.Elements.{Circle, Line, Path}

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
  doctest Svg.Noise
  doctest Svg.Perturb

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
    test "generates a calibration pattern with straight and perturbed lines" do
      canvas = Svg.Calibration.generate()

      assert canvas.width_mm == 105.0
      assert canvas.height_mm == 148.0
      # 4 spacings x 5 lines x 2 columns (straight + perturbed) = 40 elements
      assert length(canvas.elements) == 40
    end

    test "accepts custom resolution" do
      canvas = Svg.Calibration.generate(resolution: :illustrator)
      assert canvas.dpi == 72
    end
  end

  describe "Svg.Noise" do
    test "generates reproducible noise with the same seed" do
      state1 = Svg.Noise.seed(42)
      state2 = Svg.Noise.seed(42)

      assert Svg.Noise.perlin2(1.0, 1.0, state1) == Svg.Noise.perlin2(1.0, 1.0, state2)
    end

    test "generates different noise with different seeds" do
      state1 = Svg.Noise.seed(42)
      state2 = Svg.Noise.seed(123)

      # Use non-integer coordinates to avoid grid points
      refute Svg.Noise.perlin2(1.5, 2.3, state1) == Svg.Noise.perlin2(1.5, 2.3, state2)
    end

    test "perlin2 returns values in expected range" do
      state = Svg.Noise.seed(42)

      for x <- [0.0, 0.5, 1.0, 2.5, 10.0] do
        for y <- [0.0, 0.5, 1.0, 2.5, 10.0] do
          value = Svg.Noise.perlin2(x, y, state)
          assert value >= -1 and value <= 1
        end
      end
    end

    test "simplex2 returns values in expected range" do
      state = Svg.Noise.seed(42)

      for x <- [0.0, 0.5, 1.0, 2.5, 10.0] do
        for y <- [0.0, 0.5, 1.0, 2.5, 10.0] do
          value = Svg.Noise.simplex2(x, y, state)
          assert value >= -1 and value <= 1
        end
      end
    end
  end

  describe "Svg.Perturb" do
    test "perturbs a line element" do
      line = Line.new(x1: 0, y1: 0, x2: 100, y2: 0, stroke: "black")
      path = Svg.Perturb.perturb(line, amplitude: 5.0, seed: 42)

      assert path.__struct__ == Path
      assert path.d =~ "M"
      assert path.d =~ "L"
    end

    test "perturbs a circle element using polar noise" do
      circle = Circle.new(cx: 50, cy: 50, r: 25, stroke: "black")
      path = Svg.Perturb.perturb(circle, amplitude: 5.0, seed: 42)

      assert path.__struct__ == Path
      assert path.d =~ "M"
      assert path.d =~ "Z"
    end

    test "same seed produces same perturbation" do
      line = Line.new(x1: 0, y1: 0, x2: 100, y2: 0)

      path1 = Svg.Perturb.perturb(line, seed: 42)
      path2 = Svg.Perturb.perturb(line, seed: 42)

      assert path1.d == path2.d
    end

    test "different seeds produce different perturbations" do
      line = Line.new(x1: 0, y1: 0, x2: 100, y2: 0)

      path1 = Svg.Perturb.perturb(line, seed: 42)
      path2 = Svg.Perturb.perturb(line, seed: 123)

      refute path1.d == path2.d
    end

    test "different amplitudes produce different perturbations" do
      line = Line.new(x1: 0, y1: 0, x2: 100, y2: 0)

      path1 = Svg.Perturb.perturb(line, amplitude: 5.0, seed: 42)
      path2 = Svg.Perturb.perturb(line, amplitude: 20.0, seed: 42)

      refute path1.d == path2.d
    end

    test "different frequencies produce different perturbations" do
      line = Line.new(x1: 0, y1: 0, x2: 100, y2: 0)

      path1 = Svg.Perturb.perturb(line, frequency: 0.01, seed: 42)
      path2 = Svg.Perturb.perturb(line, frequency: 0.5, seed: 42)

      refute path1.d == path2.d
    end

    test "higher amplitude produces larger displacements" do
      line = Line.new(x1: 0, y1: 0, x2: 100, y2: 0)

      path_small = Svg.Perturb.perturb(line, amplitude: 1.0, seed: 42, samples: 20)
      path_large = Svg.Perturb.perturb(line, amplitude: 50.0, seed: 42, samples: 20)

      # Extract Y values from path data and compare max displacement
      small_ys = extract_y_values(path_small.d)
      large_ys = extract_y_values(path_large.d)

      small_max_displacement = Enum.max(Enum.map(small_ys, &abs/1))
      large_max_displacement = Enum.max(Enum.map(large_ys, &abs/1))

      # Larger amplitude should produce larger displacements
      assert large_max_displacement > small_max_displacement
    end

    test "zero amplitude produces no displacement from original path" do
      line = Line.new(x1: 0, y1: 0, x2: 100, y2: 0)

      path = Svg.Perturb.perturb(line, amplitude: 0.0, seed: 42, samples: 20)

      # All Y values should be 0 (no displacement from horizontal line)
      ys = extract_y_values(path.d)
      assert Enum.all?(ys, fn y -> abs(y) < 0.01 end)
    end

    test "samples option controls number of points" do
      line = Line.new(x1: 0, y1: 0, x2: 100, y2: 0)

      path_few = Svg.Perturb.perturb(line, samples: 10, seed: 42)
      path_many = Svg.Perturb.perturb(line, samples: 100, seed: 42)

      # Count L commands in path data
      few_points = count_path_commands(path_few.d)
      many_points = count_path_commands(path_many.d)

      assert many_points > few_points
    end

    test "octaves option adds detail to perturbation" do
      line = Line.new(x1: 0, y1: 0, x2: 100, y2: 0)

      path1 = Svg.Perturb.perturb(line, octaves: 1, seed: 42)
      path4 = Svg.Perturb.perturb(line, octaves: 4, seed: 42)

      # Different octave counts should produce different results
      refute path1.d == path4.d
    end

    # Helper to extract Y values from path data
    defp extract_y_values(path_d) do
      # Match patterns like "M 0 5.5" or "L 10 -3.2"
      Regex.scan(~r/[ML]\s+[\d.-]+\s+([\d.-]+)/, path_d)
      |> Enum.map(fn [_, y] -> String.to_float(y) end)
    end

    # Helper to count path commands
    defp count_path_commands(path_d) do
      length(Regex.scan(~r/[ML]/, path_d))
    end
  end

  describe "Svg.perturb_last/2" do
    test "perturbs the last element on the canvas" do
      canvas =
        Svg.canvas(:a6)
        |> Svg.line(x1: 0, y1: 0, x2: 100, y2: 0, stroke: "black")
        |> Svg.perturb_last(amplitude: 5.0, seed: 42)

      assert length(canvas.elements) == 1
      [element] = canvas.elements
      assert element.__struct__ == Path
    end

    test "handles empty canvas gracefully" do
      canvas = Svg.canvas(:a6) |> Svg.perturb_last(amplitude: 5.0)
      assert canvas.elements == []
    end
  end
end
