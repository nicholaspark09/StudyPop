//
//  Event.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/8/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData


class Event: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var info: String?
    @NSManaged var subject: String?
    @NSManaged var city: String?
    @NSManaged var location: String?
    @NSManaged var maxpeople: NSNumber?
    @NSManaged var currentpeople: NSNumber?
    @NSManaged var image: String?
    @NSManaged var user: String?
    @NSManaged var ispublic: NSNumber?
    @NSManaged var price: NSNumber?
    @NSManaged var start: NSDate?
    @NSManaged var end: NSDate?
    @NSManaged var dayof: String?
    @NSManaged var photoblob: NSData?
    @NSManaged var hasCity: City?
    @NSManaged var hasSubject: Subject?
    @NSManaged var hasPhoto: Photo?
    @NSManaged var hasLocation: Location?
    
    
    struct Keys{
        static let Name = "name"
        static let Info = "info"
        static let City = "city"
        static let Subject = "subject"
        static let Location = "location"
        static let MaxPeople = "maxpeople"
        static let CurrentPeople = "currentpeople"
        static let Image = "image"
        static let User = "user"
        static let IsPublic = "ispublic"
        static let Price = "price"
        static let Start = "start"
        static let End = "end"
        static let DayOf = "dayof"
        static let PhotoBlob = "photoblob"
    }
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Event", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        info = dictionary[Keys.Info] as? String
        city = dictionary[Keys.City] as? String
        subject = dictionary[Keys.Subject] as? String
        location = dictionary[Keys.Location] as? String
        maxpeople = dictionary[Keys.MaxPeople] as? NSNumber
        currentpeople = dictionary[Keys.CurrentPeople] as? NSNumber
        image = dictionary[Keys.Image] as? String
        user = dictionary[Keys.User] as? String
        ispublic = dictionary[Keys.IsPublic] as? NSNumber
        price = dictionary[Keys.Price] as? NSNumber
        
        if let startString = dictionary[Keys.Start] as? String{
            if let startDate = StudyPopClient.sharedDateFormatter.dateFromString(startString){
                start = startDate
            }
        }
        if let endString = dictionary[Keys.End] as? String{
            if let endDate = StudyPopClient.sharedDateFormatter.dateFromString(endString){
                end = endDate
            }
        }
        dayof = dictionary[Keys.DayOf] as? String
        photoblob = dictionary[Keys.PhotoBlob] as? NSData
    }
}
