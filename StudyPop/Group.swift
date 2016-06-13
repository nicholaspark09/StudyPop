//
//  Group.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/30/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Group: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var info: String?
    @NSManaged var maxpeople: NSNumber?
    @NSManaged var currentpeople: NSNumber?
    @NSManaged var user: String?
    @NSManaged var image: String?
    @NSManaged var ispublic: NSNumber?
    @NSManaged var safekey: String?
    @NSManaged var thumbblob: NSData?
    @NSManaged var city: City?
    @NSManaged var subject:Subject?
    @NSManaged var location: Location?
    @NSManaged var hasProfilePhoto: Photo?
    var checked: Bool?
    
    var photoImage: UIImage?
    
    struct Keys{
        static let Name = "name"
        static let Info = "info"
        static let Subject = "subject"
        static let MaxPeople = "maxpeople"
        static let CurrentPeople = "currentpeople"
        static let Location = "location"
        static let User = "user"
        static let Image = "image"
        static let City = "city"
        static let IsPublic = "ispublic"
        static let SafeKey = "safekey"
        static let ThumbBlob = "thumbblob"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Group", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        checked = false
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        info = dictionary[Keys.Info] as? String
        maxpeople = dictionary[Keys.MaxPeople] as? NSNumber
        currentpeople = dictionary[Keys.CurrentPeople] as? NSNumber
        image = dictionary[Keys.Image] as? String
        ispublic = dictionary[Keys.IsPublic] as? NSNumber
        safekey = dictionary[Keys.SafeKey] as? String
        if let cityDict = dictionary[Keys.City] as? [String:AnyObject]{
            city = City.init(dictionary: cityDict, context: context)
        }
        if let subjectDict = dictionary[Keys.Subject] as? [String:AnyObject]{
            subject = Subject.init(dictionary: subjectDict, context: context)
        }
        if let locationDict = dictionary[Keys.Location] as? [String:AnyObject]{
            location = Location.init(dictionary: locationDict, context: context)
        }
    }

}
