//
//  Notes.swift
//  Notes
//
//  Created by otet_tud on 1/21/20.
//  Copyright © 2020 otet_tud. All rights reserved.
//

import Foundation
import MapKit
import CoreMotion

//The application should have the following features:
//• Data should be persistent
//• User should be able to search for specific note by title or by keyword that may be
//contained in a note
//• User should be allowed to take picture (or use a picture that was previously taken) and
//store it as part of a note
//• User location that is the information on where the note was taken should be captured as
//part of the note
//• User later should be able to see the location on a map for every note that was taken
//• User should be able to record audio and associate the audio file with the note
//• User should able as well to change the

class Note {
    private var title : String
    private var info : String
    private var date : String
    //var location : CLLocationCoordinate2D
    private var latitude : Double
    private var longitude : Double
    private var address : String
    private var image : String
    private var folder : Int
    
    internal init(title: String, info: String, date: String, latitude: Double, longitude: Double, address: String, image: String, folder: Int) {
        self.title = title
        self.info = info
        self.date = date
        //self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.image = image
        self.folder = folder
    }
    
    /* Note Clas Getters */
    
    func getTitle() -> String { return self.title }
    
    func getInfo() -> String { return self.info }
    
    func getDate() -> String { return self.date }
    
    func getLatitude() -> Double { return self.latitude }
    
    func getLongitude() -> Double { return self.longitude }
    
    func getAddress() -> String { return self.address }
    
    func getImage() -> String { return self.image }
    
    func geFolder() -> Int { return self.folder }
    
    /* Note Class Setters */
    
    func setTitle(title: String) { self.title = title }
    
    func setInfo(info: String) { self.info = info }
    
    func setDate(date: String) { self.date = date }
    
    func setLatitude(latitude: Double) { self.latitude = latitude }
    
    func setLongitude(longitude: Double) { self.longitude = longitude }
    
    func setImage(image: String) { self.image = image }
    
    func setFolder(folder: Int) { self.folder = folder }
}
