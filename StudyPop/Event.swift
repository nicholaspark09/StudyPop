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
    @NSManaged var safekey: String?
    @NSManaged var city: City?
    @NSManaged var subject: Subject?
    @NSManaged var hasPhoto: Photo?
    @NSManaged var location: Location?
    @NSManaged var hasMembers: [EventMember]?
    var startString:String?
    var endString:String?
    
    
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
        static let HasMembers = "hasmembers"
        static let SafeKey = "safekey"
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
        maxpeople = dictionary[Keys.MaxPeople] as? NSNumber
        currentpeople = dictionary[Keys.CurrentPeople] as? NSNumber
        image = dictionary[Keys.Image] as? String
        user = dictionary[Keys.User] as? String
        ispublic = dictionary[Keys.IsPublic] as? NSNumber
        price = dictionary[Keys.Price] as? NSNumber
        dayof = dictionary[Keys.DayOf] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        startString = dictionary[Keys.Start] as? String
        if startString != nil{
            if let startDate = StudyPopClient.sharedDateFormatter.dateFromString(startString!){
                start = startDate
            }
        }
        endString = dictionary[Keys.End] as? String
        if endString != nil{
            if let endDate = StudyPopClient.sharedDateFormatter.dateFromString(endString!){
                end = endDate
            }
        }
        if let cityDict = dictionary[Keys.City] as? [String:AnyObject]{
            city = City.init(dictionary: cityDict, context: context)
        }
        if let subjectDict = dictionary[Keys.Subject] as? [String:AnyObject]{
            subject = Subject.init(dictionary: subjectDict, context: context)
        }
        if let locationDict = dictionary[Keys.Location] as? [String:AnyObject]{
            location = Location.init(dictionary: locationDict, context: context)
        }
        dayof = dictionary[Keys.DayOf] as? String
        photoblob = dictionary[Keys.PhotoBlob] as? NSData
    }
}
