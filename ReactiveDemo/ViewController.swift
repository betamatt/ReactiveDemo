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

class ViewModel {
  var state = MutableProperty<ViewControllerState<NSError>>(.NotLoaded)
}

class ViewController: UIViewController, UISearchBarDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource {

  @IBOutlet weak var tableView: UITableView!

  var searchController: UISearchController!
  var viewModel = ViewModel()
  var delegate: AppDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.searchBar.delegate = self
    tableView.tableHeaderView = searchController.searchBar
    
    definesPresentationContext = true

    searchController.searchBar.sizeToFit()
    
    tableView.dataSource = self
    
    viewModel.state.signal
      .debounce(NSTimeInterval(0.3), onScheduler: QueueScheduler.mainQueueScheduler)
      .filter {
        switch $0 {
        case .Loading (let term): return !term.isEmpty
        default: return false
        }
      }
      .observeNext {
        switch $0 {
        case .Loading (let term):
          self.delegate.foursquareService.venues(35.702069, long: 139.775326, query: term) { result in
            switch result {
            case let .Success(data):
              let venues = data["response"]["venues"].arrayValue
              let names = venues.map { venue in venue["name"].stringValue }
              self.viewModel.state.swap(ViewControllerState.Success(searchTerm: term, results: names))
            case let .Failure(error):
              self.viewModel.state.swap(ViewControllerState.Failure(searchTerm: term, error))
            default:
              break
            }
          }
        default: break
        }
      }
    
    viewModel.state.signal.observeNext { _ in self.tableView.reloadData() }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func updateSearchResultsForSearchController(searchController: UISearchController) {
    if let text = searchController.searchBar.text {
      viewModel.state.swap(ViewControllerState.Loading(searchTerm: text))
    }
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch viewModel.state.value {
    case let .Success(_, data):
      return data.count
    default:
      return 0
    }
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    
    switch viewModel.state.value {
    case let .Success(_, results):
      cell.textLabel?.text = results[indexPath.row]
    default:
      false
    }
  
    return cell
  }
  
}
