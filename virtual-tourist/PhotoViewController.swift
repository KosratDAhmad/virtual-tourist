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

class PhotoViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var pin: Pin?
    var totalImage: Int?
    var flikrImages = [UIImage]()
    
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
        
        // Create Fetch Request to get photos in core data
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let pred = NSPredicate(format: "pin = %@", argumentArray: [pin!])
        fr.predicate = pred
        
        do {
            let photos = try DbController.getContext().fetch(fr)
            
            print(photos.count)
            if photos.count > 0 {
                for p in photos {
                    flikrImages.append(UIImage(data: (p as! Photo).image! as Data)!)
                    print(UIImage(data: (p as! Photo).image! as Data)!)
                }
                totalImage = photos.count
                collectionView.reloadData()
            } else {
                getPhotos()
            }
        }catch {
            getPhotos()
        }
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
        
        FlickrClient.sharedInstance().getPhotos(bboxString()) { results, error in
            
            DispatchQueue.main.async {
                if let results = results {
                    self.totalImage = results.count
                    self.collectionView.reloadData()
                }
            }
            
            for (index, item) in (results?.enumerated())! {
                
                let url = URL(string: item)
                let data = try? Data(contentsOf: url!)
                
                DispatchQueue.main.async {
                    let photo = Photo(context: DbController.getContext())
                    photo.pin = self.pin
                    photo.image = (data! as NSData)
                    
                    self.flikrImages.append(UIImage(data: data!)!)
                    let cell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FlickrPhotoCell
                    cell?.backgroundColor = UIColor.white
                    cell?.indicator.stopAnimating()
                    cell?.imageView.image = UIImage(data: data!)
                }
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
    
    // MARK: UICollectionViewDelegates
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalImage ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrPhotoCell
        
        cell.backgroundColor = UIColor.black
        cell.indicator.startAnimating()
        cell.indicator.hidesWhenStopped = true
        
        print("second count \(flikrImages.count)")
        if flikrImages.count > indexPath.row {
            cell.backgroundColor = UIColor.white
            cell.indicator.stopAnimating()
            cell.imageView.image = flikrImages[indexPath.row]
        }
        return cell
    }
}

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
