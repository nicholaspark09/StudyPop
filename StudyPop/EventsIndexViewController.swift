//
//  EventsIndexViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/27/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol EventsIndexProtocol{
    func refreshClicked()
}

class EventsIndexViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    struct Constants{
        static let CityPickerSegue = "CityPicker Segue"
        static let CityPickedButton = "CityBlue"
        static let CityUnpickedButton = "CityWhite"
        static let SubjectPickedButton = "SubjectBlue"
        static let SubjectUnpickedButton = "SubjectWhite"
        static let SubjectPickerSegue = "SubjectPicker Segue"
        static let Controller = "Events"
        static let CellReuseIdentifier = "EventCell"
        static let EventViewSegue = "EventView Segue"
        static let MyEventsSegue = "MyEvents Segue"
    }
    
    
    var events = [Event]()
    var user:User?
    // Legacy Keys used in case no one's logged in
    var cityKey = ""
    var subjectKey = ""
    var canLoadMore = true
    var loading = false
    var locale = "en_US"
    var refreshControl: UIRefreshControl!

    // MARK: SharedContext
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var cityButton: UIButton!
    @IBOutlet var subjectButton: UIButton!
    @IBOutlet var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Grab the city first
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        (_,cityKey) = appDelegate.getCity()
        if cityKey != ""{
            cityButton!.setImage(UIImage(named:Constants.CityPickedButton), forState: .Normal)
        }
        (_,subjectKey) = appDelegate.getSubject()
        if subjectKey != ""{
            subjectButton.setImage(UIImage(named: Constants.SubjectPickedButton), forState: .Normal)
        }else{
            subjectButton.setImage(UIImage(named: Constants.SubjectUnpickedButton), forState: .Normal)
        }
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(EventsIndexProtocol.refreshClicked), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        getUser()
        // Upload events right away and pull from the server as you want today's events
        indexEvents()
    }

    
    // MARK: - Unwind to Events Controller
    @IBAction func unwindToEvents(sender: UIStoryboardSegue){
        if let sourceViewController = sender.sourceViewController as? CityPickerViewController{
            cityKey = sourceViewController.currentCityKey
            if cityKey != ""{
                cityButton.setImage(UIImage(named: Constants.CityPickedButton), forState: .Normal)
            }else{
                cityButton.setImage(UIImage(named: Constants.CityUnpickedButton), forState: .Normal)
            }
            print("You got a citykey back of id: \(cityKey)")
        }else if let svc = sender.sourceViewController as? StudyPickerViewController{
            subjectKey = svc.subjectKey
            if subjectKey != ""{
                subjectButton.setImage(UIImage(named: Constants.SubjectPickedButton), forState: .Normal)
            }else{
                subjectButton.setImage(UIImage(named: Constants.SubjectUnpickedButton), forState: .Normal)
            }
        }
    }
    
    func refreshClicked(){
        events = [Event]()
        self.updateUI()
        self.canLoadMore = true
        indexEvents()
    }
    
    
    // MARK: -IndexEvents From Server
    //Live! Don't pull from the local db as events will constantly change
    // It's important that users don't get the wrong information
    func indexEvents(){
        if !loading && canLoadMore{
            loading = true
            let name = textField.text!
            self.refreshControl.beginRefreshing()
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(events.count)",
                          StudyPopClient.ParameterKeys.Locale:locale,
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          Event.Keys.City : cityKey,
                          Event.Keys.Subject : subjectKey,
                          Event.Keys.Name : name
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters:params){(results,error) in
                
                self.loading = false
                
                func sendError(error: String){
                    self.simpleError(error)
                    self.canLoadMore = false
                    performOnMain(){
                        self.refreshControl.endRefreshing()
                    }
                    print("You have hit an error")
                }
                
                guard error == nil else{
                    sendError(error!.localizedDescription)
                    return
                }
                
                guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                    sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                    return
                }
                
                performOnMain(){
                    if let eventDictionary = results![StudyPopClient.JSONReponseKeys.Events] as? [[String:AnyObject]]{
                        for i in eventDictionary{
                            let dict = i as Dictionary<String,AnyObject>
                            let event = Event.init(dictionary: dict, context: self.sharedContext)
                            self.events.append(event)
                        }
                        print("There are \(eventDictionary.count) number or groups in this batch")
                        if eventDictionary.count < 10{
                            self.canLoadMore = false
                        }else{
                            self.canLoadMore = true
                        }
                        self.updateUI()
                    }
                    self.loading = false
                }
            }
        }
    }
    
    // MARK: - TableView Delegates
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM dd"
        return dateFormatter.stringFromDate(date)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! EventTableViewCell
        let event = events[indexPath.row]
        cell.event = event
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let event = events[indexPath.row]
        performSegueWithIdentifier(Constants.EventViewSegue, sender: event)
    }
    
    func updateUI(){
        performOnMain(){
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
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
    
    
    @IBAction func searchClicked(sender: UIButton) {
        events = [Event]()
        self.updateUI()
        self.canLoadMore = true
        indexEvents()
    }

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.CityPickerSegue{
            if let cityPicker = segue.destinationViewController as? CityPickerViewController{
                cityPicker.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.SubjectPickerSegue{
            if let subjectPicker = segue.destinationViewController as? StudyPickerViewController{
                subjectPicker.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.EventViewSegue{
            let event = sender as! Event
            if let esc = segue.destinationViewController.contentViewController as? EventViewController{
                esc.user = user
                esc.safekey = event.safekey!
            }
        }else if segue.identifier == Constants.MyEventsSegue{
            if let mec = segue.destinationViewController.contentViewController as? MyEventsTableViewController{
                mec.user = user!
            }
        }
    }
    

}
