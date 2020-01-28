//
//  NotesTableViewController.swift
//  Notes Organizer
//
//  Created by otet_tud on 1/21/20.
//  Copyright © 2020 otet_tud. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class NotesTableViewController: UITableViewController, UISearchResultsUpdating, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    weak var delegate: MasterViewController?
    var detailViewController: DetailViewController? = nil
    var noteList = [Note]()
    var folderList = [Folder]()
    var currNote : Note?

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
        loadCoreData()
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
        
        folderList = delegate!.folderList 
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
                let object = resultSearchController.isActive ?  filteredTableData[indexPath.row] : noteList[indexPath.row]
                
                print("DEBUG: checking what detail we are passing to detail")
                print(noteList[indexPath.row])
                
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                currNote = object
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
        var peekStr = object.getInfo()
        var offsetIdx : Int = peekStr.count
        if peekStr.count > 48 { offsetIdx = 48 }
        let allowedIndx = peekStr.index(peekStr.startIndex, offsetBy: offsetIdx)
        peekStr = peekStr.count > 0 ? (peekStr[..<allowedIndx] + "...") : "empty"
        cell.detailTextLabel!.text = peekStr
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let note = self.resultSearchController.isActive ? filteredTableData[indexPath.row] : noteList[indexPath.row]
        if editingStyle == .delete {
            if self.resultSearchController.isActive {
                filteredTableData.remove(at:indexPath.row)
                var  nIdx : Int = 0
                for thisNote in noteList {
                    if thisNote.getTitle() == note.getTitle() {
                        noteList.remove(at: nIdx)
                    }
                    nIdx += 1
                }
            } else {
                noteList.remove(at: indexPath.row)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
            // Delete Core Data
            deleteCoreData(note: note)
            // Now update the folder where it belongs to
            delegate?.deleteNoteFromFolder(note : note, fname: (detailItem?.getFolderName())!)
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
    
    func getNoteIndex(note : Note) -> Int {
        var idx : Int = 0
        for noteIdx in noteList {
            if note.getTitle() == noteIdx.getTitle() && note.getDate() == noteIdx.getDate() && note.getAddress() == noteIdx.getAddress() {
                return idx
            }
            idx += 1
        }
        return -1
    }
    
    func addNewNote(note: Note) {
        // Append the note in this notelist
        noteList.append(note)
        // Add the note in the folder's notelist
        delegate?.addNewNoteToFolder(note: note, fname: (detailItem?.getFolderName())!)
        // Save the note changes to core data
        //saveCoreData()
        
    }
    
    func updateNote(oldNote: Note, newNote: Note) {
        //print("DEBUG: 2 Updating Note \(newNote.getInfo())")
        //delegate?.updateNotesData(oldNote: oldNote, newNote: newNote)
        delegate?.updateNotesData(oldNote: oldNote, newNote: newNote)
//        let idx : Int = getNoteIndex(note: oldNote)
//        noteList.remove(at: idx)
//        noteList.insert(newNote, at: idx)
//        
        
        //Update Core Data
       // saveCoreData()
    }
    
    func loadCoreData() {
        print("DEBUG: Loading Initial Data")
        noteList = [Note]()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NoteEntity")
        fetchRequest.predicate = NSPredicate(format: "folder=%@", (detailItem?.getFolderName())!)
        do {
            let results = try managedContext.fetch(fetchRequest)
            if results is [NSManagedObject] {
                for result in results as! [NSManagedObject] {
                    let title = result.value(forKey: "title") as! String
                    let info = result.value(forKey: "info") as! String
                    let date = result.value(forKey: "date") as! String
                    let latitude = result.value(forKey: "latitude") as! Double
                    let longitude = result.value(forKey: "longitude") as! Double
                    let address = result.value(forKey: "address") as! String
                    let image = result.value(forKey: "image") as! String
                    let audio = result.value(forKey: "audio") as! String
                    let folder = result.value(forKey: "folder") as! String
                    
                    noteList.append(Note(title: title, info: info, date: date, latitude: latitude, longitude: longitude, address: address, image: image, audio: audio, folder: folder))
                    
                }
            }
        } catch { print(error) }
        //self.delegate?.detailItem.setNumNotes(noteList.count)
    }
    
    func saveCoreData() {
        print("DEBUG: Saving Modifications")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        clearCoreData()
        for note in noteList {
            let noteEntity = NSEntityDescription.insertNewObject(forEntityName: "NoteEntity", into: managedContext)
                
            noteEntity.setValue(note.getTitle(), forKey: "title")
            noteEntity.setValue(note.getInfo(), forKey: "info")
            noteEntity.setValue(note.getDate(), forKey: "date")
            noteEntity.setValue(note.getLatitude(), forKey: "latitude")
            noteEntity.setValue(note.getLongitude(), forKey: "longitude")
            noteEntity.setValue(note.getAddress(), forKey: "address")
            noteEntity.setValue(note.getImage(), forKey: "image")
            noteEntity.setValue(note.getAudio(), forKey: "audio")
            noteEntity.setValue(note.getFolder(), forKey: "folder")
    
            do {
                try managedContext.save()
            } catch { print(error) }
        }
    }
    
    func clearCoreData() {
        print("DEBUG: Clearing Note Data")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        // Create a fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NoteEntity")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try managedContext.fetch(fetchRequest)
            for managedObjects in results {
                if let managedObjectData = managedObjects as? NSManagedObject {
                    managedContext.delete(managedObjectData)
                }
            }
        } catch{ print(error)  }
        print("DEBUG: Done Clearing Note Core Data")
    }
    
    func deleteCoreData(note: Note) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NoteEntity")
        // Helps filter the query
        deleteRequest.predicate = NSPredicate(format: "title=%@", note.getTitle())
        deleteRequest.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(deleteRequest)
            if results.count > 0 {
                for idx in results as! [NSManagedObject] {
                    // Delete the user or entity
                    if let name = idx.value(forKey: "title") as? String {
                        if note.getDate() == idx.value(forKey: "date") as? String {
                            if note.getInfo() == idx.value(forKey: "info") as? String {
                                print("DEBUG: Deleting note \(name)")
                                context.delete(idx)
                                do {
                                    try context.save()
                                } catch { print(error) }
                                break
                            }
                        }
                    }
                }
            }
        } catch { print(error) }
    }
}

