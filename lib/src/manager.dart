import 'easing.dart';
import 'interpolator.dart';
import 'sequence.dart';
import 'tween.dart';

/// Centralized manager that updates active tweens and sequences, providing fast cancellation and pooling.
class TweenManager {
  static final TweenManager instance = TweenManager();

  final List<Tweenable> _active = [];
  final List<Tweenable> _pendingAdd = [];

  /// Number of currently active tweens and sequences.
  int get activeCount =>
      _active.where((t) => !t.isCompleted).length +
      _pendingAdd.where((t) => !t.isCompleted).length;

  /// Starts a numeric double tween.
  Tween<double> to(
    void Function(double value) setter,
    double endValue,
    double duration, {
    double Function()? getter,
    double? startValue,
    Object? target,
    EaseFunc? ease,
  }) {
    final tween = Tween<double>(
      setter: setter,
      endValue: endValue,
      duration: duration,
      interpolator: Interpolators.doubleLerp,
      getter: getter,
      startValue: startValue ?? (getter == null ? 0.0 : null),
      target: target,
    );
    if (ease != null) tween.ease(ease);
    add(tween);
    return tween;
  }

  /// Starts a custom type tween with an interpolator.
  Tween<T> custom<T>({
    required void Function(T value) setter,
    required T endValue,
    required double duration,
    required Interpolator<T> interpolator,
    T Function()? getter,
    T? startValue,
    Object? target,
    EaseFunc? ease,
  }) {
    final tween = Tween<T>(
      setter: setter,
      endValue: endValue,
      duration: duration,
      interpolator: interpolator,
      getter: getter,
      startValue: startValue,
      target: target,
    );
    if (ease != null) tween.ease(ease);
    add(tween);
    return tween;
  }

  /// Creates and registers a new animation sequence.
  Sequence sequence({Object? target}) {
    final seq = Sequence(target: target);
    add(seq);
    return seq;
  }

  /// Registers any [Tweenable] with this manager.
  T add<T extends Tweenable>(T tweenable) {
    _pendingAdd.add(tweenable);
    return tweenable;
  }

  /// Advances all active tweens and sequences by [dt] seconds.
  void update(double dt) {
    if (_pendingAdd.isNotEmpty) {
      _active.addAll(_pendingAdd);
      _pendingAdd.clear();
    }

    if (_active.isEmpty) return;

    for (var i = _active.length - 1; i >= 0; i--) {
      final t = _active[i];
      if (t.isCompleted) {
        _active.removeAt(i);
        continue;
      }
      final stillActive = t.update(dt);
      if (!stillActive || t.isCompleted) {
        _active.removeAt(i);
      }
    }
  }

  /// Terminates all tweens and sequences bound to [target].
  void killTarget(Object target, {bool complete = false}) {
    for (var i = _active.length - 1; i >= 0; i--) {
      final t = _active[i];
      if (t.target == target) {
        if (complete) {
          t.complete(invokeCallback: true);
        } else {
          t.kill();
        }
        _active.removeAt(i);
      }
    }
    for (var i = _pendingAdd.length - 1; i >= 0; i--) {
      final t = _pendingAdd[i];
      if (t.target == target) {
        if (complete) {
          t.complete(invokeCallback: true);
        } else {
          t.kill();
        }
        _pendingAdd.removeAt(i);
      }
    }
  }

  /// Terminates all active and pending tweens.
  void killAll({bool complete = false}) {
    for (final t in _active) {
      if (complete) {
        t.complete(invokeCallback: true);
      } else {
        t.kill();
      }
    }
    for (final t in _pendingAdd) {
      if (complete) {
        t.complete(invokeCallback: true);
      } else {
        t.kill();
      }
    }
    _active.clear();
    _pendingAdd.clear();
  }

  /// Pauses all tweens bound to [target].
  void pauseTarget(Object target) {
    for (final t in _active) {
      if (t.target == target) t.pause();
    }
    for (final t in _pendingAdd) {
      if (t.target == target) t.pause();
    }
  }

  /// Resumes all tweens bound to [target].
  void resumeTarget(Object target) {
    for (final t in _active) {
      if (t.target == target) t.resume();
    }
    for (final t in _pendingAdd) {
      if (t.target == target) t.resume();
    }
  }
}
