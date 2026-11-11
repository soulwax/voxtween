import 'tween.dart';

sealed class _SeqStep {}

final class _TweenStep extends _SeqStep {
  final List<Tweenable> parallelTweens;
  _TweenStep(this.parallelTweens);
}

final class _IntervalStep extends _SeqStep {
  final double duration;
  double elapsed = 0.0;
  _IntervalStep(this.duration);
}

final class _CallbackStep extends _SeqStep {
  final void Function() callback;
  _CallbackStep(this.callback);
}

/// A sequence of tweens and callbacks executed sequentially or in parallel tracks.
class Sequence implements Tweenable {
  final List<_SeqStep> _steps = [];
  int _currentStepIndex = 0;
  int _loops = 1;
  int _currentIteration = 0;

  Object? _target;
  void Function()? _onComplete;
  void Function()? _onStart;

  bool _isStarted = false;
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _isKilled = false;

  Sequence({Object? target}) : _target = target;

  @override
  Object? get target => _target;

  @override
  bool get isCompleted => _isCompleted || _isKilled;

  @override
  bool get isPaused => _isPaused;

  /// Appends a tween to run sequentially after previous steps finish.
  Sequence append(Tweenable tween) {
    _steps.add(_TweenStep([tween]));
    return this;
  }

  /// Runs [tween] in parallel with the most recently appended step.
  Sequence join(Tweenable tween) {
    if (_steps.isEmpty || _steps.last is! _TweenStep) {
      return append(tween);
    }
    (_steps.last as _TweenStep).parallelTweens.add(tween);
    return this;
  }

  /// Appends a time delay before proceeding to the next step.
  Sequence appendInterval(double seconds) {
    _steps.add(_IntervalStep(seconds > 0.0 ? seconds : 0.0));
    return this;
  }

  /// Appends an action callback fired at this point in the sequence.
  Sequence appendCallback(void Function() callback) {
    _steps.add(_CallbackStep(callback));
    return this;
  }

  /// Sets repetition loops (-1 for infinite).
  Sequence loops(int count) {
    _loops = count;
    return this;
  }

  /// Callback when sequence starts.
  Sequence onStart(void Function() callback) {
    _onStart = callback;
    return this;
  }

  /// Callback when entire sequence completes.
  Sequence onComplete(void Function() callback) {
    _onComplete = callback;
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
    for (final step in _steps) {
      if (step is _TweenStep) {
        for (final t in step.parallelTweens) {
          t.kill();
        }
      }
    }
  }

  @override
  void complete({bool invokeCallback = true}) {
    if (_isCompleted || _isKilled) return;

    for (final step in _steps) {
      if (step is _TweenStep) {
        for (final t in step.parallelTweens) {
          t.complete(invokeCallback: false);
        }
      } else if (step is _CallbackStep) {
        step.callback();
      }
    }

    _isCompleted = true;
    if (invokeCallback) {
      _onComplete?.call();
    }
  }

  @override
  bool update(double dt) {
    if (_isCompleted || _isKilled || _isPaused) return !_isCompleted;

    if (!_isStarted) {
      _isStarted = true;
      _onStart?.call();
    }

    if (_steps.isEmpty) {
      complete(invokeCallback: true);
      return false;
    }

    while (_currentStepIndex < _steps.length && dt >= 0.0) {
      final step = _steps[_currentStepIndex];

      if (step is _CallbackStep) {
        step.callback();
        _currentStepIndex++;
        continue;
      }

      if (step is _IntervalStep) {
        step.elapsed += dt;
        if (step.elapsed >= step.duration) {
          dt = step.elapsed - step.duration;
          step.elapsed = 0.0;
          _currentStepIndex++;
          continue;
        } else {
          return true;
        }
      }

      if (step is _TweenStep) {
        var allDone = true;
        for (final t in step.parallelTweens) {
          if (!t.isCompleted) {
            final active = t.update(dt);
            if (active) allDone = false;
          }
        }

        if (allDone) {
          _currentStepIndex++;
          dt = 0.0;
          continue;
        } else {
          return true;
        }
      }
    }

    if (_currentStepIndex >= _steps.length) {
      _currentIteration++;
      if (_loops != -1 && _currentIteration >= _loops) {
        complete(invokeCallback: true);
        return false;
      }

      // Reset for next loop
      _currentStepIndex = 0;
      for (final s in _steps) {
        if (s is _IntervalStep) s.elapsed = 0.0;
        if (s is _TweenStep) {
          for (final t in s.parallelTweens) {
            if (t is Tween) t.restart();
          }
        }
      }
    }

    return true;
  }
}
