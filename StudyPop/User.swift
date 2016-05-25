//
//  User.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/25/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData


class User: NSManagedObject {

    @NSManaged var email: String?
    @NSManaged var locale: String?
    @NSManaged var name: String?
    @NSManaged var oauthtokenuid: NSNumber?
    @NSManaged var safekey: String?
    @NSManaged var token: String?
    @NSManaged var accesstoken: String?
    @NSManaged var group: NSNumber?
    @NSManaged var logged: NSNumber?
    @NSManaged var profile: NSManagedObject?
    
    //Keep the user keys here and not in constants
    // Helps me code faster
    struct Keys{
        static let Email = "email"
        static let Locale = "locale"
        static let Name = "name"
        static let Oauthtokenuid = "oauthrtokenuid"
        static let SafeKey = "safekey"
        static let Token = "token"
        static let AccessToken = "accesstoken"
        static let Group = "group"
        static let Profile = "profile"
        static let Logged = "logged"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("User", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        email = dictionary[Keys.Email] as? String
        locale = dictionary[Keys.Locale] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        token = dictionary[Keys.Token] as? String
        accesstoken = dictionary[Keys.AccessToken] as? String
        group = dictionary[Keys.Group] as? NSNumber
    }

}
