//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Ranjith on 09/27/16.
//  Copyright © 2016 Ranjith. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var creationDate: NSDate?
    @NSManaged var latitude: NSNumber?
    @NSManaged var locationTitle: String?
    @NSManaged var longitude: NSNumber?
    @NSManaged var photos: NSSet?

}
