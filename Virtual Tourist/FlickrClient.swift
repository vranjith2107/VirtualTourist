//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Ranjith on 09/27/16.
//  Copyright © 2016 Ranjith. All rights reserved.
//

import Foundation

class FlickrClient {
    
    init() {
        
    }
    
    func urlFromParameters(scheme: String, host: String, path: String, parameters: [String:AnyObject], withPathExtension: String? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path + (withPathExtension ?? "")
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
        
    }
    
    func taskForGetMethod(method: String, parameters: [String:AnyObject], completionHandlerForGet: (result: AnyObject?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        let request = NSMutableURLRequest(URL: urlFromParameters(FlickrURL.ApiScheme, host: FlickrURL.ApiHost, path: FlickrURL.ApiPath, parameters: parameters, withPathExtension: method))
        //print(request)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            guard (error == nil) else {
                completionHandlerForGet(result: nil, error: error)
                print("There was an error: \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                return
            }
            
            guard let data = data else {
                print("No data returned by request")
                return
            }
            
            let parsedResult: AnyObject!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                print("Could not parse the data as JSON: \(data)")
                return
            }
            
            completionHandlerForGet(result: parsedResult, error: nil)
        }
        task.resume()
        return task
    }
    
    //MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }

    
}
