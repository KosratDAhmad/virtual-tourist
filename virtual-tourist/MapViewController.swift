//
//  ViewController.swift
//  virtual-tourist
//
//  Created by Kosrat D. Ahmad on 5/30/17.
//  Copyright © 2017 Kosrat D. Ahmad. All rights reserved.
//

import UIKit
import MapKit
import CoreData

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
        
        // Create long press gesture recognizer
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.dropPin(gestureRecognizer:)))
        longPress.minimumPressDuration = 0.5

        mapView.addGestureRecognizer(longPress)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Get pin data from core data.
        getData()
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
            
            // Insert pin into core data.
            let pin = Pin(context: DbController.getContext())
            pin.latitude = annotation.coordinate.latitude
            pin.longitude = annotation.coordinate.longitude
        }
    }
    
    /// Get pin data from core data.
    func getData() {
        
        do {
            let pins = try DbController.getContext().fetch(Pin.fetchRequest()) as! [Pin]
            addPins(pins)
        } catch {
            print("No pins found.")
        }
    }
    
    /// Add pin location annotations to the map
    ///
    /// - Parameter locations: List of Pin data object.
    private func addPins(_ pins: [Pin]) {
        
        // We will create an MKPointAnnotation for each dictionary in "pins". The
        // point annotations will be stored in this array, and then provided to the map view.
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            
            // This is a version of the Double type.
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Here we create the annotation and set its coordiate.
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        
        // When the array is complete, we add the annotations to the map.
        self.mapView.addAnnotations(annotations)
    }

    // MARK: Map Delegates
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // Save map region and zoom level in user defaults.
        UserDefaults.standard.set(mapView.region.center.latitude.description, forKey: "Latitude")
        UserDefaults.standard.set(mapView.region.center.longitude.description, forKey: "Longitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta.description, forKey: "LatitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta.description, forKey: "LongitudeDelta")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    
        let controller = storyboard?.instantiateViewController(withIdentifier: "PhotoView") as! PhotoViewController
        
        let cordinate = view.annotation?.coordinate
        
        do {
            let pred = NSPredicate(format: "latitude = %@ and longitude = %@", argumentArray: [cordinate!.latitude, cordinate!.longitude])
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
            fetchRequest.predicate = pred
            
            let pins = try DbController.getContext().fetch(fetchRequest) as! [Pin]
            controller.pin = pins[0]
            self.navigationController?.pushViewController(controller, animated: true)
            
        } catch {
            print("No pins found.")
        }
    }
}
