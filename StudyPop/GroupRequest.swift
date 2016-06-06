//
//  GroupRequest.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/3/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData


class GroupRequest: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var user: String?
    @NSManaged var seen: NSNumber?
    @NSManaged var accepted: NSNumber?
    @NSManaged var safekey: String?
    @NSManaged var groupkey: String?
    
    struct Keys{
        static let Name = "name"
        static let User = "user"
        static let Seen = "seen"
        static let Accepted = "accepted"
        static let SafeKey = "safekey"
        static let GroupKey = "groupkey"
    }

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("GroupRequest", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        seen = dictionary[Keys.Seen] as? NSNumber
        accepted = dictionary[Keys.Accepted] as? NSNumber
        groupkey = dictionary[Keys.GroupKey] as? String
    }
    
}
