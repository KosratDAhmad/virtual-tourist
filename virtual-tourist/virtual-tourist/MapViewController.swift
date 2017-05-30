//
//  ViewController.swift
//  virtual-tourist
//
//  Created by Kosrat D. Ahmad on 5/30/17.
//  Copyright © 2017 Kosrat D. Ahmad. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // Restore saved map region and zoom level from user defaults.
        if let latitude = UserDefaults.standard.string(forKey: "Latitude"), let longitude = UserDefaults.standard.string(forKey: "Longitude"),
            let latitudeDelta = UserDefaults.standard.string(forKey: "LatitudeDelta"), let longitudeDelta = UserDefaults.standard.string(forKey: "LongitudeDelta"){
            
            let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude)!, longitude: CLLocationDegrees(longitude)!)
            let span = MKCoordinateSpanMake(CLLocationDegrees(latitudeDelta)!, CLLocationDegrees(longitudeDelta)!)
            let region = MKCoordinateRegionMake(coordinate, span)
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    // MARK: Map Delegates
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // Save map region and zoom level in user defaults.
        UserDefaults.standard.set(mapView.region.center.latitude.description, forKey: "Latitude")
        UserDefaults.standard.set(mapView.region.center.longitude.description, forKey: "Longitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta.description, forKey: "LatitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta.description, forKey: "LongitudeDelta")
    }
}
