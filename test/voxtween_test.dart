import 'package:test/test.dart';
import 'package:voxtween/voxtween.dart';

void main() {
  group('voxtween Easing', () {
    test('all easing functions return 0.0 at t=0 and 1.0 at t=1 (or within tolerance)', () {
      final funcs = [
        Ease.linear,
        Ease.inQuad, Ease.outQuad, Ease.inOutQuad,
        Ease.inCubic, Ease.outCubic, Ease.inOutCubic,
        Ease.inQuart, Ease.outQuart, Ease.inOutQuart,
        Ease.inQuint, Ease.outQuint, Ease.inOutQuint,
        Ease.inSine, Ease.outSine, Ease.inOutSine,
        Ease.inExpo, Ease.outExpo, Ease.inOutExpo,
        Ease.inCirc, Ease.outCirc, Ease.inOutCirc,
        Ease.inBack, Ease.outBack, Ease.inOutBack,
        Ease.inBounce, Ease.outBounce, Ease.inOutBounce,
        Ease.inElastic, Ease.outElastic, Ease.inOutElastic,
      ];

      for (final f in funcs) {
        expect(f(0.0).abs(), lessThan(1e-4));
        expect((f(1.0) - 1.0).abs(), lessThan(1e-4));
      }
    });
  });

  group('voxtween Tween<double>', () {
    test('linear double tween advances value and invokes callbacks', () {
      var val = 0.0;
      var started = false;
      var completed = false;

      final tween = Tween<double>(
        getter: () => val,
        setter: (v) => val = v,
        endValue: 10.0,
        duration: 1.0,
        interpolator: Interpolators.doubleLerp,
      )
        ..onStart(() => started = true)
        ..onComplete(() => completed = true);

      expect(tween.isCompleted, isFalse);
      expect(started, isFalse);

      tween.update(0.5);
      expect(started, isTrue);
      expect(val, closeTo(5.0, 1e-4));
      expect(tween.isCompleted, isFalse);
      expect(completed, isFalse);

      tween.update(0.5);
      expect(val, closeTo(10.0, 1e-4));
      expect(tween.isCompleted, isTrue);
      expect(completed, isTrue);
    });

    test('tween delay defers execution until delay expires', () {
      var val = 0.0;
      final tween = Tween<double>(
        getter: () => val,
        setter: (v) => val = v,
        endValue: 10.0,
        duration: 1.0,
        interpolator: Interpolators.doubleLerp,
      ).delay(0.5);

      tween.update(0.25);
      expect(val, 0.0);

      // Remaining 0.25 delay consumed, 0.25 advances tween
      tween.update(0.5);
      expect(val, closeTo(2.5, 1e-4));
    });

    test('tween ping-pong alternates back and forth', () {
      var val = 0.0;
      final tween = Tween<double>(
        getter: () => val,
        setter: (v) => val = v,
        endValue: 10.0,
        duration: 1.0,
        interpolator: Interpolators.doubleLerp,
      ).loops(2, pingPong: true);

      // Forward half
      tween.update(1.0);
      expect(val, closeTo(10.0, 1e-4));

      // Backward half
      tween.update(0.5);
      expect(val, closeTo(5.0, 1e-4));

      tween.update(0.5);
      expect(val, closeTo(0.0, 1e-4));
      expect(tween.isCompleted, isTrue);
    });
  });

  group('voxtween Sequence', () {
    test('sequence executes steps in order and joins parallel tweens', () {
      var x = 0.0;
      var y = 0.0;
      final events = <String>[];

      final seq = Sequence()
        ..append(Tween<double>(
          getter: () => x,
          setter: (v) => x = v,
          endValue: 10.0,
          duration: 1.0,
          interpolator: Interpolators.doubleLerp,
        ))
        ..appendCallback(() => events.add('first_done'))
        ..appendInterval(0.5)
        ..append(Tween<double>(
          getter: () => x,
          setter: (v) => x = v,
          endValue: 20.0,
          duration: 1.0,
          interpolator: Interpolators.doubleLerp,
        ))
        ..join(Tween<double>(
          getter: () => y,
          setter: (v) => y = v,
          endValue: 50.0,
          duration: 1.0,
          interpolator: Interpolators.doubleLerp,
        ))
        ..onComplete(() => events.add('all_done'));

      seq.update(1.0);
      expect(x, closeTo(10.0, 1e-4));
      expect(events, contains('first_done'));

      // Delay 0.5s
      seq.update(0.5);
      expect(x, closeTo(10.0, 1e-4));

      // Parallel tweens advance 1.0s
      seq.update(1.0);
      expect(x, closeTo(20.0, 1e-4));
      expect(y, closeTo(50.0, 1e-4));
      expect(seq.isCompleted, isTrue);
      expect(events, contains('all_done'));
    });
  });

  group('voxtween TweenManager', () {
    test('manages multiple tweens and target-based cancellation', () {
      final manager = TweenManager();
      final targetA = Object();
      final targetB = Object();

      var a = 0.0;
      var b = 0.0;

      manager.to((v) => a = v, 10.0, 1.0, target: targetA);
      manager.to((v) => b = v, 20.0, 1.0, target: targetB);

      expect(manager.activeCount, 2);

      manager.update(0.5);
      expect(a, closeTo(5.0, 1e-4));
      expect(b, closeTo(10.0, 1e-4));

      manager.killTarget(targetA);
      expect(manager.activeCount, 1);

      manager.update(0.5);
      expect(a, closeTo(5.0, 1e-4)); // Stopped
      expect(b, closeTo(20.0, 1e-4)); // Finished
      expect(manager.activeCount, 0);
    });

    test('custom type interpolation', () {
      final manager = TweenManager();
      var pos = [0.0, 0.0, 0.0];

      manager.custom<List<double>>(
        getter: () => pos,
        setter: (v) => pos = v,
        endValue: [10.0, 20.0, 30.0],
        duration: 1.0,
        interpolator: Interpolators.listDoubleLerp,
      );

      manager.update(0.5);
      expect(pos[0], closeTo(5.0, 1e-4));
      expect(pos[1], closeTo(10.0, 1e-4));
      expect(pos[2], closeTo(15.0, 1e-4));

      manager.update(0.5);
      expect(pos[0], closeTo(10.0, 1e-4));
      expect(pos[1], closeTo(20.0, 1e-4));
      expect(pos[2], closeTo(30.0, 1e-4));
    });
  });
}
