//
//  FlickrConvenience.swift
//  virtual-tourist
//
//  Created by Kosrat D. Ahmad on 6/4/17.
//  Copyright © 2017 Kosrat D. Ahmad. All rights reserved.
//

import Foundation
import GameplayKit

extension FlickrClient {
    
    // MARK: Get user information
    
    func getPhotos(_ bboxString: String, completionHandler: @escaping (_ images: [String]?, _ error: String?) -> Void){
        
        /* Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let methodParameters = [
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
            FlickrParameterKeys.BoundingBox: bboxString,
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback
        ]
        
        /* Make the request */
        let _ = taskForGETMethod(parameters: methodParameters as [String : AnyObject]) { (parsedResults, error) in
            
            /* Send the desired value(s) to completion handler */
            if let error = error {
                completionHandler(nil, error.localizedDescription)
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResults?[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandler(nil, "Cannot find key '\(FlickrResponseKeys.Photos)' in \(parsedResults!)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                completionHandler(nil, "Cannot find key '\(FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            if photosArray.count == 0 {
                completionHandler(nil, "No Photos Found. Search Again.")
                return
            }
            
            var photoUrls = [String]()
            for photo in photosArray {
                
                if let imageUrl = photo[FlickrResponseKeys.MediumURL] as? String {
                    photoUrls.append(imageUrl)
                }
            }
            
            if photoUrls.count < Constants.MaxItemsPerCollection {
                completionHandler(photoUrls, nil)
                return
            }
            
            var shuffled = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: photoUrls) as! [String]
            completionHandler(Array(shuffled[0..<Constants.MaxItemsPerCollection]), nil)
        }
    }

    // MARK: Download flickr photo 
    
    func download(url: String, indexInArray: Int, _ completionHandler: @escaping (UIImage?, Int) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = URL(string: url) else {
                completionHandler(nil, indexInArray)
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                let image = UIImage(data: data)
                completionHandler(image, indexInArray)
            } catch {
                completionHandler(nil, indexInArray)
                return
            }
        }
    }
}
