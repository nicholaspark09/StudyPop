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
        static let ApiSecret = "randomgibberish23ksn"
        static let ApiScheme = "http"
        static let ApiHost = "stone-booking-130515.appspot.com"
        static let ApiPath = "/services/rest"
    }
    
    struct ParameterKeys{
        
    }
    
    struct ParameterValues{
    
    }
    
    struct JSONReponseKeys{
        static let Result = "Result"
        static let Error = "Error"
        static let Groups = "Groups"
        static let Group = "Group"
        static let SafeKey = "SafeKey"
    }
    
    struct JSONResponseValues{
        static let Success = "Success"
        static let Failure = "Failure"
    }
}