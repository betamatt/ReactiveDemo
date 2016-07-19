//
//  LocationService.swift
//  ReactiveDemo
//
//  Created by Matt on 6/28/16.
//  Copyright © 2016 RogueComma. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveCocoa
import enum Result.NoError

enum LocationStatus {
  case NotDetermined
  case Authorized
  case Denied
  case Loading
  case Success(CLLocation)
}

class LocationService: NSObject, CLLocationManagerDelegate {
  
  let location = MutableProperty<LocationStatus>(.NotDetermined)
  
  private
  
  let locationManager = CLLocationManager()
  
  override init() {
    super.init()

    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    
    location.swap(mapLocationStatus(CLLocationManager.authorizationStatus()))
  }
  
  func start() {
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
  }
  
  func stop() {
    locationManager.stopUpdatingLocation()
  }
  
  // Listen for the first location event then stop
  func establishLocation() {
    location.signal
      .on(next: { l in
        print("HERE")
        switch l {
        case .Success, .Denied:
          self.stop()
        default:
          break
        }
      })
    start()
  }
  
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    location.swap(mapLocationStatus(status))
  }
  
  func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
    location.swap(.Success(newLocation))
  }
  
  private
  
  func mapLocationStatus(status: CLAuthorizationStatus) -> LocationStatus {
    switch status {
    case .Authorized, .AuthorizedAlways, .AuthorizedWhenInUse:
      return .Authorized
    case .Denied:
      return .Denied
    case .NotDetermined:
      return .NotDetermined
    case .Restricted:
      return .Denied
    }
  }
  
  
}