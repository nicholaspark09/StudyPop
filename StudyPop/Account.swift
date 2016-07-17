//
//  Account.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/16/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData


class Account: NSManagedObject {


    @NSManaged var name: String?
    @NSManaged var info: String?
    @NSManaged var email: String?
    @NSManaged var phone:String?
    @NSManaged var clientid: String?
    @NSManaged var stripeid: String?
    @NSManaged var secretkey: String?
    @NSManaged var publishablekey: String?
    @NSManaged var country: String?
    @NSManaged var user: String?
    @NSManaged var safekey: String?
    @NSManaged var balance: NSNumber?
    @NSManaged var modified: NSDate?
    @NSManaged var groupkey: String?
    
    struct Keys{
        static let Name = "name"
        static let Info = "info"
        static let Email = "email"
        static let Phone = "phone"
        static let ClientId = "clientid"
        static let StripeId = "stripeid"
        static let SecretKey = "secretkey"
        static let PublishableKey = "publishablekey"
        static let Country = "country"
        static let User = "user"
        static let SafeKey = "safekey"
        static let Balance = "balance"
        static let Modified = "modified"
        static let GroupKey = "groupkey"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Account", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        info = dictionary[Keys.Info] as? String
        email = dictionary[Keys.Email] as? String
        phone = dictionary[Keys.Phone] as? String
        balance = dictionary[Keys.Balance] as? NSNumber
        user = dictionary[Keys.User] as? String
        clientid = dictionary[Keys.ClientId] as? String
        stripeid = dictionary[Keys.StripeId] as? String
        secretkey = dictionary[Keys.SecretKey] as? String
        publishablekey = dictionary[Keys.PublishableKey] as? String
        groupkey = dictionary[Keys.GroupKey] as? String
        country = dictionary[Keys.Country] as? String
        safekey = dictionary[Keys.SafeKey] as? String
        if let startString = dictionary[Keys.Modified] as? String{
            if let startDate = StudyPopClient.sharedDateFormatter.dateFromString(startString){
                modified = startDate
            }
        }
    }

}
