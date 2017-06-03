//
//  FlickrConvenience.swift
//  virtual-tourist
//
//  Created by Kosrat D. Ahmad on 6/4/17.
//  Copyright © 2017 Kosrat D. Ahmad. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // MARK: Get user information
    
    func getPhotos(_ bboxString: String, completionHandlerForUserInfo: @escaping (_ success: Bool, _ error: String?) -> Void){
        
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
        let _ = taskForGETMethod(parameters: methodParameters as [String : AnyObject]) { (results, error) in
            
            /* Send the desired value(s) to completion handler */
            if let error = error {
                completionHandlerForUserInfo(false, error.localizedDescription)
            } else {
                print(results)
            }
        }
    }
}
