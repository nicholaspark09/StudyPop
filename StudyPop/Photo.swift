//
//  Photo.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/6/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var safekey: String?
    @NSManaged var controller: String?
    @NSManaged var pretty: String?
    @NSManaged var blob: NSData?
    @NSManaged var type: NSNumber?
    @NSManaged var fromGroupProfile: Group?
    @NSManaged var parentkey: String?
    var photoImage: UIImage?
    
    struct Keys{
        static let Name = "name"
        static let SafeKey = "safekey"
        static let Controller = "controller"
        static let Pretty = "pretty"
        static let Blob = "blob"
        static let TheType = "type"
        static let FromGroupProfile = "Group"
        static let ParentKey = "parentkey"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        controller = dictionary[Keys.Controller] as? String
        pretty = dictionary[Keys.Pretty] as? String
        type = dictionary[Keys.TheType] as? NSNumber
        parentkey = dictionary[Keys.ParentKey] as? String
        blob = dictionary[Keys.Blob] as? NSData
        if pretty != nil && blob == nil{
            blob = NSData(base64EncodedString: pretty!, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
        }
        if blob != nil{
            photoImage = UIImage(data: blob!)
        }
    }
}
