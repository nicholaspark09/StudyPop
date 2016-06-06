//
//  StudyPopServerHelper.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/25/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import UIKit
import CoreData

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
    
    func findSubject(token: String,safekey: String, completionHandlerForSubject: (results: [String:AnyObject]?, error: String?) -> Void){
        let params = [ParameterKeys.Controller : ParameterValues.CitiesController,
                      ParameterKeys.Method : ParameterValues.QuickMethod,
                      ParameterKeys.ApiKey : Constants.ApiKey,
                      ParameterKeys.ApiSecret : Constants.ApiSecret,
                      ParameterKeys.Token : token,
                      ParameterKeys.SafeKey : safekey]
        httpGet("",parameters: params){(results,error) in
            func sendError(error: String){
                completionHandlerForSubject(results: nil, error: error)
            }
            
            guard error == nil else{
                sendError("Error: \(error!.localizedDescription)")
                return
            }
            guard let stat = results[JSONReponseKeys.Result] as? String where stat == JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[JSONReponseKeys.Error])")
                return
            }
            
            guard let subjectDict = results[JSONReponseKeys.Subject] as? [String:AnyObject] else{
                sendError("Had a hard time finding the name")
                return
            }
            
            completionHandlerForSubject(results: subjectDict, error: nil)
        }
    }
    
    func findPicture(token: String,safekey: String, completionHandlerForPicture: (results: NSData?, error: String?) -> Void){
        let params = [ParameterKeys.Controller : ParameterValues.PicsController,
                      ParameterKeys.Method : ParameterValues.ViewMethod,
                      ParameterKeys.ApiKey : Constants.ApiKey,
                      ParameterKeys.ApiSecret : Constants.ApiSecret,
                      ParameterKeys.Token : token,
                      ParameterKeys.Pic : safekey]
        httpGet("",parameters: params){(results,error) in
            func sendError(error: String){
                completionHandlerForPicture(results: nil, error: error)
            }
            
            guard error == nil else{
                sendError("Error: \(error!.localizedDescription)")
                return
            }
            
            guard let stat = results[JSONReponseKeys.Result] as? String where stat == JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[JSONReponseKeys.Error])")
                return
            }
            
            guard let body = results[JSONReponseKeys.Body] as? String else{
                sendError("Couldn't find the Picture")
                return
            }
            //print("The body was \(body)")
            let newString = body.stringByRemovingPercentEncoding
            print("The new string is \(newString!)")
            if let data = NSData(base64EncodedString: newString!, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters){
                completionHandlerForPicture(results: data, error: nil)
            }else{
                sendError("Couldn't decode the picture")
            }
        }
    }
    
    func findProfileImage(token: String,safekey: String, completionHandlerForPicture: (results: NSData?, error: String?) -> Void){
        let params = [ParameterKeys.Controller : ParameterValues.PicsController,
                      ParameterKeys.Method : ParameterValues.ProfileMethod,
                      ParameterKeys.ApiKey : Constants.ApiKey,
                      ParameterKeys.ApiSecret : Constants.ApiSecret,
                      ParameterKeys.Token : token,
                      ParameterValues.ProfileMethod: safekey]
        httpGet("",parameters: params){(results,error) in
            func sendError(error: String){
                completionHandlerForPicture(results: nil, error: error)
            }
            
            guard error == nil else{
                sendError("Error: \(error!.localizedDescription)")
                return
            }
            
            guard let stat = results[JSONReponseKeys.Result] as? String where stat == JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[JSONReponseKeys.Error])")
                return
            }
            
            guard let body = results[JSONReponseKeys.Body] as? String else{
                sendError("Couldn't find the Picture")
                return
            }
            //print("The body was \(body)")
            let newString = body.stringByRemovingPercentEncoding
            print("The new string is \(newString!)")
            if let data = NSData(base64EncodedString: newString!, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters){
                completionHandlerForPicture(results: data, error: nil)
            }else{
                sendError("Couldn't decode the picture")
            }
        }
    }
    
    // Obviously...Finding the Subject
    func findSubjectInDB(safekey: String, sharedContext: NSManagedObjectContext) -> Subject?{
        let request = NSFetchRequest(entityName: "Subject")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "user == %@", safekey)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0 {
                let subject = results[0] as? Subject
                return subject
            }
        } catch {
            let fetchError = error as NSError
            print("The Error was \(fetchError)")
            return nil
        }
        return nil
    }
    
    // Obviously...Finding the City
    func findCityInDB(safekey: String, sharedContext: NSManagedObjectContext) -> City?{
        let request = NSFetchRequest(entityName: "City")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "user == %@", safekey)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0 {
                let city = results[0] as? City
                return city
            }
        } catch {
            let fetchError = error as NSError
            print("The Error was \(fetchError)")
            return nil
        }
        return nil
    }
    
    func logout(){
        
    }
}