//
//  AsyncData.swift
//  ReactiveDemo
//
//  Created by Matt on 6/26/16.
//  Copyright © 2016 RogueComma. All rights reserved.
//

import ReactiveCocoa

enum AsyncData<Value> {
  case NotLoaded
  case Loading
  case Success(Value)
  case Failure
}