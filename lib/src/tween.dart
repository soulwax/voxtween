import 'easing.dart';
import 'interpolator.dart';

/// Base interface for any tween or composite sequence that can be advanced in time.
abstract class Tweenable {
  /// Whether this tween or sequence is finished or killed.
  bool get isCompleted;

  /// Whether this tween is currently paused.
  bool get isPaused;

  /// Optional target object associated with this tween (used for target-based cancellation).
  Object? get target;

  /// Advances the tweenable by [dt] seconds.
  /// Returns `true` if still active, or `false` if completed/dead.
  bool update(double dt);

  /// Pauses advancement.
  void pause();

  /// Resumes advancement.
  void resume();

  /// Immediately terminates and removes the tween without invoking completion callbacks.
  void kill();

  /// Immediately fast-forwards to completion and triggers callbacks.
  void complete({bool invokeCallback = true});
}

/// A tween interpolating a value of type [T] over time using an easing function.
class Tween<T> implements Tweenable {
  final T Function()? _getter;
  final void Function(T value) _setter;
  final T _endValue;
  final Interpolator<T> _interpolator;
  final double _duration;

  T? _startValue;
  double _delay = 0.0;
  EaseFunc _ease = Ease.linear;
  int _loopCount = 1; // 1 = run once, -1 = infinite
  bool _pingPong = false;

  Object? _target;
  void Function()? _onStart;
  void Function(T value)? _onUpdate;
  void Function()? _onComplete;
  void Function(int remainingLoops)? _onLoop;

  // Runtime state
  double _elapsed = 0.0;
  double _delayRemaining = 0.0;
  int _currentIteration = 0;
  bool _isForward = true;
  bool _isStarted = false;
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _isKilled = false;

  /// Creates a tween. If [startValue] is omitted, [getter] is called upon tween start.
  Tween({
    required void Function(T value) setter,
    required T endValue,
    required double duration,
    required Interpolator<T> interpolator,
    T Function()? getter,
    T? startValue,
    Object? target,
  })  : _setter = setter,
        _endValue = endValue,
        _duration = duration > 0.0 ? duration : 0.00001,
        _interpolator = interpolator,
        _getter = getter,
        _startValue = startValue,
        _target = target;

  @override
  Object? get target => _target;

  @override
  bool get isCompleted => _isCompleted || _isKilled;

  @override
  bool get isPaused => _isPaused;

  /// Total duration in seconds of a single iteration.
  double get duration => _duration;

  /// Delay in seconds before starting.
  double get delayTime => _delay;

  /// Elapsed time within the current iteration.
  double get elapsed => _elapsed;

  /// Configures the easing function.
  Tween<T> ease(EaseFunc easeFunc) {
    _ease = easeFunc;
    return this;
  }

  /// Sets delay in seconds before the tween begins.
  Tween<T> delay(double seconds) {
    _delay = seconds > 0.0 ? seconds : 0.0;
    _delayRemaining = _delay;
    return this;
  }

  /// Configures repetition count (-1 for infinite) and optional ping-pong (yoyo) behavior.
  Tween<T> loops(int count, {bool pingPong = false}) {
    _loopCount = count;
    _pingPong = pingPong;
    return this;
  }

  /// Attaches target object reference.
  Tween<T> setTarget(Object target) {
    _target = target;
    return this;
  }

  /// Callback fired when the tween starts (after initial delay).
  Tween<T> onStart(void Function() callback) {
    _onStart = callback;
    return this;
  }

  /// Callback fired on every tick with the current value.
  Tween<T> onUpdate(void Function(T value) callback) {
    _onUpdate = callback;
    return this;
  }

  /// Callback fired when all loops of the tween finish.
  Tween<T> onComplete(void Function() callback) {
    _onComplete = callback;
    return this;
  }

  /// Callback fired each time an iteration loop finishes.
  Tween<T> onLoop(void Function(int remainingLoops) callback) {
    _onLoop = callback;
    return this;
  }

  @override
  void pause() => _isPaused = true;

  @override
  void resume() => _isPaused = false;

  @override
  void kill() {
    _isKilled = true;
    _isCompleted = true;
  }

  @override
  void complete({bool invokeCallback = true}) {
    if (_isCompleted || _isKilled) return;

    _startValue ??= _getter?.call() ?? _endValue;
    final finalValue = _pingPong && !_isForward ? _startValue! : _endValue;
    _setter(finalValue);
    _onUpdate?.call(finalValue);

    _isCompleted = true;
    if (invokeCallback) {
      _onComplete?.call();
    }
  }

  /// Resets the tween to its start state so it can be re-run.
  void restart() {
    _elapsed = 0.0;
    _delayRemaining = _delay;
    _currentIteration = 0;
    _isForward = true;
    _isStarted = false;
    _isPaused = false;
    _isCompleted = false;
    _isKilled = false;
  }

  @override
  bool update(double dt) {
    if (_isCompleted || _isKilled || _isPaused) return !_isCompleted;

    // Handle initial delay
    if (_delayRemaining > 0.0) {
      _delayRemaining -= dt;
      if (_delayRemaining > 0.0) return true;
      dt = -_delayRemaining; // carry remainder over into tweening
      _delayRemaining = 0.0;
    }

    if (!_isStarted) {
      _isStarted = true;
      _startValue ??= _getter?.call() ?? _endValue;
      _onStart?.call();
    }

    _elapsed += dt;

    var ratio = (_elapsed / _duration).clamp(0.0, 1.0);
    if (!_isForward) {
      ratio = 1.0 - ratio;
    }

    final easedRatio = _ease(ratio);
    final val = _interpolator(_startValue!, _endValue, easedRatio);
    _setter(val);
    _onUpdate?.call(val);

    if (_elapsed >= _duration) {
      _currentIteration++;

      if (_loopCount != -1 && _currentIteration >= _loopCount) {
        complete(invokeCallback: true);
        return false;
      }

      // Loop or Ping-Pong
      final remaining = _loopCount == -1 ? -1 : (_loopCount - _currentIteration);
      _onLoop?.call(remaining);

      _elapsed = _elapsed - _duration;
      if (_pingPong) {
        _isForward = !_isForward;
      }
    }

    return true;
  }
}
