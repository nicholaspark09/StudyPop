//
//  AlertIndexViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/29/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol AlertIndexProtocol{
    func refreshClicked()
}

class AlertIndexViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    struct Constants{
        static let CellReuseIdentifier = "Alert Cell"
        static let GroupRequestsController = "grouprequests"
        static let EventRequestsController = "eventrequests"
        static let ViewRequestSegue = "ViewRequest Segue"
        static let GroupRequestSegue = "GroupRequest Segue"
        static let EventRequestSegue = "EventRequest Segue"
        static let RefreshingTitle = "Loading..."
        static let RefreshTitle = "Refresh"
    }
    
    let threshold = 50.0
    var user:User?
    var alerts = [Alert]()
    var loading = false
    var canLoadMore = true
    let seenImage = UIImage(named: "AlertSeen")
    let unseenImage = UIImage(named: "AlertSmall")
    var refreshControl: UIRefreshControl!
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var tableView: UITableView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        tableView.delegate = self
        tableView.dataSource = self
        getUser()
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(AlertIndexProtocol.refreshClicked), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        if user != nil{
            indexAlerts()
        }
    }
    
    
    // MARK: - TableView Delegates
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if alerts.count < 1{
            return "No notifications"
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alerts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! AlertTableViewCell
        let alert = alerts[indexPath.row]
        if alert.name != nil{
            cell.label.text = alert.name!
        }
        if alert.blob != nil{
            cell.alertImageView.image = UIImage(data: alert.blob!)
        }else if alert.controller! == Constants.EventRequestsController || alert.controller! == Constants.GroupRequestsController && !alert.checked && alert.originaluser != ""{
            // This was a request from a user, so grab their picture if you can
            alerts[indexPath.row].checked = true
            StudyPopClient.sharedInstance.findUserPicture(alert.originaluser!){(results,error) in
                if let error = error{
                    print("Couldn't find a picture: \(error)")
                }else if results != nil{
                    self.alerts[indexPath.row].blob = results!
                    performOnMain(){
                        cell.alertImageView.image = UIImage(data: results!)
                    }
                }
            }
        }
        if alert.seen?.boolValue == false{
            cell.alertImageView.image = unseenImage
        }else{
            cell.alertImageView.image = seenImage
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let alert = alerts[indexPath.row]
        if alert.controller != nil{
            if alert.controller! == Constants.EventRequestsController{
                performSegueWithIdentifier(Constants.EventRequestSegue, sender: alert)
            }else if alert.controller == Constants.GroupRequestsController{
                performSegueWithIdentifier(Constants.GroupRequestSegue, sender: alert)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getCount()
    }
    
    
    

    // MARK: -IndexAlerts from Server
    func indexAlerts(){
        print("Calling this")
        if !loading && canLoadMore{
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.AlertsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(alerts.count)",
                          StudyPopClient.ParameterKeys.Token : user!.token!
            ]
            loading = true
            refreshControl.beginRefreshing()
            StudyPopClient.sharedInstance.httpGet("", parameters:params){(results,error) in
                self.loading = false
                func sendError(error: String){
                    self.simpleError(error)
                    self.canLoadMore = false
                    performOnMain(){
                        self.refreshControl.endRefreshing()
                    }
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
                
                    if let groupDictionary = results![StudyPopClient.JSONReponseKeys.Alerts] as? [[String:AnyObject]]{
                        for i in groupDictionary{
                            let dict = i as Dictionary<String,AnyObject>
                            let alert = Alert.init(dictionary: dict, context: self.sharedContext)
                            self.alerts.append(alert)
                        }
                        print("The length of dictionary is \(groupDictionary.count)")
                        print("you have \(self.alerts.count) alerts")
                        if groupDictionary.count < 10{
                            print("can't Keep going")
                            self.canLoadMore = false
                        }else{
                            print("Keep going")
                            self.canLoadMore = true
                        }
                        self.updateUI()
                    }
            
            }
        }
    }
    
    
    func refreshClicked() {
        if !loading{
            alerts = [Alert]()
            updateUI()
            canLoadMore = true
            indexAlerts()
        }
    }
    
    
    
    // MARK: - UpdateTable
    func updateUI(){
        //Keep updates on the main UI Thread
        performOnMain(){
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    // MARK: -ScrollView Delegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        
        if !loading && canLoadMore && (Double(maximumOffset) - Double(contentOffset) <= threshold) {
            // Get more data - API call
            indexAlerts()
        }
    }
    

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.GroupRequestSegue{
            let alert = sender as! Alert
            if let rvc = segue.destinationViewController as? GroupRequestViewController{
                rvc.user = user!
                rvc.alert = alert
            }
        }else if segue.identifier == Constants.EventRequestSegue{
            let alert = sender as! Alert
            if let rvc = segue.destinationViewController as? EventRequestViewController{
                rvc.user = user!
                rvc.alert = alert
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
    
    func updateCount(count: Int){
        performOnMain(){
            let item = self.tabBarItem
            item.title = "Alerts \(count)"
            if count > 0{
                item.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.redColor()], forState: .Normal)
            }else{
                item.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: .Normal)
            }
        }
    }
    
    //Check for Updates from StudyPop API
    func getCount(){
        print("Getting count")
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
                self.updateCount(tempCount)
            }
        }
    }

}
