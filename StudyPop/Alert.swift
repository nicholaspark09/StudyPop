//
//  Alert.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/29/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData


class Alert: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var info: String?
    @NSManaged var controller: String?
    @NSManaged var action: String?
    @NSManaged var safekey: String?
    @NSManaged var user: String?
    @NSManaged var seen: NSNumber?
    @NSManaged var created: NSDate?
    @NSManaged var originaluser: String?
    @NSManaged var image: String?
    var createdString:String?
    
    struct Keys{
        static let Name = "name"
        static let Info = "info"
        static let Controller = "controller"
        static let Created = "created"
        static let Action = "action"
        static let SafeKey = "safekey"
        static let User = "user"
        static let Seen = "seen"
        static let OriginalUser = "originaluser"
        static let Image = "image"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Alert", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        info = dictionary[Keys.Info] as? String
        controller = dictionary[Keys.Controller] as? String
        seen = dictionary[Keys.Seen] as? NSNumber
        originaluser = dictionary[Keys.OriginalUser] as? String
        user = dictionary[Keys.User] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        createdString = dictionary[Keys.Created] as? String
        image = dictionary[Keys.Image] as? String
        if createdString != nil{
            if let startDate = StudyPopClient.sharedDateFormatter.dateFromString(createdString!.trunc(16)){
                created = startDate
            }
        }
    }

}
