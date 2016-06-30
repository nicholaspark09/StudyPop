//
//  EventRequest.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/30/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData


class EventRequest: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var eventkey: String?
    @NSManaged var safekey: String?
    @NSManaged var accepted: NSNumber?
    @NSManaged var seen: NSNumber?
    @NSManaged var user: String?

    struct Keys{
        static let Name = "name"
        static let User = "user"
        static let Seen = "seen"
        static let Accepted = "accepted"
        static let SafeKey = "safekey"
        static let EventKey = "eventkey"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("EventRequest", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        seen = dictionary[Keys.Seen] as? NSNumber
        accepted = dictionary[Keys.Accepted] as? NSNumber
        eventkey = dictionary[Keys.EventKey] as? String
    }

}
