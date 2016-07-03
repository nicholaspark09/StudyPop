//
//  Attendance.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/3/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Attendance: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var event: String?
    @NSManaged var user: String?
    @NSManaged var safekey: String?
    @NSManaged var created: NSDate?
    @NSManaged var modified: NSDate?
    @NSManaged var blob: NSData?
    @NSManaged var fromEventMember: EventMember?
    var checked = false
    var photoImage:UIImage?
    
    struct Keys{
        static let Name = "name"
        static let Event = "event"
        static let User = "user"
        static let SafeKey = "safekey"
        static let Created = "created"
        static let Modified = "modified"
        static let Blob = "blob"
        static let EventMember = "eventmember"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Attendance", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        event = dictionary[Keys.Event] as? String
        blob = dictionary[Keys.Blob] as? NSData
        if blob != nil{
            photoImage = UIImage(data: blob!)
        }
        if let eventMemberDict = dictionary[Keys.EventMember] as? [String:AnyObject]{
            fromEventMember = EventMember.init(dictionary: eventMemberDict, context: context)
        }
    }

}
