//
//  MapViewController.swift
//  Notes Organizer
//
//  Created by otet_tud on 1/23/20.
//  Copyright © 2020 otet_tud. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    weak var delegate: DetailViewController?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Define Latitude and Longitude of a specific location ex. Toronto
        let coordinates = delegate?.coordinates
        let latidude : CLLocationDegrees = (coordinates?.coordinate.latitude)!
        let longitude: CLLocationDegrees = (coordinates?.coordinate.longitude)!
        
        // Define the Deltas of Latitude and Longitude
        let latDelta : CLLocationDegrees = 0.05
        let longDelta : CLLocationDegrees = 0.05
        
        // Define the Span
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        
        // Define the location
        let location = CLLocationCoordinate2D(latitude: latidude, longitude: longitude)
        
        // Define the region
        let region = MKCoordinateRegion(center: location, span: span)
        
        // Set MapView with the set region
        mapView.setRegion(region, animated: true)
        
        // PIN Location: Add annotation
        let annotation = MKPointAnnotation()
        annotation.title =  delegate?.address
        annotation.subtitle = "This is where you decided to create the note"
        annotation.coordinate = location
        mapView.addAnnotation(annotation)
    }
    


}
