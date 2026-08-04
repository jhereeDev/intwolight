import 'dart:math' as math;

/// A pseudo-random source whose sequence is **fixed forever**.
///
/// ⚠️ Why not `dart:math`'s `Random(seed)`: its algorithm is an implementation
/// detail, not part of the language contract, and it has changed across SDK
/// releases before. Levels baked into `levels.g.dart` and `dailies.g.dart` do
/// not care — they were generated once and shipped as data. **Endless rooms
/// are generated on the device**, so a future Flutter upgrade could silently
/// hand every player a different room 500 than the one they shared. That would
/// break sharing, comparison and any record anyone kept.
///
/// splitmix64: 64-bit state, one multiply-xor-shift round per draw, no warmup,
/// and it passes the usual smoke tests for a generator of this size. Small
/// enough to read in one sitting, which is the point — this must be auditable
/// forever.
///
/// Implements [math.Random] so it drops straight into the existing generator.
class StableRandom implements math.Random {
  StableRandom(int seed) : _s = _mix(seed);

  int _s;

  static int _mix(int x) {
    // Avalanche the seed so adjacent room numbers do not produce correlated
    // streams. Room 41 must not resemble room 42.
    x = (x ^ (x >>> 33)) * 0xff51afd7ed558ccd;
    x = (x ^ (x >>> 33)) * 0xc4ceb9fe1a85ec53;
    return x ^ (x >>> 33);
  }

  /// One splitmix64 step. Dart ints are 64-bit two's complement on the VM and
  /// wrap on overflow, which is exactly the arithmetic this needs.
  int _next() {
    _s += 0x9e3779b97f4a7c15;
    var z = _s;
    z = (z ^ (z >>> 30)) * 0xbf58476d1ce4e5b9;
    z = (z ^ (z >>> 27)) * 0x94d049bb133111eb;
    return z ^ (z >>> 31);
  }

  @override
  double nextDouble() {
    // Top 53 bits — the exact mantissa width of a double, so every
    // representable value in [0,1) is reachable and none is favoured.
    return (_next() >>> 11) / (1 << 53);
  }

  @override
  int nextInt(int max) {
    if (max <= 0) throw RangeError.range(max, 1, null, 'max');
    // Rejection-sample away the modulo bias rather than pretending it is
    // negligible: these draws pick geometry, and a lopsided axis choice would
    // show up as every sculpture leaning the same way.
    final limit = (1 << 32) - ((1 << 32) % max);
    while (true) {
      final v = _next() >>> 32;
      if (v < limit) return v % max;
    }
  }

  @override
  bool nextBool() => (_next() >>> 63) == 1;
}
