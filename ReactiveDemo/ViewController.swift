//
//  ViewController.swift
//  ReactiveDemo
//
//  Created by Matt on 6/23/16.
//  Copyright © 2016 RogueComma. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SwiftyJSON
import enum Result.NoError


class ViewModel {
  
  var foursquareService: FoursquareService!
  var locationService: LocationService!
  
  var searchTerm = MutableProperty<String>("")
  var searchResults = MutableProperty<[String]>([])

  
  init() {
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    locationService = delegate.locationService
    foursquareService = delegate.foursquareService
    
    let results = searchTerm.producer
      .debounce(NSTimeInterval(0.3), onScheduler: QueueScheduler.mainQueueScheduler)
      .filter({ s in !(s.isEmpty) })
      .flatMap(.Merge) { (term) -> SignalProducer<[String], NoError> in
        let q = self.locationService.location.producer
          .on(next: { s in print(s) })
          .map { loc in (term, loc) }
        return self.queryVenues(q)
      }
    
    searchResults <~ results
    
    results.start()
    locationService.establishLocation()
  }
  
  
  private func queryVenues(query: SignalProducer<(String, LocationStatus), NoError>) -> SignalProducer<[String], NoError> {
    return query.flatMap(.Latest) { (string, locationStatus) in
      return SignalProducer() { observer, disposable in
        // Run search
        switch locationStatus {
        case .Success(let location):
          self.foursquareService.venues(location.coordinate.latitude, long: location.coordinate.longitude, query: string) { result in
            switch result {
            case let .Success(data):
              let venues = data["response"]["venues"].arrayValue
              let names = venues.map { venue in venue["name"].stringValue }
              observer.sendNext(names)
            case .Failure:
              observer.sendNext([])
            }
          }
        default:
          observer.sendNext([])
        }
      }
    }
  }
  
}

class ViewController: UIViewController, UISearchBarDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource {

  @IBOutlet weak var tableView: UITableView!

  var searchController: UISearchController!
  var viewModel: ViewModel = ViewModel()
  var delegate: AppDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    viewModel.foursquareService = delegate.foursquareService
    viewModel.locationService = delegate.locationService
    
    searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.searchBar.delegate = self
    tableView.tableHeaderView = searchController.searchBar
    
    definesPresentationContext = true

    searchController.searchBar.sizeToFit()
    
    tableView.dataSource = self
    
    viewModel.searchResults.signal.observeNext({ _ in self.tableView.reloadData() })
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func updateSearchResultsForSearchController(searchController: UISearchController) {
    if let s = searchController.searchBar.text {
      viewModel.searchTerm.swap(s)
    }
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return viewModel.searchResults.value.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
    
      cell.textLabel?.text = viewModel.searchResults.value[indexPath.row]
    
  
    return cell
  }
  
}
