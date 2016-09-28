//
//  TravelLocationVC.swift
//  Virtual Tourist
//
//  Created by Ranjith on 09/27/16.
//  Copyright © 2016 Ranjith. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
import ContactsUI

class TravelLocationVC: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    var fetchResultsController: NSFetchedResultsController!
    
    var pin: Pin?
    var pinArray: [Pin]?
    var locationCoordinate: CLLocationCoordinate2D?
    var editingState: Bool = false
    
    let flickrClient = FlickrClient()
    
    @IBOutlet weak var mapView: MKMapView!
    //@IBOutlet weak var doneEditingButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.mapType = .Standard
        attemptFetch()
        
       // doneEditingButton.hidden = true
    }
    

    @IBAction func dropPin(sender: AnyObject) {
        let theSender = sender as! UIGestureRecognizer
        
        if theSender.state == .Began {
            var location = ""
            var city = ""
            var country = ""
            
            //Reserve geocode location to get city and country for annotation title and add annotation to the map
            let geocoder = CLGeocoder()
            
            //Get location from sender as CGPoint
            let touchPoint = sender.locationInView(mapView)
            
            //Convert location to CLCoordinate2D
            let touchCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            locationCoordinate = touchCoordinate
            
            //Create CLLocation to use for reverseGeocodeLocation
            let touchCLLocation = CLLocation(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude)
            
            
            geocoder.reverseGeocodeLocation(touchCLLocation) { (placemarks, error) in
                guard (error == nil) else {
                    print("There was an error: \(error?.userInfo)")
                    dispatch_async(dispatch_get_main_queue(), {
                        createAlertError("No Location Found", message: "Sorry! We couldn't find your location")
                    })
                    return
                }
                
                var placeMark: CLPlacemark!
                placeMark = placemarks?[0]
                
                // Location name
                if let locationName = placeMark.addressDictionary!["Name"] as? NSString {
                    location = locationName as String
                }
                
                //City
                if let theCity = placeMark.addressDictionary!["City"] as? NSString {
                    city = theCity as String
                }
                
                //Country
                if let theCountry = placeMark.addressDictionary!["Country"] as? NSString {
                    country = theCountry as String
                }
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchCoordinate
                
                if location.isEmpty == false && city.isEmpty == true {
                    annotation.title = "\(location)"
                } else {
                    annotation.title = "\(city), \(country)"
                }
                
                self.mapView.addAnnotation(annotation)
                self.mapView.deselectAnnotation(annotation, animated: false)
                
                appDel.managedObjectContext.performBlock({ 
                    self.pin = Pin(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude, title: annotation.title!, context: appDel.managedObjectContext)
                    
                    do {
                        try appDel.managedObjectContext.save()
                    } catch {
                        abort()
                    }
                })
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinReuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(pinReuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: pinReuseID)
            pinView?.animatesDrop = true
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        attemptFetch()
        
        if view.annotation != nil {
            
            locationCoordinate = view.annotation?.coordinate
            
            if let pinArry = pinArray {
                for pin in pinArry {
                    if pin.latitude == locationCoordinate!.latitude && pin.longitude == locationCoordinate!.longitude {
                        if editingState == true {
                            
                            appDel.managedObjectContext.deleteObject(pin)
                            
                            appDel.saveContext()
                            
                            dispatch_async(dispatch_get_main_queue(), { 
                                mapView.removeAnnotation(view.annotation!)
                            })
                        } else {
                            mapView.deselectAnnotation(view.annotation, animated: false)
                            self.pin = pin
                            self.performSegueWithIdentifier("sendPinLocation", sender: self)
                        }
                    }
                }
            }
        } else {
            //print("Sorry we couldnt send the annoation location via segue")
        }
    }
    
    // MARK: - Fetch Results Controller
    
    //Execute fetchRequest and use results returned from setFetchRequest
    func attemptFetch() {
        setFetchRequest()
        
        do {
            try self.fetchResultsController.performFetch()
            
            let results = fetchResultsController.fetchedObjects as? [Pin]
            //Store Pin array
            self.pinArray = results
            
            if let result = results {
                for pin in result {
                    let annotation = MKPointAnnotation()
                    let coordinate = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
                    annotation.coordinate = coordinate
                    annotation.title = pin.locationTitle
                    mapView.addAnnotation(annotation)
                }
            }
            
        } catch {
            print("Error executing fetch request: \(error)")
            dispatch_async(dispatch_get_main_queue(), { 
                createAlertError("No Results", message: "Sorry! We couldn't find any results")
            })
        }
        
    }
    
    // Set up fetch request
    func setFetchRequest() {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: appDel.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        controller.delegate = self
        
        fetchResultsController = controller
    }
    
    @IBAction func editPin(sender: AnyObject) {
        editingState = true
       // doneEditingButton.hidden = false
    }
    
    
    @IBAction func doneEditing(sender: AnyObject) {
        editingState = false
       // doneEditingButton.hidden = true
    }
    
    //MARK: Send loaction information via "sendPinLocation" segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "sendPinLocation" {
            if let photoVC = segue.destinationViewController as? PhotoAlbumVC {
                photoVC.selectedPin = pin
                photoVC.location = locationCoordinate
            }
        }
    }
}

