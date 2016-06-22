//
//  EventMembersTableViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/16/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol EventMembersProtocol{
    func refreshClicked()
}

class EventMembersTableViewController: UITableViewController {

    struct Constants{
        static let LoadingTitle = "Loading"
        static let NotLoadingTitle = ""
        static let RefreshTitle = "Refresh"
        static let CellReuseIdentifier = "EventMember Cell"
        static let ProfileViewSegue = "ProfileView Segue"
    }
    
    var event:Event?
    var user:User?
    var members = [EventMember]()
    var loadingButton: UIBarButtonItem?
    var canLoadMore = true
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if event != nil{
            title = "\(event!.name!) Members"
        }
        
        loadingButton = UIBarButtonItem(title: Constants.NotLoadingTitle, style: .Plain, target: self, action: #selector(EventMembersProtocol.refreshClicked))
        navigationItem.rightBarButtonItem = loadingButton
        indexMembers()
    }



    // MARK: - Table view data source


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return members.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! EventMemberTableViewCell

        let member = members[indexPath.row]
        cell.eventMember = member
        if member.thumbblob == nil && !member.checked{
            member.checked = true
            StudyPopClient.sharedInstance.findUserPicture(member.user!){(results,error) in
                if let error = error{
                    print("Couldn't find a picture: \(error)")
                }else if results != nil{
                    member.thumbblob = results!
                    performOnMain(){
                        cell.imageData = member.thumbblob!
                    }
                }
            }
        }else if member.thumbblob != nil{
            cell.imageData = member.thumbblob!
        }
        
        return cell
    }
    

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let member = members[indexPath.row]
        performSegueWithIdentifier(Constants.ProfileViewSegue, sender: member)
    }

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
    
    func updateUI(){
        performOnMain(){
            self.loadingButton!.title = Constants.RefreshTitle
            self.loadingButton!.enabled = true
            self.tableView.reloadData()
        }
    }
    
    func refreshClicked(){
        members = [EventMember]()
        updateUI()
        indexMembers()
    }
    
    // MARK: - Get Members from StudyPop API
    func indexMembers(){
        if canLoadMore{
            loadingButton?.title = Constants.LoadingTitle
            loadingButton?.enabled = false
            print("Sending the safekey of \(event!.safekey!)")
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventMembersController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(members.count)",
                          Event.Keys.SafeKey : event!.safekey!,
                          StudyPopClient.ParameterKeys.Token : user!.token!
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters: params) { (results,error) in
                
                func sendError(error: String){
                    self.loadingButton!.title = Constants.RefreshTitle
                    self.loadingButton!.enabled = true
                    self.simpleError(error)
                }
                
                guard error == nil else{
                    sendError(error!.localizedDescription)
                    return
                }
                
                guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                    sendError("StudyPopApi: Could not get proper response from server")
                    return
                }
                
                if stat == StudyPopClient.JSONResponseValues.Success{
                    if let membersDictionary = results![StudyPopClient.JSONReponseKeys.EventMembers] as? [[String:AnyObject]]{
                        for i in membersDictionary{
                            let dict = i as Dictionary<String,AnyObject>
                            let member = EventMember.init(dictionary:dict, context: self.sharedContext)
                            self.members.append(member)
                        }
                        if membersDictionary.count < 10{
                            self.canLoadMore = false
                        }else{
                            self.canLoadMore = true
                        }
                        self.updateUI()
                    }
                }else if let responseError = results[StudyPopClient.JSONReponseKeys.Error] as? String{
                    sendError(responseError)
                }
            }
        }
    }


    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.ProfileViewSegue{
            if let pvc = segue.destinationViewController as? ProfileViewController{
                let member = sender as! EventMember
                pvc.user = user
                pvc.profileUser = member.user!
            }
        }
    }

}
