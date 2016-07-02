//
//  AlertIndexViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/29/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

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
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var refreshButton: UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        tableView.delegate = self
        tableView.dataSource = self
        getUser()
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
    

    // MARK: -IndexAlerts from Server
    func indexAlerts(){
        if !loading && canLoadMore{
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.AlertsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(alerts.count)",
                          StudyPopClient.ParameterKeys.Token : user!.token!
            ]
            refreshButton.setTitle(Constants.RefreshingTitle, forState: .Normal)
            refreshButton.enabled = false
            StudyPopClient.sharedInstance.httpGet("", parameters:params){(results,error) in
                self.loading = false
                func sendError(error: String){
                    self.simpleError(error)
                    self.canLoadMore = false
                    performOnMain(){
                        self.refreshButton.setTitle(Constants.RefreshTitle, forState: .Normal)
                        self.refreshButton.enabled = true
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
                
                performOnMain(){
                    if let groupDictionary = results![StudyPopClient.JSONReponseKeys.Alerts] as? [[String:AnyObject]]{
                        for i in groupDictionary{
                            let dict = i as Dictionary<String,AnyObject>
                            let alert = Alert.init(dictionary: dict, context: self.sharedContext)
                            self.alerts.append(alert)
                        }
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
    }
    
    
    @IBAction func refreshClicked(sender: AnyObject) {
        alerts = [Alert]()
        updateUI()
        canLoadMore = true
        indexAlerts()
    }
    
    
    
    // MARK: - UpdateTable
    func updateUI(){
        //Keep updates on the main UI Thread
        performOnMain(){
            self.tableView.reloadData()
            self.refreshButton.setTitle(Constants.RefreshTitle, forState: .Normal)
            self.refreshButton.enabled = true
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

}
