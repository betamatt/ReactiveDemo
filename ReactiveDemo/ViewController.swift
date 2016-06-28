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

class ViewModel {
  var searchTerm = MutableProperty<String?>(nil)
  var searchResults = MutableProperty<AsyncData<[String], NSError>>(.NotLoaded)
  
  init() {
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
    
    searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.searchBar.delegate = self
    tableView.tableHeaderView = searchController.searchBar
    
    definesPresentationContext = true

    searchController.searchBar.sizeToFit()
    
    tableView.dataSource = self

    viewModel.searchTerm.signal
      .debounce(NSTimeInterval(0.3), onScheduler: QueueScheduler.mainQueueScheduler)
      .filter({ s in !(s?.isEmpty)! })
      .observeNext({ string in
        if let s = string {
          NSLog(s)
          let results = self.viewModel.searchResults
          results.swap(AsyncData.Loading)
          
          self.delegate.foursquareService.venues(35.702069, long: 139.775326, query: s) { result in
            switch result {
            case let .Success(data):
              let venues = data["response"]["venues"].arrayValue
              let names = venues.map { venue in venue["name"].stringValue }
              results.swap(AsyncData.Success(names))
            default:
              break
            }
          }
        }
      })
    
    viewModel.searchResults.signal.observeNext({ _ in self.tableView.reloadData() })
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func updateSearchResultsForSearchController(searchController: UISearchController) {
    viewModel.searchTerm.swap(searchController.searchBar.text)
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch (viewModel.searchResults.value) {
    case .Success(let data):
      return data.count
    default:
      return 0
    }
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
    
    switch (viewModel.searchResults.value) {
    case let .Success(value):
      cell.textLabel?.text = value[indexPath.row]
    default:
      false
    }
  
    return cell
  }
  
}
