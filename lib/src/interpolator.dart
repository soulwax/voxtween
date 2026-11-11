/// Function that calculates interpolated value between [start] and [end] given ratio [t] in [0, 1].
typedef Interpolator<T> = T Function(T start, T end, double t);

/// Standard interpolators for common types.
abstract final class Interpolators {
  /// Linear interpolation for double scalars.
  static double doubleLerp(double a, double b, double t) => a + (b - a) * t;

  /// Rounded integer interpolation.
  static int intLerp(int a, int b, double t) => (a + (b - a) * t).round();

  /// Element-wise interpolation for List<double>.
  static List<double> listDoubleLerp(List<double> a, List<double> b, double t) {
    final count = a.length < b.length ? a.length : b.length;
    final out = List<double>.filled(count, 0.0);
    for (var i = 0; i < count; i++) {
      out[i] = a[i] + (b[i] - a[i]) * t;
    }
    return out;
  }
}
