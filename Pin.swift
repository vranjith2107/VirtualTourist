//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Ranjith on 09/27/16.
//  Copyright © 2016 Ranjith. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    convenience init(latitude: Double, longitude: Double, title: String, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitude
            self.locationTitle = title
            self.creationDate = NSDate()
        } else {
            fatalError("Unable to find Entity name")
        }
    }

}
