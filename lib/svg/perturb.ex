defmodule Svg.Perturb do
  @moduledoc """
  Element perturbation using Perlin noise.

  Transforms geometric SVG elements into organic, hand-drawn looking paths
  by applying noise-based displacement to sampled points.

  ## Perturbation Strategies

  ### Cartesian (Open Paths)
  For lines and polylines, points are displaced perpendicular to the path direction.

  ### Polar (Closed Shapes)
  For circles, ellipses, and polygons, radial displacement is used to ensure
  seamless joins. Based on the technique from Coding Train's polar noise sketch.

  ## Examples

      line = Svg.Elements.Line.new(x1: 0, y1: 0, x2: 100, y2: 100, stroke: "black")
      perturbed = Svg.Perturb.perturb(line, amplitude: 5.0, frequency: 0.05, seed: 42)

  """

  alias Svg.Elements.{Circle, Ellipse, Line, Path, Polygon, Polyline, Rect}
  alias Svg.Noise

  @default_opts [
    amplitude: 10.0,
    frequency: 0.1,
    octaves: 1,
    persistence: 0.5,
    seed: 0,
    samples: 100,
    mode: :auto
  ]

  @doc """
  Perturbs an element using Perlin noise.

  Returns a new Path element with the perturbed shape.

  ## Options

    * `:amplitude` - Maximum displacement in pixels (default: 10.0)
    * `:frequency` - Noise frequency, higher = more variation (default: 0.1)
    * `:octaves` - Number of noise layers for detail (default: 1)
    * `:persistence` - Amplitude falloff per octave (default: 0.5)
    * `:seed` - Random seed for reproducibility (default: 0)
    * `:samples` - Number of sample points (default: 100)
    * `:mode` - Force `:cartesian` or `:polar`, or `:auto` (default: :auto)

  ## Examples

      iex> line = Svg.Elements.Line.new(x1: 0, y1: 0, x2: 100, y2: 0, stroke: "black")
      iex> path = Svg.Perturb.perturb(line, amplitude: 5.0, seed: 42)
      iex> path.d != ""
      true

  """
  @spec perturb(struct(), keyword()) :: Path.t()
  def perturb(element, opts \\ [])

  def perturb(%Line{} = line, opts) do
    opts = Keyword.merge(@default_opts, opts)
    state = Noise.seed(opts[:seed])

    points = sample_line(line, opts[:samples])
    perturbed = perturb_open_path(points, state, opts)

    build_path(perturbed, line.attrs)
  end

  def perturb(%Polyline{} = polyline, opts) do
    opts = Keyword.merge(@default_opts, opts)
    state = Noise.seed(opts[:seed])

    points = sample_polyline(polyline.points, opts[:samples])
    perturbed = perturb_open_path(points, state, opts)

    build_path(perturbed, polyline.attrs)
  end

  def perturb(%Polygon{} = polygon, opts) do
    opts = Keyword.merge(@default_opts, opts)
    mode = resolve_mode(opts[:mode], :closed)

    state = Noise.seed(opts[:seed])

    perturbed =
      case mode do
        :polar ->
          perturb_polygon_polar(polygon.points, state, opts)

        :cartesian ->
          points = sample_polygon(polygon.points, opts[:samples])
          perturb_closed_path(points, state, opts)
      end

    build_closed_path(perturbed, polygon.attrs)
  end

  def perturb(%Rect{} = rect, opts) do
    # Convert rect to polygon points
    points = [
      {rect.x, rect.y},
      {rect.x + rect.width, rect.y},
      {rect.x + rect.width, rect.y + rect.height},
      {rect.x, rect.y + rect.height}
    ]

    polygon = %Polygon{points: points, attrs: rect.attrs}
    perturb(polygon, opts)
  end

  def perturb(%Circle{} = circle, opts) do
    opts = Keyword.merge(@default_opts, opts)
    state = Noise.seed(opts[:seed])

    perturbed = perturb_circle_polar(circle, state, opts)

    build_closed_path(perturbed, circle.attrs)
  end

  def perturb(%Ellipse{} = ellipse, opts) do
    opts = Keyword.merge(@default_opts, opts)
    state = Noise.seed(opts[:seed])

    perturbed = perturb_ellipse_polar(ellipse, state, opts)

    build_closed_path(perturbed, ellipse.attrs)
  end

  def perturb(%Path{d: d, attrs: attrs}, opts) do
    opts = Keyword.merge(@default_opts, opts)
    state = Noise.seed(opts[:seed])

    # Parse path data to extract points (handles M, L, Z commands)
    points = parse_path_points(d)

    if length(points) < 2 do
      Path.new([{:d, d} | Map.to_list(attrs)])
    else
      # Determine if path is closed
      is_closed = String.contains?(d, "Z") or String.contains?(d, "z")

      perturbed =
        if is_closed do
          perturb_closed_path(points, state, opts)
        else
          perturb_open_path(points, state, opts)
        end

      if is_closed do
        build_closed_path(perturbed, attrs)
      else
        build_path(perturbed, attrs)
      end
    end
  end

  # Sampling functions

  defp sample_line(%Line{x1: x1, y1: y1, x2: x2, y2: y2}, samples) when samples >= 2 do
    Enum.map(0..(samples - 1), fn i ->
      t = i / (samples - 1)
      x = x1 + (x2 - x1) * t
      y = y1 + (y2 - y1) * t
      {x, y}
    end)
  end

  defp sample_line(%Line{x1: x1, y1: y1}, _samples) do
    [{x1, y1}]
  end

  # Parses simple path data (M, L, Z commands) into a list of points
  defp parse_path_points(path_d) do
    # Match M/L commands followed by coordinates
    Regex.scan(~r/[ML]\s*([-\d.]+)\s*[,\s]\s*([-\d.]+)/i, path_d)
    |> Enum.map(fn [_, x, y] ->
      {parse_number(x), parse_number(y)}
    end)
  end

  defp parse_number(str) do
    case Float.parse(str) do
      {num, _} -> num
      :error -> 0.0
    end
  end

  defp sample_polyline(points, _samples) when length(points) < 2, do: points

  defp sample_polyline(points, samples) do
    # Calculate total length
    segments = Enum.zip(points, tl(points))

    total_length =
      Enum.reduce(segments, 0, fn {{x1, y1}, {x2, y2}}, acc ->
        acc + :math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
      end)

    if total_length == 0 do
      points
    else
      # Sample evenly along the path
      sample_along_segments(segments, total_length, samples)
    end
  end

  defp sample_polygon(points, _samples) when length(points) < 3, do: points

  defp sample_polygon(points, samples) do
    # Close the polygon by adding first point at end
    closed_points = points ++ [hd(points)]
    sample_polyline(closed_points, samples)
  end

  defp sample_along_segments(segments, total_length, samples) do
    step = total_length / (samples - 1)

    {result, _, _} =
      Enum.reduce(0..(samples - 1), {[], 0, segments}, fn i, {acc, current_dist, segs} ->
        target_dist = i * step
        {point, new_dist, new_segs} = find_point_at_distance(segs, current_dist, target_dist)
        {[point | acc], new_dist, new_segs}
      end)

    Enum.reverse(result)
  end

  defp find_point_at_distance([{{x1, y1}, {x2, y2}} = seg | rest], current_dist, target_dist) do
    seg_length = :math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
    end_dist = current_dist + seg_length

    if target_dist <= end_dist or rest == [] do
      # Point is in this segment
      t = if seg_length > 0, do: (target_dist - current_dist) / seg_length, else: 0
      t = max(0, min(1, t))
      point = {x1 + (x2 - x1) * t, y1 + (y2 - y1) * t}
      {point, current_dist, [seg | rest]}
    else
      find_point_at_distance(rest, end_dist, target_dist)
    end
  end

  defp find_point_at_distance([], current_dist, _target_dist) do
    {{0, 0}, current_dist, []}
  end

  # Cartesian perturbation for open paths

  defp perturb_open_path(points, _state, _opts) when length(points) < 2, do: points

  defp perturb_open_path(points, state, opts) do
    amplitude = opts[:amplitude]
    frequency = opts[:frequency]
    octaves = opts[:octaves]
    persistence = opts[:persistence]

    # Convert to tuple for O(1) access
    points_tuple = List.to_tuple(points)
    len = tuple_size(points_tuple)

    # Compute normals and perturb in a single pass
    Enum.map(0..(len - 1), fn i ->
      {x, y} = elem(points_tuple, i)

      # Get perpendicular direction using O(1) tuple access
      {nx, ny} = get_normal_at_tuple(points_tuple, i, len)

      # Calculate noise
      noise =
        if octaves > 1 do
          Noise.fractal2(x * frequency, y * frequency, state,
            octaves: octaves,
            persistence: persistence
          )
        else
          Noise.perlin2(x * frequency, y * frequency, state)
        end

      # Displace perpendicular to path
      displacement = noise * amplitude
      {x + nx * displacement, y + ny * displacement}
    end)
  end

  defp perturb_closed_path(points, state, opts) do
    # Same as open path but ensures continuity
    perturb_open_path(points, state, opts)
  end

  defp get_normal_at_tuple(points_tuple, index, len) do
    {prev_x, prev_y} =
      if index == 0 do
        elem(points_tuple, 0)
      else
        elem(points_tuple, index - 1)
      end

    {next_x, next_y} =
      if index >= len - 1 do
        elem(points_tuple, len - 1)
      else
        elem(points_tuple, index + 1)
      end

    # Tangent direction
    dx = next_x - prev_x
    dy = next_y - prev_y

    # Normalize and rotate 90 degrees for normal
    len_t = :math.sqrt(dx * dx + dy * dy)

    if len_t > 0 do
      {-dy / len_t, dx / len_t}
    else
      {0, 1}
    end
  end

  # Polar perturbation for closed shapes

  defp perturb_circle_polar(%Circle{cx: cx, cy: cy, r: r}, state, opts) do
    samples = opts[:samples]
    amplitude = opts[:amplitude]
    frequency = opts[:frequency]
    octaves = opts[:octaves]
    persistence = opts[:persistence]

    # Use a separate noise offset to avoid artifacts
    noise_radius = frequency

    Enum.map(0..(samples - 1), fn i ->
      # Angle from 0 to 2π (don't include 2π to avoid duplicate point)
      theta = 2 * :math.pi() * i / samples

      # Sample noise using polar coordinates in noise space
      # This ensures seamless wrapping
      noise_x = :math.cos(theta) * noise_radius
      noise_y = :math.sin(theta) * noise_radius

      noise =
        if octaves > 1 do
          Noise.fractal2(noise_x, noise_y, state,
            octaves: octaves,
            persistence: persistence
          )
        else
          Noise.perlin2(noise_x, noise_y, state)
        end

      # Vary radius
      new_r = r + noise * amplitude

      # Convert back to cartesian
      x = cx + new_r * :math.cos(theta)
      y = cy + new_r * :math.sin(theta)

      {x, y}
    end)
  end

  defp perturb_ellipse_polar(%Ellipse{cx: cx, cy: cy, rx: rx, ry: ry}, state, opts) do
    samples = opts[:samples]
    amplitude = opts[:amplitude]
    frequency = opts[:frequency]
    octaves = opts[:octaves]
    persistence = opts[:persistence]

    noise_radius = frequency

    Enum.map(0..(samples - 1), fn i ->
      theta = 2 * :math.pi() * i / samples

      noise_x = :math.cos(theta) * noise_radius
      noise_y = :math.sin(theta) * noise_radius

      noise =
        if octaves > 1 do
          Noise.fractal2(noise_x, noise_y, state,
            octaves: octaves,
            persistence: persistence
          )
        else
          Noise.perlin2(noise_x, noise_y, state)
        end

      # Apply noise to both radii proportionally
      new_rx = rx + noise * amplitude
      new_ry = ry + noise * amplitude

      x = cx + new_rx * :math.cos(theta)
      y = cy + new_ry * :math.sin(theta)

      {x, y}
    end)
  end

  defp perturb_polygon_polar(points, _state, _opts) when length(points) < 3, do: points

  defp perturb_polygon_polar(points, state, opts) do
    samples = opts[:samples]
    amplitude = opts[:amplitude]
    frequency = opts[:frequency]
    octaves = opts[:octaves]
    persistence = opts[:persistence]

    # Calculate centroid
    {sum_x, sum_y} = Enum.reduce(points, {0, 0}, fn {x, y}, {sx, sy} -> {sx + x, sy + y} end)
    n = length(points)
    cx = sum_x / n
    cy = sum_y / n

    noise_radius = frequency

    # Sample around the polygon
    Enum.map(0..(samples - 1), fn i ->
      theta = 2 * :math.pi() * i / samples

      # Find base radius at this angle by interpolating polygon edges
      base_r = radius_at_angle(points, cx, cy, theta)

      noise_x = :math.cos(theta) * noise_radius
      noise_y = :math.sin(theta) * noise_radius

      noise =
        if octaves > 1 do
          Noise.fractal2(noise_x, noise_y, state,
            octaves: octaves,
            persistence: persistence
          )
        else
          Noise.perlin2(noise_x, noise_y, state)
        end

      new_r = base_r + noise * amplitude

      x = cx + new_r * :math.cos(theta)
      y = cy + new_r * :math.sin(theta)

      {x, y}
    end)
  end

  defp radius_at_angle(points, cx, cy, target_theta) do
    # Find which edge the ray at target_theta intersects
    closed_points = points ++ [hd(points)]
    edges = Enum.zip(closed_points, tl(closed_points))

    Enum.reduce_while(edges, 0.0, fn {{x1, y1}, {x2, y2}}, _acc ->
      # Check if ray from center at target_theta intersects this edge
      case ray_edge_intersection(cx, cy, target_theta, x1, y1, x2, y2) do
        {:ok, r} -> {:halt, r}
        :none -> {:cont, 0.0}
      end
    end)
  end

  defp ray_edge_intersection(cx, cy, theta, x1, y1, x2, y2) do
    # Ray direction
    dx = :math.cos(theta)
    dy = :math.sin(theta)

    # Edge direction
    ex = x2 - x1
    ey = y2 - y1

    # Solve for intersection
    denom = dx * ey - dy * ex

    if abs(denom) < 1.0e-10 do
      :none
    else
      t = ((x1 - cx) * ey - (y1 - cy) * ex) / denom
      u = ((x1 - cx) * dy - (y1 - cy) * dx) / denom

      if t > 0 and u >= 0 and u <= 1 do
        {:ok, t}
      else
        :none
      end
    end
  end

  # Path building

  defp build_path(points, attrs) when length(points) < 2 do
    Path.new(d: "", attrs: Map.to_list(attrs))
  end

  defp build_path(points, attrs) do
    [{x0, y0} | rest] = points

    commands = Enum.map_join(rest, " ", fn {x, y} -> "L #{format_num(x)} #{format_num(y)}" end)

    d = "M #{format_num(x0)} #{format_num(y0)} #{commands}"

    Path.new([{:d, d} | Map.to_list(attrs)])
  end

  defp build_closed_path(points, attrs) when length(points) < 3 do
    Path.new(d: "", attrs: Map.to_list(attrs))
  end

  defp build_closed_path(points, attrs) do
    [{x0, y0} | rest] = points

    commands = Enum.map_join(rest, " ", fn {x, y} -> "L #{format_num(x)} #{format_num(y)}" end)

    d = "M #{format_num(x0)} #{format_num(y0)} #{commands} Z"

    Path.new([{:d, d} | Map.to_list(attrs)])
  end

  defp format_num(n) when is_float(n), do: :erlang.float_to_binary(n, [:compact, decimals: 2])
  defp format_num(n) when is_integer(n), do: Integer.to_string(n)

  defp resolve_mode(:auto, :closed), do: :polar
  defp resolve_mode(mode, _), do: mode
end
