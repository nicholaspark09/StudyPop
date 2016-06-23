//
//  Thumb.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/23/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Thumb: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var pretty: String?
    @NSManaged var parent: String?
    @NSManaged var type: NSNumber?
    @NSManaged var protection: NSNumber?
    @NSManaged var user: String?
    @NSManaged var created: NSDate?
    @NSManaged var blob: NSData?
    @NSManaged var hasPic: Photo?
    var photoImage: UIImage?
    
    struct Keys{
        static let Name = "name"
        static let Pretty = "pretty"
        static let Parent = "parent"
        static let TheType = "type"
        static let User = "user"
        static let Created = "created"
        static let Blob = "blob"
    }

    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Thumb", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        parent = dictionary[Keys.Parent] as? String
        pretty = dictionary[Keys.Pretty] as? String
        type = dictionary[Keys.TheType] as? NSNumber
        blob = dictionary[Keys.Blob] as? NSData
        if blob != nil{
            photoImage = UIImage(data: blob!)
        }
    }
}
