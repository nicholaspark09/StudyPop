//
//  GroupMember.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/4/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class GroupMember: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var info: String?
    @NSManaged var user: String?
    @NSManaged var role: NSNumber?
    @NSManaged var safekey: String?
    @NSManaged var fromGroup: Group?
    @NSManaged var photoblob: NSData?
    var photoImage: UIImage?
    var checked = false
    
    struct Keys{
        static let Name = "name"
        static let Info = "info"
        static let User = "user"
        static let Role = "role"
        static let SafeKey = "safekey"
        static let FromGroup = "FromGroup"
        static let PhotoBlob = "photoblob"
        static let PhotoImage = "photoimage"
    }
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("GroupMember", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        info = dictionary[Keys.Info] as? String
        role = dictionary[Keys.Role] as? NSNumber
        photoblob = dictionary[Keys.PhotoBlob] as? NSData
        if photoblob != nil{
            photoImage = UIImage(data: photoblob!)
        }
    }

}
