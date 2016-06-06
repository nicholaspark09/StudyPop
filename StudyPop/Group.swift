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
    @NSManaged var subject: String?
    @NSManaged var maxpeople: NSNumber?
    @NSManaged var currentpeople: NSNumber?
    @NSManaged var location: String?
    @NSManaged var user: String?
    @NSManaged var image: String?
    @NSManaged var city: String?
    @NSManaged var ispublic: NSNumber?
    @NSManaged var hasCity: City?
    @NSManaged var hasSubject:Subject?
    @NSManaged var hasLocation: Location?
    @NSManaged var hasProfilePhoto: Photo?
    
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
        static let HasSubject = "hassubject"
        static let HasLocation = "haslocation"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Group", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        user = dictionary[Keys.User] as? String
        info = dictionary[Keys.Info] as? String
        subject = dictionary[Keys.Subject] as? String
        maxpeople = dictionary[Keys.MaxPeople] as? NSNumber
        currentpeople = dictionary[Keys.CurrentPeople] as? NSNumber
        location = dictionary[Keys.Location] as? String
        image = dictionary[Keys.Image] as? String
        city = dictionary[Keys.City] as? String
        ispublic = dictionary[Keys.IsPublic] as? NSNumber
        
    }

}
