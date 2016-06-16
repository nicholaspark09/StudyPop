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
        static let UserNotification = "StudyPopUser Notification"
    }
    
    struct ParameterKeys{
        static let Controller = "controller"
        static let Method = "method"
        static let ApiSecret = "api_secret"
        static let ApiKey = "api_key"
        static let Name = "name"
        static let Locale = "locale"
        static let Offset = "offset"
        static let Token = "token"
        static let SafeKey = "safekey"
        static let BigImage = "bigImage"
        static let SmallImage = "smallImage"
        static let IsPublic = "isPublic"
        static let People = "people"
        static let Group = "group"
        static let Lat = "lat"
        static let Lng = "lng"
        static let Body = "body"
        static let Thumb = "thumb"
        static let Pic = "pic"
        static let User = "user"
        static let Query = "query"
        static let LatInfo = "latinfo"
        static let LocationSafeKey = "locationsafekey"
    }
    
    struct ParameterValues{
        static let UserController = "users"
        static let GroupsController = "groups"
        static let GroupRequestsController = "grouprequests"
        static let GroupMembersController = "groupmembers"
        static let ProfilesController = "profiles"
        static let EventsController = "events"
        static let CitiesController = "cities"
        static let PicsController = "pics"
        static let SubjectsController = "subjects"
        static let LoginMethod = "iphonelogin"
        static let RegisterMethod = "iphoneregistration"
        static let SearchMethod = "search"
        static let EditMethod = "mobileedit"
        static let IndexMethod = "mobileindex"
        static let ViewMethod = "mobileview"
        static let MyProfileMethod = "myprofile"
        static let ProfileMethod = "profile"
        static let QuickMethod = "quick"
        static let ProfileAdd = "profileadd"
        static let DeleteMethod = "delete"
        static let AddMethod = "add"
        static let UserThumbMethod = "userthumb"
        static let UserViewMethod = "userview"
        static let GroupEventsMethod = "groupindex"
    }
    
    struct JSONReponseKeys{
        static let Result = "Result"
        static let Error = "Error"
        static let Groups = "Groups"
        static let Group = "Group"
        static let SafeKey = "SafeKey"
        static let Cities = "Cities"
        static let Subjects = "Subjects"
        static let MemberKey = "MemberKey"
        static let GroupMember = "Member"
        static let GroupMembers = "GroupMembers"
        static let City = "City"
        static let Subject = "Subject"
        static let Location = "Location"
        static let LocationKey = "LocationKey"
        static let Body = "Body"
        static let Profile = "Profile"
        static let Profiles = "Profiles"
        static let Events = "Events"
        static let Event = "Event"
        static let EventMember = "EventMember"
        static let EventMembers = "EventMembers"
    }
    
    struct JSONResponseValues{
        static let Success = "Success"
        static let Failure = "Failure"
    }
}