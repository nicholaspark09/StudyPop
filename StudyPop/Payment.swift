//
//  Payment.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/9/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import CoreData


class Payment: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var info: String?
    @NSManaged var controller: String?
    @NSManaged var action: String?
    @NSManaged var total: NSNumber?
    @NSManaged var totalpaid: NSNumber?
    @NSManaged var paymenttype: NSNumber?
    @NSManaged var created: NSDate?
    @NSManaged var modified: NSDate?
    @NSManaged var user: String?
    @NSManaged var stripeid: String?
    @NSManaged var currency: String?
    @NSManaged var token: String?
    @NSManaged var safekey: String?
    
    struct Keys{
        static let Name = "name"
        static let Info = "info"
        static let Controller = "controller"
        static let Action = "action"
        static let Total = "total"
        static let TotalPaid = "totalpaid"
        static let PaymentType = "paymenttype"
        static let Created = "created"
        static let Modified = "modified"
        static let User = "user"
        static let StripeId = "stripeid"
        static let Currency = "currency"
        static let Token = "token"
        static let SafeKey = "safekey"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Payment", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.Name] as? String
        info = dictionary[Keys.Info] as? String
        controller = dictionary[Keys.Controller] as? String
        action = dictionary[Keys.Action] as? String
        total = dictionary[Keys.Total] as? NSNumber
        totalpaid = dictionary[Keys.TotalPaid] as? NSNumber
        stripeid = dictionary[Keys.StripeId] as? String
        token = dictionary[Keys.Token] as? String
        currency = dictionary[Keys.Currency] as? String
        user = dictionary[Keys.User] as? String
        paymenttype = dictionary[Keys.PaymentType] as? NSNumber
        safekey = dictionary[Keys.SafeKey] as? String
        if let createdString = dictionary[Keys.Created] as? String{
            print("The created date was \(createdString)")
            if let startDate = StudyPopClient.sharedDateFormatter.dateFromString(createdString){
                created = startDate
            }
        }
        if let endString = dictionary[Keys.Modified] as? String{
            if let endDate = StudyPopClient.sharedDateFormatter.dateFromString(endString){
                modified = endDate
            }
        }
    }
    

}
