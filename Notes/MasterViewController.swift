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
                let object = folderList[indexPath.row] 
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
        
        if let noteListSegue = segue.destination as? NotesTableViewController {
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
        cell.imageView?.image = UIImage(named: "folder-icon")
        cell.textLabel!.text = object.getFolderName()
        cell.detailTextLabel!.text = String(object.getNumNotes())
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
            self.saveCoreData()
        } else {
            print("Clearing the Data and loading something empty")
            self.clearCoreData()
            self.loadCoreData()
        }
        self.tableView.reloadData()
    }
    
    func addNewFolder(fname: String) {
        let n1 = Note(title: "note1", info: "note1", date: "", latitude: 1.0, longitude: 2.0, address: "address", image: "image", folder: "1")
         let n2 = Note(title: "note2", info: "note2", date: "", latitude: 1.0, longitude: 2.0, address: "address", image: "image", folder: "1")
         let n3 = Note(title: "note3", info: "note3", date: "", latitude: 1.0, longitude: 2.0, address: "address", image: "image", folder: "1")
         var notesTest = [n1,n2,n3]
         
        
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
    
    func getNotesList(folder: String) -> [Note] {
        return [Note]()
    }
    
    
    func loadCoreData() {
        print("DEBUG: Loading Initial Data")
        folderList = [Folder]()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FolderEntity")
        do {
            let results = try managedContext.fetch(fetchRequest)
            if results is [NSManagedObject] {
                for result in results as! [NSManagedObject] {
                    let fname = result.value(forKey: "fname") as! String
                    let numNotes = result.value(forKey: "notesnum") as! Int
                    let notes = result.value(forKey: "noteslist") as! [Note]
                    //let notes : [Note] = self.getNotesList(folder: fname)
                   
                    
                    folderList.append(Folder(fname: fname, notesNum: numNotes, notesList: notes))
                }
            }
        } catch { print(error) }
    }
    
    func saveCoreData() {
        print("DEBUG: Saving Modifications")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        clearCoreData()
        for folder in folderList {
            let folderEntity = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: managedContext)
                
            folderEntity.setValue(folder.getFolderName(), forKey: "fname")
            folderEntity.setValue(folder.getNumNotes(), forKey: "notesnum")
            folderEntity.setValue(folder.getNotesList(), forKey: "noteslist")
            do {
                try managedContext.save()
            } catch { print(error) }
        }
    }
    
    func clearCoreData() {
        print("DEBUG: Clearing data")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        // Create a fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FolderEntity")
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
    
}

