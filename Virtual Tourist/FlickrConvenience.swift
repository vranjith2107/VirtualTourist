//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Ranjith on 09/27/16.
//  Copyright © 2016 Ranjith. All rights reserved.
//

import UIKit
import CoreData
import MapKit

extension FlickrClient {
    func searchPhotoByLocation(latitude: Double, longitude: Double, completionHandlerForSearch: (result: AnyObject?, error: NSError?) -> Void) {
        let parameters: [String:AnyObject] = [
            FlickrClient.FlickrParameterKeys.Method : FlickrClient.FlickrParameterValues.PhotoSearchMethod,
            FlickrClient.FlickrParameterKeys.ApiKey: FlickrClient.FlickrParameterValues.APIKey,
            FlickrClient.FlickrParameterKeys.Latitude: latitude,
            FlickrClient.FlickrParameterKeys.Longitude : longitude,
            FlickrClient.FlickrParameterKeys.Format : FlickrClient.FlickrParameterValues.FormatResponse,
            FlickrClient.FlickrParameterKeys.NoJSONCallback : FlickrClient.FlickrParameterValues.DisableJSONCallback,
            FlickrClient.FlickrParameterKeys.PerPage : FlickrClient.FlickrParameterValues.PerPageNumber
        ]
        
        taskForGetMethod("", parameters: parameters) { (result, error) in
            guard (error == nil) else {
                completionHandlerForSearch(result: nil, error: error)
                print("\(error?.userInfo)")
                return
            }
            
            guard let result = result else {
                print("Sorry we didnt get a result from searchByPhoto")
                return
            }
            
            guard let photosArray = result["photos"] as? [String : AnyObject] else {
                completionHandlerForSearch(result: nil, error: error)
                print("We could not find the 'photos' key in \(result["photos"])")
                return
            }
            
            guard let totalPages = photosArray["pages"] as? Int else {
                print("We could not find the 'pages' key in \(photosArray["pages"])")
                return
            }
            
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            
            print(randomPage)
            
            FlickrClient.sharedInstance().searchPhotoByLocationWithPage(latitude, longitude: longitude, page: randomPage, completionHandlerForSearchWithPage: { (result, error) in
                guard (error == nil) else {
                    return
                }
                
                if let results = result {
                    let downloadLinks = results as! [String]
                    
                    completionHandlerForSearch(result: downloadLinks, error: nil)
                }
            })
        }
    }
    
    func searchPhotoByLocationWithPage(latitude: Double, longitude: Double, page: Int, completionHandlerForSearchWithPage: (result: AnyObject?, error: NSError?) -> Void) {
        let parameters: [String:AnyObject] = [
            FlickrClient.FlickrParameterKeys.Method : FlickrClient.FlickrParameterValues.PhotoSearchMethod,
            FlickrClient.FlickrParameterKeys.ApiKey: FlickrClient.FlickrParameterValues.APIKey,
            FlickrClient.FlickrParameterKeys.Latitude: latitude,
            FlickrClient.FlickrParameterKeys.Longitude : longitude,
            FlickrClient.FlickrParameterKeys.Format : FlickrClient.FlickrParameterValues.FormatResponse,
            FlickrClient.FlickrParameterKeys.NoJSONCallback : FlickrClient.FlickrParameterValues.DisableJSONCallback,
            FlickrClient.FlickrParameterKeys.PerPage : FlickrClient.FlickrParameterValues.PerPageNumber,
            FlickrClient.FlickrParameterKeys.Page : "\(page)"
        ]
        
        taskForGetMethod("", parameters: parameters) { (result, error) in
            guard (error == nil) else {
                completionHandlerForSearchWithPage(result: nil, error: error)
                print("\(error?.userInfo)")
                return
            }
            
            guard let result = result else {
                print("Sorry we didnt get a result from searchByPhoto")
                return
            }
            
            guard let photosArray = result["photos"] as? [String : AnyObject] else {
                completionHandlerForSearchWithPage(result: nil, error: error)
                print("We could not find the 'photos' key in \(result["photos"])")
                return
            }
            
            guard let photoArray = photosArray["photo"] as? [[String:AnyObject]] else {
                completionHandlerForSearchWithPage(result: nil, error: error)
                print("We could not find the 'photo' key in \(photosArray["photo"])")
                return
            }
            
            let photoDownloadLinks = self.createDownloadLinkFromResults(photoArray)
            
            completionHandlerForSearchWithPage(result: photoDownloadLinks, error: nil)
            
        }
    }
    
    func createDownloadLinkFromResults(result: [[String:AnyObject]]) -> [String] {
        
        var photoDownloadLinks: [String] = []
        for item in result {
            if let farmID = item[JSONResponseKeys.FarmID], let serverID = item[JSONResponseKeys.ServerID], let id = item[JSONResponseKeys.ID], let secret = item[JSONResponseKeys.Secret] {
                let downloadURL = "https://farm\(farmID).staticflickr.com/\(serverID)/\(id)_\(secret).jpg"
                //print(downloadURL)
                photoDownloadLinks.append(downloadURL)
            }
        }
        return photoDownloadLinks
    }
    
    func taskToDownloadPhotos(url: String, completionHandlerForDownloadPhotos: (data: NSData?, error: NSError?) -> Void) {
        
        let url = NSURL(string: url)
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) in
            guard (error == nil) else {
                return completionHandlerForDownloadPhotos(data: nil, error: error)
            }
            
            if let data = data {
                completionHandlerForDownloadPhotos(data: data, error: nil)
            }
            
        })
        task.resume()
        
    }
    
}