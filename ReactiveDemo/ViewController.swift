//
//  ViewController.swift
//  ReactiveDemo
//
//  Created by Matt on 6/23/16.
//  Copyright © 2016 RogueComma. All rights reserved.
//

import UIKit
import ReactiveCocoa
import enum Result.NoError

enum ViewControllerState<Error> {
  case NotLoaded
  case Loading(searchTerm: String)
  case Success(searchTerm: String, results: [String])
  case Failure(searchTerm: String, Error)
}

struct ViewModel {
  var state = ViewControllerState<NSError>.NotLoaded
}

protocol ViewControllerDelegate {
  func viewController(viewController: ViewController, didSuggest model: ViewModel)
}

class ViewController: UIViewController, UISearchBarDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource {

  @IBOutlet weak var tableView: UITableView!

  var searchController: UISearchController!
  var input = ViewModel() {
    didSet {
      tableView.reloadData()
    }
  }
  var output = VenuesFromQueryAndLocation() // Type should be `ViewControllerDelegate` and assignment made externally
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.searchBar.delegate = self
    tableView.tableHeaderView = searchController.searchBar
    definesPresentationContext = true
    searchController.searchBar.sizeToFit()
    tableView.dataSource = self
  }

  func updateSearchResultsForSearchController(searchController: UISearchController) {
    if let text = searchController.searchBar.text {
      output.viewController(self, didSuggest: ViewModel(state: .Loading(searchTerm: text)))
    }
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch input.state {
    case let .Success(_, data):
      return data.count
    default:
      return 0
    }
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    
    switch input.state {
    case let .Success(_, results):
      cell.textLabel?.text = results[indexPath.row]
    default:
      false
    }
  
    return cell
  }
  
}

class VenuesFromQueryAndLocation: ViewControllerDelegate {
  
  var foursquareService: FoursquareService! {
    let info = NSBundle.mainBundle().infoDictionary!
    return FoursquareService(
      clientId: info["FOURSQUARE_API_KEY"] as! String,
      clientSecret: info["FOURSQUARE_API_SECRET"] as! String
    )
  }
  
  func viewController(view: ViewController, didSuggest suggested: ViewModel) {
    switch suggested.state {
    case let .Loading(term) where term.characters.count > 0:
      view.input = ViewModel(state: .Loading(searchTerm: term))
      foursquareService.venues(35.702069, long: 139.775326, query: term) {
        switch $0 {
        case let .Success(data):
          let names = data["response"]["venues"].arrayValue.map { $0["name"].stringValue }
          view.input = ViewModel(state: .Success(searchTerm: term, results: names))
        case let .Failure(error):
          view.input = ViewModel(state: .Failure(searchTerm: term, error))
        default:
          break
        }
      }
    case let .Loading(term) where term.characters.count == 0:
      view.input = ViewModel(state: .NotLoaded)
    default:
      break
    }
  }
  
}
