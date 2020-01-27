//
//  MasterViewController.swift
//  Notes
//
//  Created by otet_tud on 1/16/20.
//  Copyright © 2020 otet_tud. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var folderList = [Folder]()
    var allNotesList = [Note]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = editButtonItem

        // Initialize Core Data Accesses
        loadCoreData()
        
        // This is in an attempt to implement a split view
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        tableView.reloadData()
        // Save whatever we changes we did with the notes view
        saveCoreData(entityName: "NoteEntity")
    }

    @objc
    func insertNewObject(_ sender: Any) {
//        objects.insert(NSDate(), at: 0)
//        let indexPath = IndexPath(row: 0, section: 0)
//        tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "showDetail" {
//            if let indexPath = tableView.indexPathForSelectedRow {
//                let object = folderList[indexPath.row] 
//                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
//                controller.detailItem = object
//                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//                controller.navigationItem.leftItemsSupplementBackButton = true
//                detailViewController = controller
//            }
//        }
        
        if let noteListSegue = segue.destination as? NotesTableViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                noteListSegue.detailItem = folderList[indexPath.row]
            }
            noteListSegue.delegate = self
        }
        
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folderList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let object = folderList[indexPath.row]
        cell.imageView?.image = UIImage(named: "folder")
        cell.textLabel!.text = object.getFolderName()
        cell.detailTextLabel!.text = ""//String(object.getNotesList().count)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("DEBUG: removing folder \(folderList[indexPath.row].getFolderName()) from \(folderList.count)")
            deleteCoreData(format: folderList[indexPath.row].getFolderName())
            deleteNotesFromFolder(folderName : folderList[indexPath.row].getFolderName())
            folderList.remove(at: indexPath.row)
            print("DEBUG: removed and folder count is \(folderList.count)")
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = self.folderList[sourceIndexPath.row]
        folderList.remove(at: sourceIndexPath.row)
        folderList.insert(movedObject, at: destinationIndexPath.row)
    }

    @IBAction func addFolder(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "New Folder", message: "Enter a name for this folder.", preferredStyle: .alert)
        var nFolderName : UITextField?
        
        alertController.addTextField { (nFolderName) in
            nFolderName.placeholder = "Name"
        }
            
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        cancelAction.setValue(UIColor.orange, forKey: "titleTextColor")
        
        let addItemAction = UIAlertAction(title: "Add Item", style: .default) { (action) in
            let textField = alertController.textFields![0]
            print("DEBUG: Will be adding folder \(textField.text!)")
            if(self.isNameValid(fname: "\(textField.text!)")) {
                self.addNewFolder(fname: "\(textField.text!)")
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(addItemAction)
            
        self.present(alertController, animated: true, completion: nil)
    }
    
    func updateData() {
        if (folderList.count > 0) {
            self.saveCoreData(entityName: "FolderEntity")
        } else {
            print("Clearing the Data and loading something empty")
            self.clearCoreData(entityName: "FolderEntity")
            self.loadCoreData()
        }
        self.tableView.reloadData()
    }
    
    func addNewFolder(fname: String) {
//        let n1 = Note(title: "note1", info: "note1", date: "", latitude: 1.0, longitude: 2.0, address: "address", image: "image", folder: "1")
//         let n2 = Note(title: "note2", info: "note2", date: "", latitude: 1.0, longitude: 2.0, address: "address", image: "image", folder: "1")
//         let n3 = Note(title: "note3", info: "note3", date: "", latitude: 1.0, longitude: 2.0, address: "address", image: "image", folder: "1")
//         var notesTest = [n1,n2,n3]
         
        
        let nFolder : Folder = Folder(fname: fname, notesNum: 0, notesList: [Note]() )
        folderList.append(nFolder)
        self.updateData()
    }
    
    func isNameValid(fname: String) -> Bool {
        for index in folderList {
            if index.getFolderName() == fname {
                alert(msg: "Folder name already exists")
                return false
            }
        }
        return true
    }
    
    func alert(msg: String) {
        let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func loadCoreData() {
        print("DEBUG: Loading Initial Data Folders")
        folderList = [Folder]()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        //Load the folders
        var fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FolderEntity")
        do {
            let results = try managedContext.fetch(fetchRequest)
            if results is [NSManagedObject] {
                for result in results as! [NSManagedObject] {
                    let fname = result.value(forKey: "fname") as! String
                    let numNotes = result.value(forKey: "notesnum") as! Int
                    //let notes = result.value(forKey: "noteslist") as! [Note]
                    let notes = [Note]()
                   
                    
                    folderList.append(Folder(fname: fname, notesNum: numNotes, notesList: notes))
                }
            }
        } catch { print(error) }
        
        //Load all notes
        fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NoteEntity")
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
                    
                    allNotesList.append(Note(title: title, info: info, date: date, latitude: latitude, longitude: longitude, address: address, image: image, audio: audio, folder: folder))
                }
            }
        } catch { print(error) }
    }
    
    func saveCoreData(entityName: String) {
        print("DEBUG: Saving Modifications for \(entityName)")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        clearCoreData(entityName: entityName)
        switch entityName {
        case "FolderEntity":
            for folder in folderList {
                let folderEntity = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: managedContext)
                    
                folderEntity.setValue(folder.getFolderName(), forKey: "fname")
                folderEntity.setValue(folder.getNumNotes(), forKey: "notesnum")
                // This will crash
                //folderEntity.setValue(folder.getNotesList(), forKey: "noteslist")
                do {
                    try managedContext.save()
                } catch { print(error) }
            }
        case "NoteEntity":
            print("DEBUG: Saving allnotes list to core data with count \(allNotesList.count)")
            for note in allNotesList {
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
        default:
            // Nothing to do here
            break
        }
    }
    
    func clearCoreData(entityName : String) {
        print("DEBUG: Clearing data for \(entityName)")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        // Create a fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try managedContext.fetch(fetchRequest)
            for managedObjects in results {
                if let managedObjectData = managedObjects as? NSManagedObject {
                    managedContext.delete(managedObjectData)
                }
            }
        } catch{ print(error)  }
        print("DEBUG: Done Clearing Core Data")
    }
    
    func deleteCoreData(format: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FolderEntity")
        // Helps filter the query
        deleteRequest.predicate = NSPredicate(format: "fname=%@", format)
        deleteRequest.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(deleteRequest)
            if results.count > 0 {
                for idx in results as! [NSManagedObject] {
                    // Delete the user or entity
                    if let name = idx.value(forKey: "fname") as? String {
                        print("DEBUG: Deleting with name \(format)")
                        context.delete(idx)
                        do {
                            try context.save()
                        } catch { print(error) }
                        break
                    }
                }
            }
        } catch { print(error) }
    }
    
    func getFolderIndex (fname: String) -> Int {
        var idx : Int = 0
        for folder in folderList {
            if folder.getFolderName() == fname {
                return idx
            }
            idx += 1
        }
        return -1
    }
    
    func addNewNoteToFolder(note: Note, fname: String) {
        print("DEBUG: New note \(note.getTitle()) added to folder \(fname)")
        var idx : Int = 0
        for folder in folderList {
            if folder.getFolderName() == fname {
                print("DEBUG: \(note.getTitle()) added into \(fname)")
                folderList[idx].addNoteList(note: note)
                print("DEBUG: right after addition \(folder.getFolderName()) has \(folder.getNotesList().count)")
            }
            idx += 1
        }
        tableView.reloadData()
        addNoteToList(note: note)
    }
    
    func addNoteToList(note: Note) {
        allNotesList.append(note)
        print("DEBUG: Adding note to all list \(allNotesList.count)")
        saveCoreData(entityName: "NoteEntity")
        saveCoreData(entityName: "FolderEntity")
    }
    
    func deleteNoteFromFolder(note: Note, fname: String) {
        let idx : Int = getFolderIndex(fname: fname)
        if idx >= 0 {
            let notes =  folderList[idx].getNotesList()
            var nIdx : Int = 0
            for noteIdx in notes {
                if noteIdx.getTitle() == note.getTitle() && noteIdx.getInfo() == note.getInfo() && noteIdx.getAddress() == note.getAddress() {
                    folderList[idx].notesList.remove(at: nIdx)
                }
                nIdx += 1
            }
        }
        tableView.reloadData()
        deleteNoteFromList(note: note)
    }
    
    func deleteNoteFromList(note: Note) {
        var nIdx : Int = 0
        for noteIdx in allNotesList {
            if noteIdx.getTitle() == note.getTitle() {//&& noteIdx.getInfo() == note.getInfo() && noteIdx.getAddress() == note.getAddress() {
                allNotesList.remove(at: nIdx)
            }
            nIdx += 1
        }
        saveCoreData(entityName: "NoteEntity")
        saveCoreData(entityName: "FolderEntity")
    }
    
    func deleteNotesFromFolder(folderName : String) {
        //First we need to remove it from the notesList array
        var noteIdx : Int = allNotesList.count-1
        repeat {
            if allNotesList[noteIdx].getFolder() == folderName {
                allNotesList.remove(at: noteIdx)
            }
            noteIdx -= 1
        } while noteIdx >= 0
        
        //Then delete it from the core data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NoteEntity")
        // Helps filter the query
        deleteRequest.predicate = NSPredicate(format: "folder=%@", folderName)
        deleteRequest.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(deleteRequest)
            if results.count > 0 {
                for idx in results as! [NSManagedObject] {
                    // Delete the user or entity
                    if let fname = idx.value(forKey: "folder") as? String {
                        context.delete(idx)
                        do {
                            try context.save()
                        } catch { print(error) }
                    }
                }
            }
        } catch { print(error) }
    }
    
    func updateNotesData(oldNote: Note, newNote: Note) {
        //print("DEBUG: Updating Note Data from \(oldNote) to \(newNote)")
        var nIdx : Int = 0
        for noteIdx in allNotesList {
            if noteIdx.getTitle() == oldNote.getTitle() { //&& noteIdx.getInfo() == oldNote.getInfo() && noteIdx.getAddress() == oldNote.getAddress() {
                allNotesList.remove(at: nIdx)
                print("DEBUG: Found note to delete")
                allNotesList.insert(newNote, at: nIdx)
            }
            nIdx += 1
        }
        saveCoreData(entityName: "NoteEntity")
    }
    
}

