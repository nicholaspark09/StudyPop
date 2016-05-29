//
//  Subject.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/29/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData


class Subject: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var info: String?
    @NSManaged var user: String?
    
    struct Keys{
        static let Name = "name"
        static let Info = "info"
        static let User = "user"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Subject", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        info = dictionary[Keys.Info] as? String
    }

}
