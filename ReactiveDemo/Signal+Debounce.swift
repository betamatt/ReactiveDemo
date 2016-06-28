import ReactiveCocoa
import enum Result.NoError

extension Signal {
  /// Debounce values sent by the receiver, such that at least `interval`
  /// seconds pass after the receiver has last sent a value, then
  /// forwards the latest value on the given scheduler.
  ///
  /// If multiple values are received before the interval has elapsed, the
  /// latest value is the one that will be passed on.
  ///
  /// If the input signal terminates while a value is being debounced, that value
  /// will be discarded and the returned signal will terminate immediately.
  @warn_unused_result(message="Did you forget to call `observe` on the signal?")
  public func debounce(interval: NSTimeInterval, onScheduler scheduler: DateSchedulerType) -> Signal<Value, Error> {
    precondition(interval >= 0)

    return self
      .materialize()
      .flatMap(.Latest) { event -> SignalProducer<Event<Value, Error>, NoError> in
        if event.isTerminating {
          return SignalProducer(value: event).observeOn(scheduler)
        } else {
          return SignalProducer(value: event).delay(interval, onScheduler: scheduler)
        }
      }
      .dematerialize()
  }
}
