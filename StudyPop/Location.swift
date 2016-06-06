//
//  Location.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/1/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData


class Location: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var info: String?
    @NSManaged var controller: String?
    @NSManaged var parentkey: String?
    @NSManaged var safekey: String?
    @NSManaged var subject: String?
    @NSManaged var lat: NSNumber?
    @NSManaged var lng: NSNumber?
    @NSManaged var ispublic: NSNumber?
    @NSManaged var user: String?
    @NSManaged var dayof: String?
    
    struct Keys{
        static let Name = "name"
        static let Info = "info"
        static let Controller = "controller"
        static let ParentKey = "parentkey"
        static let SafeKey = "safekey"
        static let Subject = "subject"
        static let Lat = "lat"
        static let Lng = "lng"
        static let IsPublic = "ispublic"
        static let User = "user"
        static let DayOf = "dayof"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        info = dictionary[Keys.Info] as? String
        subject = dictionary[Keys.Subject] as? String
        controller = dictionary[Keys.Controller] as? String
        parentkey = dictionary[Keys.ParentKey] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        lat = dictionary[Keys.Lat] as? NSNumber
        lng = dictionary[Keys.Lng] as? NSNumber
        ispublic = dictionary[Keys.IsPublic] as? NSNumber
        dayof = dictionary[Keys.DayOf] as? String
    }

}
