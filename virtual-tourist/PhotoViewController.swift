//
//  PhotoViewController.swift
//  virtual-tourist
//
//  Created by Kosrat D. Ahmad on 6/2/17.
//  Copyright © 2017 Kosrat D. Ahmad. All rights reserved.
//

import UIKit
import MapKit

class PhotoViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var pin: Pin?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // Show selected pin on the map.
        addPins()
        
        getPhotos();
    }
    
    /// Add pin location annotation to the map
    private func addPins() {
        
        // We will create an MKPointAnnotation for each dictionary in "pins". The
        // point annotations will be stored in this array, and then provided to the map view.
        var annotations = [MKPointAnnotation]()
        
        // This is a version of the Double type.
        let lat = CLLocationDegrees(pin!.latitude)
        let long = CLLocationDegrees(pin!.longitude)
        
        // The lat and long are used to create a CLLocationCoordinates2D instance.
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        // Here we create the annotation and set its coordiate.
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        // Finally we place the annotation in an array of annotations.
        annotations.append(annotation)
        
        
        // When the array is complete, we add the annotations to the map.
        self.mapView.addAnnotations(annotations)
        
        // Zoom map to the location
        let latDelta = 0.4
        let lonDelta = 0.4
        let span = MKCoordinateSpanMake(latDelta, lonDelta)
        let region = MKCoordinateRegionMake(coordinate, span)
        self.mapView.setRegion(region, animated: true)
    }
    
    func getPhotos() {
        
        FlickrClient.sharedInstance().getPhotos(bboxString()) { isSuccess, error in
            
            print(isSuccess)
        }
    }
    
    private func bboxString() -> String {
        // ensure bbox is bounded by minimum and maximums
        if let latitude = pin?.latitude, let longitude = pin?.longitude {
            let minimumLon = max(longitude - FlickrClient.Flickr.SearchBBoxHalfWidth, FlickrClient.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - FlickrClient.Flickr.SearchBBoxHalfHeight, FlickrClient.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + FlickrClient.Flickr.SearchBBoxHalfWidth, FlickrClient.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + FlickrClient.Flickr.SearchBBoxHalfHeight, FlickrClient.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
}
