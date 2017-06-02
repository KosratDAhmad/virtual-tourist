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
        
        let pin = Pin()
        pin.latitude = 11.11111
        pin.longitude = 22.2222
        
        mapView.delegate = self
        
        // Restore saved map region and zoom level from user defaults.
        if let latitude = UserDefaults.standard.string(forKey: "Latitude"), let longitude = UserDefaults.standard.string(forKey: "Longitude"),
            let latitudeDelta = UserDefaults.standard.string(forKey: "LatitudeDelta"), let longitudeDelta = UserDefaults.standard.string(forKey: "LongitudeDelta"){
            
            let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude)!, longitude: CLLocationDegrees(longitude)!)
            let span = MKCoordinateSpanMake(CLLocationDegrees(latitudeDelta)!, CLLocationDegrees(longitudeDelta)!)
            let region = MKCoordinateRegionMake(coordinate, span)
            self.mapView.setRegion(region, animated: true)
        }
        
        // Create long press gesture recognizer
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.dropPin(gestureRecognizer:)))
        longPress.minimumPressDuration = 0.5

        mapView.addGestureRecognizer(longPress)
    }
    
    /// Drop a pin on the map when long press gesture detected
    ///
    /// - Parameter gestureRecognizer: Long press gesture
    func dropPin(gestureRecognizer:UIGestureRecognizer){

        let tapPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        
        if .began == gestureRecognizer.state {
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinate
            
            mapView.addAnnotation(annotation)
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
