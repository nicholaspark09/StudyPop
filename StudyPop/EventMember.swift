//
//  EventMember.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/11/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class EventMember: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var user: String?
    @NSManaged var role: NSNumber?
    @NSManaged var safekey: String?
    @NSManaged var thumbblob: NSData?
    @NSManaged var fromEvent: Event?
    var photoImage: UIImage?
    var checked = false
    
    struct Keys{
        static let Name = "name"
        static let User = "user"
        static let Role = "role"
        static let SafeKey = "safekey"
        static let Thumbblob = "thumblob"
        static let Event = "event"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("EventMember", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        role = dictionary[Keys.Role] as? NSNumber
        safekey = dictionary[Keys.SafeKey] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        thumbblob = dictionary[Keys.Thumbblob] as? NSData
        if thumbblob != nil{
            photoImage = UIImage(data: thumbblob!)
        }
        
    }
    

}
