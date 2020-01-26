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

class DetailViewController: UIViewController, CLLocationManagerDelegate, AVAudioRecorderDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    @IBOutlet weak var navigationbar: UINavigationItem!
    @IBOutlet weak var datefld: UITextField!
    @IBOutlet weak var mapfld: UITextField!
    @IBOutlet weak var notetitlefld: UITextField!
    @IBOutlet weak var notecontent: UITextView!
    @IBOutlet weak var donEditButton: UIBarButtonItem!
    
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
            
            //In case note contains images
            if !(note!.getImage().isEmpty) {
                print("DEBUG: Note contains image")
                getImages()
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
        donEditButton.title = ""
        notecontent.delegate = self
        
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
        if !(note!.getAudio().isEmpty) {
            recordInfo!.text = "This note contains recorded audio.  Replay or tap record button to record again"
            filename = note!.getAudio()
            audioSet = getDocumentsDirectory().appendingPathComponent(filename!)
            print("DEBUG: This is the audio's file stored \(filename!)")
            playable = true
        } else { recordInfo!.text = ""
            let tempStr = "\(note!.getFolder())-\(note!.getTitle())-recording.m4a"
            filename = tempStr.replacingOccurrences(of: " ", with: "_")
            audioSet = getDocumentsDirectory().appendingPathComponent(filename!)
        }
        print("DEBUG: This is the audio's file name \(filename!)")
            
        do {
            let audioFilename = audioSet!
            player = try AVAudioPlayer(contentsOf: audioFilename)
        }
        catch { print(error) }
        
        
        // Make sure keyboard hides after typing
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)
    }

    var detailItem: Note? {
        didSet {
            // Update the view.
            note = detailItem
            configureView()
        }
    }
    
    @objc func viewTapped() {
        notetitlefld.resignFirstResponder()
        notecontent.resignFirstResponder()
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
                //print("DEBUG: \(self.address)")
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

    @IBAction func doneTyping(_ sender: UIBarButtonItem) {
        donEditButton.title = ""
        notetitlefld.resignFirstResponder()
        notecontent.resignFirstResponder()
        var frame = self.notecontent.frame
        frame.size.height = 470//self.notecontent.contentSize.height
        self.notecontent.frame = frame
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
            self.filename = ""
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
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        donEditButton.title = "Done"
        var frame = self.notecontent.frame
        frame.size.height = 200//self.notecontent.contentSize.height
        self.notecontent.frame = frame
    }
    
    @IBAction func setImage(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Insert Image", message: "Choose image source", preferredStyle: .alert)
        let rollAction = UIAlertAction(title: "From Camera Roll", style: .default) { (action) in
            self.takePhoto(source: .savedPhotosAlbum)
        }
        
        let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { (action) in
            self.takePhoto(source: .camera)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cameraAction)
        alertController.addAction(rollAction)
        alertController.addAction(cancelAction)
             
        self.present(alertController, animated: true, completion: nil)
    }
    
    func takePhoto(source: UIImagePickerController.SourceType) {
        let vc = UIImagePickerController()
        vc.allowsEditing = true
        vc.delegate = self
        
        switch(source) {
        case .camera:
            if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                alertMessage(title: "Error", msg: "Device has no camera or App has no access to camera")
            } else {
                vc.sourceType = .camera
                self.present(vc, animated: true)
            }
        case .savedPhotosAlbum:
            vc.sourceType = .savedPhotosAlbum
            self.present(vc, animated: true)
        default:
            break
        }

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        
        setImage(image: image)

        // Then we save the image
        let imageName = generateImageName()
        let fileManager = FileManager.default
        let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
        //get the PNG data for this image
        let data = image.pngData()
        //store it in the document directory
        fileManager.createFile(atPath: imagePath as String, contents: data, attributes: nil)
        print("DEBUG: This is the imagePath \(imagePath)")
        saveImageToDocumentDirectory(image)
        
        //Then save it for CoreData to save
        let images = note!.getImage()
        print("DEBUG: This is the imagename \(images)\(imageName) to save")
        note?.setImage(image: "\(imageName)")
        //note?.setImage(image: "\(images)\(imageName)")
        
//        var exclusionPath:UIBezierPath = UIBezierPath(rect: CGRectMake(0, 0, image.frame.size.width, image.frame.size.height))
//
//        textView.textContainer.exclusionPaths  = [exclusionPath]
//        textView.addSubview(imageView)
    }
    
    func setImage(image : UIImage) {
        let imageView = UIImageView(image: image)

        //let origin : CGPoint = notecontent!.frame.origin
          
        // Get cursor position
        //https://stackoverflow.com/questions/34922331/getting-and-setting-cursor-position-of-uitextfield-and-uitextview-in-swift
          
//        let startPosition: UITextPosition = notecontent.beginningOfDocument
//        let endPosition: UITextPosition = notecontent.endOfDocument
//        let selectedRange: UITextRange? = notecontent.selectedTextRange
//
//        if let selectedRange = notecontent.selectedTextRange {
//            let cursorPosition = notecontent.offset(from: notecontent.beginningOfDocument, to: selectedRange.start)
//            print("\(cursorPosition)")
//        }
        //notecontent.frame.width.m
        imageView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        //imageView.frame = CGRect(x: 0, y: cursorPosition, width: 200, height: 200)
        print("DEBUG: Now saving image")
        notecontent?.addSubview(imageView)
    }
    
    func generateImageName() -> String {
        //Set the base image name
        var imageName : String = ""
        if (note?.getImage().isEmpty)! {
            imageName = ("0-\(note!.getFolder())-\(note!.getTitle())-image.png").replacingOccurrences(of: " ", with: "_")
        } else {
//            var strTemp : String = (note?.getImage())!
//            //Get the last image
//            let images = strTemp.components(separatedBy:",")
//            let lastImage = images[images.count-2]
//            //Get the idNo of the last image
//            let ids = lastImage.components(separatedBy:"-")
//            let id : Int = Int(ids[0])!
            let id : Int = 0
            imageName = ("\(id)-\(note!.getFolder())-\(note!.getTitle())-image.png").replacingOccurrences(of: " ", with: "_")
        }
        imageName = ("0-\(note!.getFolder())-\(note!.getTitle())-image.png").replacingOccurrences(of: " ", with: "_")
        print("DEBUG: Image file name \(imageName)")
        return imageName
    }
    
    func getImages() {
        let images = note!.getImage().components(separatedBy: ",")
        print("DEBUG: Note contains \(images.count - 1) images")
        for image in images {
            if image != "" {
                print("DEBUG: Getting image for \(image)")
                getImage(imageName: image)
            }
        }
        
    }
    
    func getImage(imageName: String){
       let fileManager = FileManager.default
       let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
        print("DEBUG: Getting image from \(imagePath)")
        
       if fileManager.fileExists(atPath: imagePath){
          //imageView.image = UIImage(contentsOfFile: imagePath)
        print("DEBUG: Image file exists in path \(imagePath)")
        setImage(image: UIImage(contentsOfFile: imagePath)!)
       }else{
          print("Panic! No Image!")
       }
    }
    
    func saveImageToDocumentDirectory(_ chosenImage: UIImage) -> String {
        let directoryPath =  NSHomeDirectory().appending("/Documents/")
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhhmmss"

        let filename = generateImageName()//"0-camera-camera-image.png"//dateFormatter.string(from: Date()).appending(".jpg")
        let filepath = directoryPath.appending(filename)
        print("DEBUG: This is the new image path \(filepath)")
        let url = NSURL.fileURL(withPath: filepath)
        do {
            try chosenImage.jpegData(compressionQuality: 1.0)?.write(to: url, options: .atomic)
            return String.init("/Documents/\(filename)")

        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
        }
    }
    
//    func saveImage(imageView: ImageView) {
//       //create an instance of the FileManager
//       let fileManager = FileManager.default
//       //get the image path
//       let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
//       //get the image we took with camera
//       let image = imageView.image!
//       //get the PNG data for this image
//       let data = UIImagePNGRepresentation(image)
//       //store it in the document directory    fileManager.createFile(atPath: imagePath as String, contents: data, attributes: nil)
//    }
    
    
}

