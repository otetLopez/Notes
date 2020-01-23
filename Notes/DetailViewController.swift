//
//  DetailViewController.swift
//  Notes
//
//  Created by otet_tud on 1/16/20.
//  Copyright © 2020 otet_tud. All rights reserved.
//

import UIKit
import MapKit

class DetailViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    @IBOutlet weak var navigationbar: UINavigationItem!
    @IBOutlet weak var datefld: UITextField!
    @IBOutlet weak var mapfld: UITextField!
    @IBOutlet weak var notetitlefld: UITextField!
    @IBOutlet weak var notecontent: UITextView!
    
    var note : Note?
    
    weak var delegate: NotesTableViewController?
    var locationManager = CLLocationManager()
    var address : String?
    var mod : Bool?
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            mod = true
            navigationbar.title = detail.getTitle()
            datefld.text = detail.getDate()
            mapfld.text = detail.getAddress()
            
            if let label = detailDescriptionLabel {
                label.text = detail.getTitle()
            }
        } else {
            mod = false
            note = Note()
            // Set date
            configureDate()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        datefld.isUserInteractionEnabled = false
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        configureView()
    
    }

    var detailItem: Note? {
        didSet {
            // Update the view.
            note = detailItem
            configureView()
        }
    }
    
    @IBAction func mapviewfldpressed(_ sender: Any) {
        mapfld.endEditing(true)
        self.performSegue(withIdentifier: "viewmap", sender: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("DEBUG: Modification status \(mod)")
        if !(notetitlefld.text?.isEmpty ?? true) && mod == false {
            print("DEBUG: Setting a new note")
            note?.setTitle(title: notetitlefld.text!)
            note?.setInfo(info: notecontent.text)
            note?.setFolder(folder: (delegate?.detailItem?.getFolderName())!)
            
            delegate?.noteList.append(note!)
            delegate?.tableView.reloadData()
        }
        
//        if !(textViewOutlet.text!.isEmpty) {
//            if mod == true {
//                self.delegateNotes?.editNote(note: self.textViewOutlet.text!, nidx: self.index)
//                self.delegateNotes?.noteIdx = -1
//                mod = false
//            } else {
//                self.delegateNotes?.addNote(note: textViewOutlet.text!)
//            }
//        }
    }
    
    func configureDate() {
        var date : Date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        date = Date(timeIntervalSince1970: NSDate().timeIntervalSince1970)
        let timestamp : String = formatter.string(from: date)
        datefld.text = "🗓 : \(timestamp)"
        note?.setDate(date: timestamp)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Retrive the user location
        let userLocation : CLLocation = locations[0]
        
        // Set location latitude and longitude
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude

     
        // Get address for touch coordinates.
        let location = CLLocation(latitude: latitude, longitude: longitude)
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
        if let error = error {
            print(error)
        }  else {
            if let placemark = placemarks?[0] {
                var thoroufare = ""
                if placemark.thoroughfare != nil {
                    thoroufare = placemark.thoroughfare!
                }
                        
                var subLocality = ""
                if placemark.subLocality != nil {
                    subLocality = placemark.subLocality!
                }
                        
                var subAdministrativeArea = ""
                if placemark.subAdministrativeArea != nil {
                    subAdministrativeArea = placemark.subAdministrativeArea!
                }
                
                var country = ""
                if placemark.country != nil {
                    country = placemark.country!
                }
                
                self.address = "\(thoroufare) \(subLocality) \(subAdministrativeArea) \(country)"
                print("DEBUG: \(self.address)")
                //if self.mapfld.text == "🗺 : " {
                if self.note?.getAddress().isEmpty ?? true {
                    self.mapfld.text = "🗺 : \(thoroufare) \(subLocality) \(subAdministrativeArea) \(country)"
                    self.note?.setAddress(address: "\(thoroufare) \(subLocality) \(subAdministrativeArea) \(country)")
                }
            }
                }}
    }
    
}

