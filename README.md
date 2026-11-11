# voxtween

A high-performance, fluent, allocation-conscious tweening and animation sequence framework for Dart.

Inspired by DOTween and TweenLite, built specifically for pure Dart game engines and interactive graphical applications.

## Features

- **30+ Standard Easing Equations**: Linear, Quad, Cubic, Quart, Quint, Sine, Expo, Circ, Back, Bounce, and Elastic (in, out, inOut).
- **Type-Agnostic Interpolation**: Tween any numeric scalar, 2D/3D vectors, colors, or custom data types with custom `Interpolator<T>`.
- **Fluent Builder API**: Chain `.ease()`, `.delay()`, `.loops()`, `.onStart()`, `.onUpdate()`, and `.onComplete()`.
- **Choreographed Sequences**: Combine tweens into sequential (`append`) and concurrent (`join`) timeline graphs with callback milestones and intervals.
- **Centralized Management**: Target-based bulk control (`killTarget`, `pauseTarget`, `resumeTarget`), fast frame updates, and zero garbage overhead in steady-state animation loops.
- **Zero External Dependencies**: Pure Dart 3, runs everywhere (Web, Desktop, Mobile, Server).

## Quick Start

```dart
import 'package:voxtween/voxtween.dart';

void main() {
  final manager = TweenManager();
  var x = 0.0;

  // Simple tween
  manager.to((val) => x = val, 100.0, 1.0, ease: Ease.outBounce)
    .delay(0.2)
    .onComplete(() => print('Reached 100!'));

  // Choreographed Sequence
  var scale = 1.0;
  var opacity = 0.0;
  manager.sequence()
    .append(manager.to((v) => opacity = v, 1.0, 0.5, ease: Ease.outQuad))
    .join(manager.to((v) => scale = v, 1.5, 0.5, ease: Ease.outBack))
    .appendInterval(0.25)
    .appendCallback(() => print('Sequence milestone'))
    .append(manager.to((v) => scale = v, 1.0, 0.3, ease: Ease.inQuad));

  // In your game loop:
  manager.update(0.016);
}
```

## License

MIT
