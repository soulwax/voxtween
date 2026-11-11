import 'dart:math' as math;

/// Function signature for easing functions transforming normalized time `[0, 1]` to an eased ratio.
typedef EaseFunc = double Function(double t);

/// Standard easing curves for animation and tweening.
abstract final class Ease {
  static const double _pi = math.pi;
  static const double _halfPi = math.pi / 2.0;

  static double linear(double t) => t;

  // Quadratic
  static double inQuad(double t) => t * t;
  static double outQuad(double t) => t * (2.0 - t);
  static double inOutQuad(double t) =>
      t < 0.5 ? 2.0 * t * t : -1.0 + (4.0 - 2.0 * t) * t;

  // Cubic
  static double inCubic(double t) => t * t * t;
  static double outCubic(double t) {
    final f = t - 1.0;
    return f * f * f + 1.0;
  }
  static double inOutCubic(double t) =>
      t < 0.5 ? 4.0 * t * t * t : (t - 1.0) * (2.0 * t - 2.0) * (2.0 * t - 2.0) + 1.0;

  // Quartic
  static double inQuart(double t) => t * t * t * t;
  static double outQuart(double t) {
    final f = t - 1.0;
    return 1.0 - f * f * f * f;
  }
  static double inOutQuart(double t) {
    if (t < 0.5) return 8.0 * t * t * t * t;
    final f = t - 1.0;
    return 1.0 - 8.0 * f * f * f * f;
  }

  // Quintic
  static double inQuint(double t) => t * t * t * t * t;
  static double outQuint(double t) {
    final f = t - 1.0;
    return f * f * f * f * f + 1.0;
  }
  static double inOutQuint(double t) {
    if (t < 0.5) return 16.0 * t * t * t * t * t;
    final f = 2.0 * t - 2.0;
    return 0.5 * f * f * f * f * f + 1.0;
  }

  // Sine
  static double inSine(double t) => 1.0 - math.cos(t * _halfPi);
  static double outSine(double t) => math.sin(t * _halfPi);
  static double inOutSine(double t) => 0.5 * (1.0 - math.cos(_pi * t));

  // Exponential
  static double inExpo(double t) => t == 0.0 ? 0.0 : math.pow(2.0, 10.0 * (t - 1.0)).toDouble();
  static double outExpo(double t) => t == 1.0 ? 1.0 : 1.0 - math.pow(2.0, -10.0 * t).toDouble();
  static double inOutExpo(double t) {
    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;
    if (t < 0.5) {
      return 0.5 * math.pow(2.0, 20.0 * t - 10.0).toDouble();
    }
    return 0.5 * (2.0 - math.pow(2.0, -20.0 * t + 10.0).toDouble());
  }

  // Circular
  static double inCirc(double t) => 1.0 - math.sqrt(math.max(0.0, 1.0 - t * t));
  static double outCirc(double t) => math.sqrt(math.max(0.0, 1.0 - (t - 1.0) * (t - 1.0)));
  static double inOutCirc(double t) {
    if (t < 0.5) {
      return 0.5 * (1.0 - math.sqrt(math.max(0.0, 1.0 - 4.0 * t * t)));
    }
    return 0.5 * (math.sqrt(math.max(0.0, 1.0 - (2.0 * t - 2.0) * (2.0 * t - 2.0))) + 1.0);
  }

  // Back (overshoot)
  static const double _c1 = 1.70158;
  static const double _c2 = _c1 * 1.525;
  static const double _c3 = _c1 + 1.0;

  static double inBack(double t) => _c3 * t * t * t - _c1 * t * t;
  static double outBack(double t) {
    final f = t - 1.0;
    return 1.0 + _c3 * f * f * f + _c1 * f * f;
  }
  static double inOutBack(double t) {
    if (t < 0.5) {
      final f = 2.0 * t;
      return 0.5 * (f * f * ((_c2 + 1.0) * f - _c2));
    }
    final f = 2.0 * t - 2.0;
    return 0.5 * (f * f * ((_c2 + 1.0) * f + _c2) + 2.0);
  }

  // Bounce
  static double outBounce(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;

    if (t < 1.0 / d1) {
      return n1 * t * t;
    } else if (t < 2.0 / d1) {
      final f = t - 1.5 / d1;
      return n1 * f * f + 0.75;
    } else if (t < 2.5 / d1) {
      final f = t - 2.25 / d1;
      return n1 * f * f + 0.9375;
    } else {
      final f = t - 2.625 / d1;
      return n1 * f * f + 0.984375;
    }
  }

  static double inBounce(double t) => 1.0 - outBounce(1.0 - t);
  static double inOutBounce(double t) =>
      t < 0.5 ? 0.5 * (1.0 - outBounce(1.0 - 2.0 * t)) : 0.5 * (1.0 + outBounce(2.0 * t - 1.0));

  // Elastic
  static double inElastic(double t) {
    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;
    final f = t - 1.0;
    return -math.pow(2.0, 10.0 * f) * math.sin((f - 0.1) * (2.0 * _pi) / 0.4);
  }

  static double outElastic(double t) {
    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;
    return math.pow(2.0, -10.0 * t) * math.sin((t - 0.1) * (2.0 * _pi) / 0.4) + 1.0;
  }

  static double inOutElastic(double t) {
    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;
    final f = 2.0 * t - 1.0;
    if (f < 0.0) {
      return -0.5 * math.pow(2.0, 10.0 * f) * math.sin((f - 0.15) * (2.0 * _pi) / 0.3);
    }
    return 0.5 * math.pow(2.0, -10.0 * f) * math.sin((f - 0.15) * (2.0 * _pi) / 0.3) + 1.0;
  }
}
