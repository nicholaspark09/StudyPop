//
//  GroupEventsTableViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/8/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol GroupEventsProtocol{
    func addClicked()
}

class GroupEventsTableViewController: UITableViewController {

    struct Constants{
        static let Title = "Events"
        static let AddTitle = "Add"
        static let AddEventSegue = "AddEvent Segue"
        static let CellReuseIdentifier = "EventCell"
        static let EventViewSegue = "EventView Segue"
    }
    
    /**
     Variables Section
     */
    // MARK: SharedContext
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    var group: Group?
    var user: User?
    var events = [Event]()
    var loading = false
    var canLoadMore = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if group != nil{
            title = Constants.Title
        }
        
        let addButton = UIBarButtonItem.init(title: Constants.AddTitle, style: .Plain, target: self, action: #selector(GroupEventsProtocol.addClicked))
        self.navigationItem.rightBarButtonItem = addButton
        
        indexEvents()
    }

    func addClicked(){
       performSegueWithIdentifier(Constants.AddEventSegue, sender: nil)
    }
    
    func updateUI(){
        performOnMain(){
            if self.events.count < 1{
                let eventDict = [Event.Keys.SafeKey : "", Event.Keys.Name : "No events"]
                let event = Event.init(dictionary: eventDict, context: self.sharedContext)
                self.events.append(event)
            }
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Get Group Events
    func indexEvents(){
        loading = true
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.GroupEventsMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Offset: "\(events.count)",
                      StudyPopClient.ParameterKeys.Token : user!.token!,
                      StudyPopClient.ParameterKeys.Group : group!.safekey!
        ]
        
        StudyPopClient.sharedInstance.httpGet("", parameters: params){(results,error) in
            func sendError(error: String){
                self.simpleError(error)
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                return
            }
            if let eventDictionary = results![StudyPopClient.JSONReponseKeys.Events] as? [[String:AnyObject]]{
                var x = 0
                for i in eventDictionary{
                    let dict = i as Dictionary<String,AnyObject>
                    let event = Event.init(dictionary: dict, context: self.sharedContext)
                    self.events.append(event)
                    x+=1
                }
                if x < 10{
                    self.canLoadMore = false
                }else{
                    self.canLoadMore = true
                }
                self.updateUI()
            }
            self.loading = false
            
        }
    }

    
    @IBAction func unwindToGroupEvents(sender: UIStoryboardSegue){
        if let aec = sender.sourceViewController as? AddEventViewController{
            let safekey = aec.safekey
            if safekey != nil{
                performSegueWithIdentifier(Constants.EventViewSegue, sender: safekey!)
            }
        }
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return events.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! EventTableViewCell
            cell.event = events[indexPath.row]
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let event = events[indexPath.row]
        if event.safekey! != ""{
            performSegueWithIdentifier(Constants.EventViewSegue, sender: event.safekey!)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */



    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.AddEventSegue{
            if let avc = segue.destinationViewController as? AddEventViewController{
                avc.user = user!
                avc.group = group!
            }
        }else if segue.identifier == Constants.EventViewSegue{
            if let safekey = sender as? String{
                if let evc = segue.destinationViewController as? EventViewController{
                    evc.safekey = safekey
                    evc.user = user!
                }
            }
        }
    }


}
