//
//  Profile.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/6/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Profile: NSManagedObject {

    @NSManaged var city: String?
    @NSManaged var email: String?
    @NSManaged var firstName: String?
    @NSManaged var image: String?
    @NSManaged var info: String?
    @NSManaged var lastName: String?
    @NSManaged var name: String?
    @NSManaged var phone: String?
    @NSManaged var user: String?
    @NSManaged var subject: String?
    @NSManaged var fromUser: User?
    @NSManaged var thumbblob: NSData?
    @NSManaged var safekey: String?
    @NSManaged var hasPhoto: Photo?
    var photoImage: UIImage?
    
    struct Keys{
        static let Name = "name"
        static let Email = "email"
        static let Phone = "phone"
        static let City = "city"
        static let Subject = "subject"
        static let Info = "info"
        static let User = "user"
        static let Image = "image"
        static let Thumbblob = "thumbblob"
        static let PhotoImage = "photoimage"
        static let SafeKey = "safekey"
        static let HasPhoto = "hasphoto"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Profile", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        city = dictionary[Keys.City] as? String
        subject = dictionary[Keys.Subject] as? String
        email = dictionary[Keys.Email] as? String
        phone = dictionary[Keys.Phone] as? String
        image = dictionary[Keys.Image] as? String
        info = dictionary[Keys.Info] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        thumbblob = dictionary[Keys.Thumbblob] as? NSData
        if thumbblob != nil{
            photoImage = UIImage(data: thumbblob!)
        }
    }
}
