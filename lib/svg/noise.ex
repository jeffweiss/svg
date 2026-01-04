defmodule Svg.Noise do
  @moduledoc """
  Perlin and Simplex noise implementation for procedural generation.

  Based on the JavaScript implementation by Stefan Gustavson, optimized by
  Peter Eastman, and converted to Elixir. Original code is in the public domain.

  See: https://revdancatt.com/scripts/perlin.js?v=4.0.1

  ## Usage

      state = Svg.Noise.seed(42)
      value = Svg.Noise.perlin2(1.5, 2.3, state)
      # value is in range [-1, 1]

  """

  @typedoc """
  Noise state containing permutation and gradient tables.
  """
  @type t :: %__MODULE__{
          perm: tuple(),
          grad_p: tuple()
        }

  defstruct [:perm, :grad_p]

  # Gradient vectors for 3D noise (used for 2D as well)
  @grad3 [
    {1, 1, 0},
    {-1, 1, 0},
    {1, -1, 0},
    {-1, -1, 0},
    {1, 0, 1},
    {-1, 0, 1},
    {1, 0, -1},
    {-1, 0, -1},
    {0, 1, 1},
    {0, -1, 1},
    {0, 1, -1},
    {0, -1, -1}
  ]

  # Base permutation table
  @p [
    151,
    160,
    137,
    91,
    90,
    15,
    131,
    13,
    201,
    95,
    96,
    53,
    194,
    233,
    7,
    225,
    140,
    36,
    103,
    30,
    69,
    142,
    8,
    99,
    37,
    240,
    21,
    10,
    23,
    190,
    6,
    148,
    247,
    120,
    234,
    75,
    0,
    26,
    197,
    62,
    94,
    252,
    219,
    203,
    117,
    35,
    11,
    32,
    57,
    177,
    33,
    88,
    237,
    149,
    56,
    87,
    174,
    20,
    125,
    136,
    171,
    168,
    68,
    175,
    74,
    165,
    71,
    134,
    139,
    48,
    27,
    166,
    77,
    146,
    158,
    231,
    83,
    111,
    229,
    122,
    60,
    211,
    133,
    230,
    220,
    105,
    92,
    41,
    55,
    46,
    245,
    40,
    244,
    102,
    143,
    54,
    65,
    25,
    63,
    161,
    1,
    216,
    80,
    73,
    209,
    76,
    132,
    187,
    208,
    89,
    18,
    169,
    200,
    196,
    135,
    130,
    116,
    188,
    159,
    86,
    164,
    100,
    109,
    198,
    173,
    186,
    3,
    64,
    52,
    217,
    226,
    250,
    124,
    123,
    5,
    202,
    38,
    147,
    118,
    126,
    255,
    82,
    85,
    212,
    207,
    206,
    59,
    227,
    47,
    16,
    58,
    17,
    182,
    189,
    28,
    42,
    223,
    183,
    170,
    213,
    119,
    248,
    152,
    2,
    44,
    154,
    163,
    70,
    221,
    153,
    101,
    155,
    167,
    43,
    172,
    9,
    129,
    22,
    39,
    253,
    19,
    98,
    108,
    110,
    79,
    113,
    224,
    232,
    178,
    185,
    112,
    104,
    218,
    246,
    97,
    228,
    251,
    34,
    242,
    193,
    238,
    210,
    144,
    12,
    191,
    179,
    162,
    241,
    81,
    51,
    145,
    235,
    249,
    14,
    239,
    107,
    49,
    192,
    214,
    31,
    181,
    199,
    106,
    157,
    184,
    84,
    204,
    176,
    115,
    121,
    50,
    45,
    127,
    4,
    150,
    254,
    138,
    236,
    205,
    93,
    222,
    114,
    67,
    29,
    24,
    72,
    243,
    141,
    128,
    195,
    78,
    66,
    215,
    61,
    156,
    180
  ]

  # Skewing factors for simplex noise
  @f2 0.5 * (:math.sqrt(3) - 1)
  @g2 (3 - :math.sqrt(3)) / 6

  @doc """
  Initializes noise state with a seed value for reproducibility.

  The seed can be any number. Values between 0 and 1 are scaled up.
  The same seed always produces the same noise pattern.

  ## Examples

      iex> state = Svg.Noise.seed(42)
      iex> is_struct(state, Svg.Noise)
      true

      iex> state1 = Svg.Noise.seed(42)
      iex> state2 = Svg.Noise.seed(42)
      iex> Svg.Noise.perlin2(1.0, 1.0, state1) == Svg.Noise.perlin2(1.0, 1.0, state2)
      true

  """
  @spec seed(number()) :: t()
  def seed(seed) when is_number(seed) do
    # Scale small seeds
    seed = if seed > 0 and seed < 1, do: seed * 65_536, else: seed
    seed = floor(seed)

    # Ensure seed has bits in both bytes
    seed = if seed < 256, do: Bitwise.bor(seed, Bitwise.bsl(seed, 8)), else: seed

    grad3_tuple = List.to_tuple(@grad3)

    # Build permutation and gradient tables
    {perm_list, grad_p_list} =
      Enum.reduce(0..255, {[], []}, fn i, {perm_acc, grad_acc} ->
        v =
          if Bitwise.band(i, 1) == 1 do
            Bitwise.bxor(Enum.at(@p, i), Bitwise.band(seed, 255))
          else
            Bitwise.bxor(Enum.at(@p, i), Bitwise.band(Bitwise.bsr(seed, 8), 255))
          end

        grad = elem(grad3_tuple, rem(v, 12))

        {[v | perm_acc], [grad | grad_acc]}
      end)

    # Reverse and double the tables to avoid index wrapping
    perm_list = Enum.reverse(perm_list)
    grad_p_list = Enum.reverse(grad_p_list)

    perm = List.to_tuple(perm_list ++ perm_list)
    grad_p = List.to_tuple(grad_p_list ++ grad_p_list)

    %__MODULE__{perm: perm, grad_p: grad_p}
  end

  @doc """
  Calculates 2D Perlin noise value at the given coordinates.

  Returns a value in the range [-1, 1].

  ## Examples

      iex> state = Svg.Noise.seed(42)
      iex> value = Svg.Noise.perlin2(0.5, 0.5, state)
      iex> value >= -1 and value <= 1
      true

  """
  @spec perlin2(number(), number(), t()) :: float()
  def perlin2(x, y, %__MODULE__{perm: perm, grad_p: grad_p}) do
    # Find unit grid cell containing point
    xi = floor(x)
    yi = floor(y)

    # Get relative coordinates within cell
    x = x - xi
    y = y - yi

    # Wrap cell coordinates at 255
    xi = Bitwise.band(xi, 255)
    yi = Bitwise.band(yi, 255)

    # Calculate noise contributions from each corner
    n00 = dot2(elem(grad_p, xi + elem(perm, yi)), x, y)
    n01 = dot2(elem(grad_p, xi + elem(perm, yi + 1)), x, y - 1)
    n10 = dot2(elem(grad_p, xi + 1 + elem(perm, yi)), x - 1, y)
    n11 = dot2(elem(grad_p, xi + 1 + elem(perm, yi + 1)), x - 1, y - 1)

    # Compute fade curve
    u = fade(x)

    # Interpolate
    lerp(
      lerp(n00, n10, u),
      lerp(n01, n11, u),
      fade(y)
    )
  end

  @doc """
  Calculates 2D Simplex noise value at the given coordinates.

  Simplex noise is faster and has fewer directional artifacts than Perlin noise.
  Returns a value in the range [-1, 1].

  ## Examples

      iex> state = Svg.Noise.seed(42)
      iex> value = Svg.Noise.simplex2(0.5, 0.5, state)
      iex> value >= -1 and value <= 1
      true

  """
  @spec simplex2(number(), number(), t()) :: float()
  def simplex2(xin, yin, %__MODULE__{perm: perm, grad_p: grad_p}) do
    # Skew input space to determine simplex cell
    s = (xin + yin) * @f2
    i = floor(xin + s)
    j = floor(yin + s)

    t = (i + j) * @g2
    x0 = xin - i + t
    y0 = yin - j + t

    # Determine which simplex we're in
    {i1, j1} =
      if x0 > y0 do
        # Lower triangle
        {1, 0}
      else
        # Upper triangle
        {0, 1}
      end

    x1 = x0 - i1 + @g2
    y1 = y0 - j1 + @g2
    x2 = x0 - 1 + 2 * @g2
    y2 = y0 - 1 + 2 * @g2

    # Wrap coordinates
    i = Bitwise.band(i, 255)
    j = Bitwise.band(j, 255)

    # Get gradient indices
    gi0 = elem(grad_p, i + elem(perm, j))
    gi1 = elem(grad_p, i + i1 + elem(perm, j + j1))
    gi2 = elem(grad_p, i + 1 + elem(perm, j + 1))

    # Calculate contributions from three corners
    n0 = corner_contribution(x0, y0, gi0)
    n1 = corner_contribution(x1, y1, gi1)
    n2 = corner_contribution(x2, y2, gi2)

    # Scale to [-1, 1]
    70 * (n0 + n1 + n2)
  end

  @doc """
  Calculates fractal/octave noise by layering multiple noise samples.

  Higher octaves add finer detail. Persistence controls how much each
  octave contributes (lower = smoother, higher = more detailed).

  ## Options

    * `:octaves` - Number of noise layers (default: 4)
    * `:persistence` - Amplitude falloff per octave (default: 0.5)
    * `:lacunarity` - Frequency multiplier per octave (default: 2.0)

  ## Examples

      iex> state = Svg.Noise.seed(42)
      iex> value = Svg.Noise.fractal2(0.5, 0.5, state, octaves: 4)
      iex> is_float(value)
      true

  """
  @spec fractal2(number(), number(), t(), keyword()) :: float()
  def fractal2(x, y, state, opts \\ []) do
    octaves = Keyword.get(opts, :octaves, 4)
    persistence = Keyword.get(opts, :persistence, 0.5)
    lacunarity = Keyword.get(opts, :lacunarity, 2.0)

    {total, _amplitude, max_value, _freq} =
      Enum.reduce(1..octaves, {0.0, 1.0, 0.0, 1.0}, fn _, {total, amp, max_value, frequency} ->
        noise = perlin2(x * frequency, y * frequency, state)
        new_total = total + noise * amp
        new_max = max_value + amp
        new_amplitude = amp * persistence
        new_frequency = frequency * lacunarity

        {new_total, new_amplitude, new_max, new_frequency}
      end)

    total / max_value
  end

  # Private helper functions

  defp dot2({gx, gy, _gz}, x, y), do: gx * x + gy * y

  defp fade(t), do: t * t * t * (t * (t * 6 - 15) + 10)

  defp lerp(a, b, t), do: (1 - t) * a + t * b

  defp corner_contribution(x, y, grad) do
    t = 0.5 - x * x - y * y

    if t < 0 do
      0.0
    else
      t = t * t
      t * t * dot2(grad, x, y)
    end
  end
end
