//
//  FoursquareService.swift
//  ReactiveDemo
//
//  Created by Matt on 6/26/16.
//  Copyright © 2016 RogueComma. All rights reserved.
//

import Foundation
import FoursquareAPIClient
import SwiftyJSON
import Result

class FoursquareService {
  
  var client: FoursquareAPIClient!
  
  init(clientId: String, clientSecret: String) {
    client = FoursquareAPIClient(clientId: clientId, clientSecret: clientSecret)
  }
  
  func venues(lat: Double, long: Double, query: String?, limit: Int = 10, completion: (Result<JSON, NSError>) -> ()) {
    var params = [
      "ll": "\(lat),\(long)",
      "limit": "\(limit)"
    ]
    if let q = query {
      params["query"] = q
    }
    
    client.requestWithPath("venues/search", parameter: params) { (data, error) in
      if let e = error {
        completion(.Failure(e))
      } else if let d = data {
        completion(.Success(JSON(data: d)))
      }
    }
  }
}