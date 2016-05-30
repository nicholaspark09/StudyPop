//
//  StudyPopServerHelper.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/25/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation

extension StudyPopClient{
    
    func login(email: String, completionHandlerForLogin: (results:String?, error: String?) -> Void){
        let params = [
            ParameterKeys.Controller : ParameterValues.UserController,
            ParameterKeys.Method : ParameterValues.LoginMethod,
            ParameterKeys.ApiKey : Constants.ApiKey,
            ParameterKeys.ApiSecret : Constants.ApiSecret,
            User.Keys.Email : email
        ]
        httpGet("", parameters: params){ (results,error) in
            func sendError(error: String){
                completionHandlerForLogin(results: nil, error: error)
            }
            
            guard error == nil else{
                sendError("Error: \(error!.localizedDescription)")
                return
            }
            guard let stat = results[JSONReponseKeys.Result] as? String where stat == JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[JSONReponseKeys.Error])")
                return
            }
            
            guard let safekey = results[JSONReponseKeys.SafeKey] as? String else{
                sendError("Couldn't find the safekey in the response")
                return
            }
            
            completionHandlerForLogin(results: safekey, error: nil)
        }
    }
    
    func registerUser(name: String, email: String, completionHandlerForRegistration: (results: String?, error: String?) -> Void){
        let params = [
            ParameterKeys.Controller : ParameterValues.UserController,
            ParameterKeys.Method : ParameterValues.RegisterMethod,
            ParameterKeys.ApiKey : Constants.ApiKey,
            ParameterKeys.ApiSecret : Constants.ApiSecret,
            User.Keys.Email : email
        ]
        httpPost("", parameters: params, jsonBody: ""){ (results,error) in
            func sendError(error: String){
                completionHandlerForRegistration(results: nil, error: error)
            }
            
            guard error == nil else{
                sendError("Error: \(error!.localizedDescription)")
                return
            }
            guard let stat = results[JSONReponseKeys.Result] as? String where stat == JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[JSONReponseKeys.Error])")
                return
            }
            
            guard let safekey = results[JSONReponseKeys.SafeKey] as? String else{
                sendError("Couldn't find the safekey in the response")
                return
            }
            
            completionHandlerForRegistration(results: safekey, error: nil)
        }
    }
    
    func findCity(token: String,safekey: String, completionHandlerForCity: (results: String?, error: String?) -> Void){
        let params = [ParameterKeys.Controller : ParameterValues.CitiesController,
                      ParameterKeys.Method : ParameterValues.QuickMethod,
                      ParameterKeys.ApiKey : Constants.ApiKey,
                      ParameterKeys.ApiSecret : Constants.ApiSecret,
                      ParameterKeys.Token : token,
                      ParameterKeys.SafeKey : safekey]
        httpGet("",parameters: params){(results,error) in
            func sendError(error: String){
                completionHandlerForCity(results: nil, error: error)
            }
            
            guard error == nil else{
                sendError("Error: \(error!.localizedDescription)")
                return
            }
            guard let stat = results[JSONReponseKeys.Result] as? String where stat == JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[JSONReponseKeys.Error])")
                return
            }
            
            guard let name = results["Name"] as? String else{
                sendError("Had a hard time finding the name")
                return
            }
            completionHandlerForCity(results: name, error: nil)
        }
    }
    
    func logout(){
        
    }
}