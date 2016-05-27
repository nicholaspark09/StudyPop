//
//  StudyPopClient.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/25/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation

class StudyPopClient: NSObject{
    
    
    var session = NSURLSession.sharedSession()
    
    // MARK: GET
    func httpGet(method: String, parameters: [String : AnyObject], completionHandlerForGET:(result:AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask{
        let request = NSMutableURLRequest(URL: urlFromParameters(parameters, withPathExtension: method))
        //request.addValue(Constants.ApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            
            
            func sendError(error: String){
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForGET(result:nil,error: NSError(domain:"httpGet", code: 1, userInfo:userInfo))
            }
            /* GUARD: Was there an error? */
            guard (error == nil) else{
                sendError("Error: \(error!.localizedDescription)")
                return
            }
            /* GUARD: did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else{
                sendError("Your request sent back a non 200 response")
                return
            }
            
            /* GUARD: Was there any data? */
            guard let data = data else{
                sendError("No data sent back by request")
                return
            }
            let string = NSString.init(data: data, encoding: NSUTF8StringEncoding)
            print("The return was \(string)")
            self.convertDataWithCompletion(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        task.resume()
        return task
    }
    
    // MARK: POST requests
    func httpPost(method: String, parameters: [String : AnyObject], jsonBody: String,completionHandlerForPOST:(result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask{
        let request = NSMutableURLRequest(URL: urlFromParameters(parameters, withPathExtension: method))
        request.HTTPMethod = "POST"
        request.addValue("application/json",forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.addValue(Constants.ApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.HTTPBody = jsonBody.dataUsingEncoding(NSUTF8StringEncoding)
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
           
            
            func sendError(error: String){
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForPOST(result:nil,error: NSError(domain:"httpPost", code: 1, userInfo:userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else{
                sendError("There was an error with the request: \(error)")
                return
            }
            /* GUARD: did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else{
                sendError("Your request sent back a non 2xx response")
                return
            }
            
            /* GUARD: Was there any data? */
            guard let data = data else{
                sendError("No data sent back by request")
                return
            }
            self.convertDataWithCompletion(data, completionHandlerForConvertData: completionHandlerForPOST)
        }
        task.resume()
        return task
    }
    
    
    // substitute the key for the value that is contained within the method name
    func substituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    // MARK: Get Clean URL Parameters
    func urlFromParameters(parameters: [String:AnyObject], withPathExtension: String? = nil) -> NSURL{
        
        let components = NSURLComponents()
        components.scheme = Constants.ApiScheme
        components.host = Constants.ApiHost
        components.path = Constants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [NSURLQueryItem]()
        
        for (key,value) in parameters {
            let qItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(qItem)
        }
        return components.URL!
    }
    
    // MARK: Convert JSON to Objects
    private func convertDataWithCompletion(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void){
        var parsedResult: AnyObject!
        do{
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse as json: '\(data)'"]
            completionHandlerForConvertData(result: nil, error: NSError(domain:"convertDataWithCompletionHandler",code: 1, userInfo: userInfo))
        }
        completionHandlerForConvertData(result:parsedResult, error:nil)
    }
    
    // MARK: - Shared Date Formatter
    
    class var sharedDateFormatter: NSDateFormatter  {
        
        struct Singleton {
            static let dateFormatter = Singleton.generateDateFormatter()
            
            static func generateDateFormatter() -> NSDateFormatter {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-mm-dd"
                
                return formatter
            }
        }
        
        return Singleton.dateFormatter
    }
    
    
    // MARK: SharedInstance
    /*
        Access the client object through this Singleton
            - removes duplication
    */
    static let sharedInstance = StudyPopClient()
    private override init(){}
}
