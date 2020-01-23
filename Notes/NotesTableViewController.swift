//
//  NotesTableViewController.swift
//  Notes Organizer
//
//  Created by otet_tud on 1/21/20.
//  Copyright © 2020 otet_tud. All rights reserved.
//

import Foundation
import UIKit

class NotesTableViewController: UITableViewController, UISearchResultsUpdating {
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    weak var delegate: MasterViewController?
    var detailViewController: DetailViewController? = nil
    var noteList = [Note]()

    // This is for the search bar
    //For the searchbar
    var resultSearchController : UISearchController!
    var filteredTableData = [Note]()
    
    var detailItem: Folder? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
       if let detail = detailItem {
        navigationBar.title = detail.getFolderName()
        noteList = detail.getNotesList()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = editButtonItem
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        //Set searchbar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.definesPresentationContext = true
            controller.searchBar.placeholder = "Search"
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.autocapitalizationType = .none
            return controller
        })()

                 navigationItem.searchController = resultSearchController
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }

    @objc
    func insertNewObject(_ sender: Any) {
//        objects.insert(NSDate(), at: 0)
//        let indexPath = IndexPath(row: 0, section: 0)
//        tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = noteList[indexPath.row]
                
                print("DEBUG: checking what detail we are passing to detail")
                print(noteList[indexPath.row])
                
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
        
        if let noteDelegate = (segue.destination as! UINavigationController).topViewController as! DetailViewController? {
                   noteDelegate.delegate = self
               }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (resultSearchController.isActive) ? filteredTableData.count : noteList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notes", for: indexPath)
        let object = resultSearchController.isActive ? filteredTableData[indexPath.row] : noteList[indexPath.row]
        cell.textLabel!.text = object.getTitle()
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            noteList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredTableData.removeAll(keepingCapacity: false)
        for idx in noteList  {
            if idx.getTitle().localizedCaseInsensitiveContains(searchController.searchBar.text!) || idx.getInfo().localizedCaseInsensitiveContains(searchController.searchBar.text!) || idx.getAddress().localizedCaseInsensitiveContains(searchController.searchBar.text!) {
                filteredTableData.append(idx)
            }
        }
        self.tableView.reloadData()
    }
    
    func addNewNote(note: Note) {
        // Append the note in this notelist
        noteList.append(note)
        // Add the note in the folder's notelist
        delegate?.addNewNoteToFolder(note: note, fname: (detailItem?.getFolderName())!)
        
        // Save the note changes
        
    }


}

