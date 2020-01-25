//
//  DetailViewController.swift
//  Notes
//
//  Created by otet_tud on 1/16/20.
//  Copyright © 2020 otet_tud. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation

class DetailViewController: UIViewController, CLLocationManagerDelegate, AVAudioRecorderDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    @IBOutlet weak var navigationbar: UINavigationItem!
    @IBOutlet weak var datefld: UITextField!
    @IBOutlet weak var mapfld: UITextField!
    @IBOutlet weak var notetitlefld: UITextField!
    @IBOutlet weak var notecontent: UITextView!
    
    var note : Note?
    var oldNote : Note?
    var temporaryNote : Note?
    
    weak var delegate: NotesTableViewController?
    var locationManager = CLLocationManager()
    var coordinates = CLLocation()
    var address : String?
    var mod : Bool?
    var mapViewMode : Bool?
    
    // For the audio

   // var recordButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var player = AVAudioPlayer()
    var playable : Bool?
    var filename : String?
    var audioSet : URL?
    @IBOutlet weak var recordInfo: UILabel!
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            mod = true
            navigationbar.title = note!.getTitle()
            datefld?.text = "🗓 : \(note!.getDate())"
            mapfld?.text = "🗺 : \(note!.getAddress())"
            notetitlefld?.text = note!.getTitle()
            notecontent?.text = note!.getInfo()
            
            let location = CLLocation(latitude: detail.getLatitude(), longitude: detail.getLongitude())
            coordinates = location
            
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
        mapViewMode = false
        playable = false
        filename = ""
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        oldNote = detailItem
        if oldNote != nil {
            var realOldNote = Note(title: oldNote!.getTitle(), date: oldNote!.getDate(), info: oldNote!.getAddress())
            temporaryNote = realOldNote
        }
        configureView()
        
        // Setup Audio recorder
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                }
            }
        } catch { print(error) }
        // Set Up Audio
        filename = (note?.getAudio().isEmpty)! ? ("\(detailItem!.getFolder())-\(detailItem!.getTitle())-recording.m4a") : note!.getAudio()
        
        
        if !(note!.getAudio().isEmpty) {
            recordInfo!.text = "This note contains recorded audio.  Replay or tap record button to record again"
            filename = note!.getAudio()
            audioSet = getDocumentsDirectory().appendingPathComponent(filename!)
            print("DEBUG: This is the audio's file stored \(filename!)")
            playable = true
        } else { recordInfo!.text = ""
            filename = "\(detailItem!.getFolder())-\(detailItem!.getTitle())-recording.m4a"
            audioSet = getDocumentsDirectory().appendingPathComponent(filename!)
        }
        print("DEBUG: This is the audio's file name \(filename!)")
            
        do {
            let audioFilename = audioSet!//getDocumentsDirectory().appendingPathComponent(filename!)
            player = try AVAudioPlayer(contentsOf: audioFilename)
        }
        catch { print(error) }
  
    }

    var detailItem: Note? {
        didSet {
            // Update the view.
            note = detailItem
            configureView()
        }
    }
    
    @IBAction func mapviewfldpressed(_ sender: Any) {
        print("DEBUG: this field is pressed")
        mapfld.endEditing(true)
        if mapfld.text != "🗺 : " { //then the address is filled
            mapViewMode = true
            //self.performSegue(withIdentifier: "viewmap", sender: self)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        mapViewMode = false
    }
    
    func getNewNote() -> Note {
        
        let tempNote = note!
        tempNote.setTitle(title: notetitlefld.text!)
        tempNote.setInfo(info: notecontent.text!)
        tempNote.setFolder(folder: (delegate?.detailItem?.getFolderName())!)
        
        return tempNote
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if mapViewMode == false {
            print("DEBUG: Modification status \(mod)")
            if !(notetitlefld.text?.isEmpty ?? true) {

                note?.setTitle(title: notetitlefld.text!)
                note?.setInfo(info: notecontent.text!)
                note?.setFolder(folder: (delegate?.detailItem?.getFolderName())!)
                
                if mod == true {
                    // We are editing existing note
                    print("DEBUG \(temporaryNote)")
                    delegate?.updateNote(oldNote : temporaryNote!, newNote: note!)
                     
                }
                
                if mod == false {
                    print("DEBUG: Setting a new note")
                    delegate?.addNewNote(note: note!) }
                delegate?.tableView.reloadData()
            }
        }
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
                if self.note?.getAddress().isEmpty ?? true {
                    self.coordinates = location
                    self.mapfld.text = "🗺 : \(thoroufare) \(subLocality) \(subAdministrativeArea) \(country)"
                    self.note?.setAddress(address: "\(thoroufare) \(subLocality) \(subAdministrativeArea) \(country)")
                    self.note?.setLatitude(latitude: latitude)
                    self.note?.setLongitude(longitude: longitude)
                }
            }
        }}
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mapDelegate = segue.destination as? MapViewController {
                   mapDelegate.delegate = self
               }
    }


    func startRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let audioFilename = audioSet!//getDocumentsDirectory().appendingPathComponent(filename!)
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
         
            audioRecorder.delegate = self
            audioRecorder.record()

            recordButton.setTitle("🔴", for: .normal)
            playable = false
        } catch {
            print("DEBUG: Error on setting the recorder")
            finishRecording(success: false)
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        recordButton.setTitle("🔘", for: .normal)
        playable = true
        if success {
            
            print("DEBUG: Recording successful")
            
        } else {
            print("DEBUG: Recording not successful")
        }
    }

    @objc func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            let audioFilename = audioSet! //getDocumentsDirectory().appendingPathComponent(filename!)
            if note!.getAudio().isEmpty {
                note?.setAudio(audio: "\(filename!)") }
            recordInfo!.text = "This note contains recorded audio.  Replay or tap record button to record again"
            finishRecording(success: true)
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    @IBAction func recorButtonPressed(_ sender: UIButton) {
        recordTapped()
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if playable == false {
            alertMessage(title: "Cannot play audio!", msg: "This note either does not contain audio or you are still on record")
        } else {
            let audioFilename = audioSet!//getDocumentsDirectory().appendingPathComponent(filename!)
            do { player = try AVAudioPlayer(contentsOf: audioFilename) }
            catch { print(error) }
            
            player.play() }
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        if playable == false {
            alertMessage(title: "Cannot stop audio!", msg: "This note either does not contain audio or you are still on record")
        } else { player.stop() }
    }
    
    @IBAction func deleteButton(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Warning!", message: "Tapping 🆓 will remove the recorded audio in this note", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Remove Audio", style: .destructive) { (action) in
            self.note?.setAudio(audio: "")
            self.recordInfo!.text = ""
            self.filename = "\(self.note!.getFolder())-\(self.note!.getTitle())-recording.m4a"
            self.audioSet = self.getDocumentsDirectory().appendingPathComponent(self.filename!)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func alertMessage(title: String, msg: String) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)

         let OkAction = UIAlertAction(title: "Got It!", style: .cancel, handler: nil)
         alertController.addAction(OkAction)
             
         self.present(alertController, animated: true, completion: nil)
    }
}

