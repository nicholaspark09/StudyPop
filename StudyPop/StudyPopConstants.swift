//
//  StudyPopConstants.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/25/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation

extension StudyPopClient{
    struct Constants{
        static let ApiSecret = "asdfljan2382Kns2lsni2kj"
        static let ApiKey = "harryPotterIs19Cool"
        static let ApiScheme = "http"
        static let ApiHost = "stone-booking-130515.appspot.com"
        static let ApiPath = "/services/rest"
        static let LoginNotification = "LoginNotification"
        static let LoginKey = "SafeKey"
        static let City = "city"
        static let CityKey = "citykey"
        static let Subject = "subject"
        static let SubjectKey = "subjectkey"
    }
    
    struct ParameterKeys{
        static let Controller = "controller"
        static let Method = "method"
        static let ApiSecret = "api_secret"
        static let ApiKey = "api_key"
        static let Name = "name"
        static let Locale = "locale"
    }
    
    struct ParameterValues{
        static let UserController = "users"
        static let LoginMethod = "iphonelogin"
        static let RegisterMethod = "iphoneregistration"
        static let CitiesController = "cities"
        static let SubjectsController = "subjects"
        static let SearchMethod = "search"
        static let IndexMethod = "mobileindex"
    }
    
    struct JSONReponseKeys{
        static let Result = "Result"
        static let Error = "Error"
        static let Groups = "Groups"
        static let Group = "Group"
        static let SafeKey = "SafeKey"
        static let Cities = "Cities"
        static let Subjects = "Subjects"
    }
    
    struct JSONResponseValues{
        static let Success = "Success"
        static let Failure = "Failure"
    }
}