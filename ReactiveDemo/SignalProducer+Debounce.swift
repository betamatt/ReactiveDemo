//
//  SignalProducer+Debounce.swift
//  ReactiveDemo
//
//  Created by Matt on 7/1/16.
//  Copyright © 2016 RogueComma. All rights reserved.
//

import Foundation
import ReactiveCocoa

extension SignalProducer {
  
  /// Debounce values sent by the receiver, such that at least `interval`
  /// seconds pass after the receiver has last sent a value, then
  /// forwards the latest value on the given scheduler.
  ///
  /// If multiple values are received before the interval has elapsed, the
  /// latest value is the one that will be passed on.
  ///
  /// If `self` terminates while a value is being debounced, that value
  /// will be discarded and the returned producer will terminate immediately.
  @warn_unused_result(message="Did you forget to call `start` on the producer?")
  public func debounce(interval: NSTimeInterval, onScheduler scheduler: DateSchedulerType) -> SignalProducer<Value, Error> {
    return lift { $0.debounce(interval, onScheduler: scheduler) }
  }
  
}