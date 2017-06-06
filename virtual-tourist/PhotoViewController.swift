//
//  PhotoViewController.swift
//  virtual-tourist
//
//  Created by Kosrat D. Ahmad on 6/2/17.
//  Copyright © 2017 Kosrat D. Ahmad. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var pin: Pin?
    var photos : [Photo?] = []
    
    let reuseIdentifier = "FlickrCell"
    let sectionInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
    let itemsPerRow: CGFloat = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Show selected pin on the map.
        addPins()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let dbphotos = pin?.photos, dbphotos.count > 0 {
            photos = [Photo?]()
            for p in dbphotos {
                photos.append(p as? Photo)
            }
        }
        else {
            getPhotos()
        }
    }
    
    /// Get new set of flikr photos.
    ///
    /// - Parameter sender: newCollectionButton
    @IBAction func getNewData(_ sender: Any) {
        getPhotos()
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
    
    /// Helper method to get photo urls from Flickr api.
    func getPhotos() {
        
        newCollectionButton.isEnabled = false
        // delete the current photos, if any
        if photos.count > 0 {
            for photo in photos {
                if let photo = photo {
                    DbController.getContext().delete(photo)
                }
            }
        }
        
        // reload the collection view to show that it's been emptied
        photos = [Photo?]()
        collectionView.reloadData()
        
        FlickrClient.sharedInstance().getPhotos(bboxString()) { results, error in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    self.showError(title: "Error", message: error!)
                    self.newCollectionButton.isEnabled = true
                }
                return
            }
            
            guard let fetchedPhotos = results else {
                DispatchQueue.main.async {
                    self.showError(title: "Error", message: "Could not get the photos!")
                    self.newCollectionButton.isEnabled = true
                }
                return
            }
            
            if fetchedPhotos.count <= 0 {
                DispatchQueue.main.async {
                    self.showError(title: "Error", message: "No photo found.")
                    self.newCollectionButton.isEnabled = true
                }
                return
            }
            
            DispatchQueue.main.async {
                self.photos = [Photo?]()
                for _ in 0..<results!.count {
                    self.photos.append(nil)
                }
                self.collectionView.reloadData()
            }
            
            for (index, item) in results!.enumerated() {
                FlickrClient.sharedInstance().download(url: item, indexInArray: index, { (image, indexInArray) in
                    guard let image = image else { return }
                    
                    // save the image in the database
                    if let imageData = UIImageJPEGRepresentation(image, 0.9) {
                        // Create a Photos object on the main thread that's gonna use it
                        DispatchQueue.main.async {
                            let dbphoto = Photo(context: DbController.getContext())
                            dbphoto.image = imageData as NSData
                            dbphoto.pin = self.pin
                            self.photos[indexInArray] = dbphoto
                            // Update teh collection view
                            let cell = self.collectionView.cellForItem(at: IndexPath(item: indexInArray, section: 0)) as? FlickrPhotoCell
                            cell?.image = dbphoto
                        }
                    }
                })
            }
            DispatchQueue.main.async {
                self.newCollectionButton.isEnabled = true
            }
            
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
    
    private func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: UICollectionViewDelegates

extension PhotoViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? FlickrPhotoCell
        
        if cell == nil {
            cell = FlickrPhotoCell()
        }
        
        cell?.image = photos[indexPath.item]
        
        return cell!
    }
}

extension PhotoViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // the photo has not been loaded, so move on
        guard let photo = photos[indexPath.item] else {
            return
        }
        
        DbController.getContext().delete(photo)
        photos.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension PhotoViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
