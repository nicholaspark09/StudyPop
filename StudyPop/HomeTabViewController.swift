//
//  HomeTabViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/27/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class HomeTabViewController: UITabBarController {

    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    var user:User?
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getUser()
        getAlerts()

        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        let appDelegate = UIApplication.sharedApplication().delegate
        center.addObserverForName(StudyPopClient.Constants.AlertNotification, object: appDelegate, queue: queue) {notification -> Void in
            print("Triggering this")
            if let tempCount = notification.userInfo![StudyPopClient.JSONReponseKeys.Count] as? Int{
                print("You found a tempcount")
                self.count = tempCount
                self.updateUI()
            }
        }
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    //Check for Updates from StudyPop API
    func getAlerts(){
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.AlertsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.UnseenCount,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Token : user!.token!
        ]

        StudyPopClient.sharedInstance.httpGet("", parameters:params){(results,error) in

            func sendError(error: String){
                print("The error was \(error)")
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                sendError("Got nothing back")
                return
            }
            
            guard stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                return
            }
            
            if let tempCount = results[StudyPopClient.JSONReponseKeys.Count] as? Int{
                self.count = tempCount
                self.updateUI()
            }
        }
    }
    
    func updateUI(){
        performOnMain(){
            let item = self.tabBar.items![3]
            item.title = "Alerts \(self.count)"
            if self.count > 0{
                item.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.redColor()], forState: .Normal)
            }else{
                item.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: .Normal)
            }
        }

    }
    
    func getUser(){
        let request = NSFetchRequest(entityName: "User")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "logged == %@", true)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0{
                if let temp = results[0] as? User{
                    user = temp
                }
            }
        } catch {
            let fetchError = error as NSError
            print("The error was \(fetchError)")
        }
    }

}
