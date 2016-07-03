//
//  MyGroupsTableViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/2/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol MyGroupsProtocol{
    func backClicked()
    func refreshClicked()
}

class MyGroupsTableViewController: UITableViewController {

    struct Constants{
        static let RefreshTitle = "Refresh"
        static let RefreshingTitle = "Loading..."
        static let CellReuseIdentifier = "Group Cell"
        static let GroupViewSegue = "GroupView Segue"
    }
    
    var members = [GroupMember]()
    var canLoadMore = true
    var loading = false
    var refreshButton:UIBarButtonItem?
    var user:User?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My Groups"
        refreshButton = UIBarButtonItem(title: Constants.RefreshTitle, style: .Plain, target: self, action: #selector(MyEventsProtocol.refreshClicked))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: #selector(MyEventsProtocol.backClicked))
        navigationItem.rightBarButtonItem = refreshButton
        
        indexMyGroups()
    }



    // MARK: - Table view data source

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if members.count < 1 {
            return "You aren't in any groups"
        }
        return nil
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return members.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! GroupTableViewCell
        let group = members[indexPath.row].fromGroup
        if group != nil{
            cell.groupNameLabel.text = group!.name!
            if group!.city != nil{
                cell.cityLabel.text = group!.city!.name!
            }
            if group!.thumbblob == nil && group!.image != nil && group!.image != "" && group!.checked == false{
                StudyPopClient.sharedInstance.findThumb(self.user!.token!, safekey: group!.image!){(results,error) in
                    self.members[indexPath.row].fromGroup!.checked = true
                    if let error = error{
                        print("Couldn't find a picture: \(error)")
                    }else if results != nil{
                        performOnMain(){
                            print("got back in image")
                            self.members[indexPath.row].fromGroup!.thumbblob = results!
                            cell.group = self.members[indexPath.row].fromGroup!
                        }
                    }
                }
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let group = members[indexPath.row].fromGroup!
        performSegueWithIdentifier(Constants.GroupViewSegue, sender: group)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            dropGroup(members[indexPath.row].safekey!)
            members.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

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
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.GroupViewSegue{
            let group = sender as! Group
            if let gvc = segue.destinationViewController.contentViewController as? GroupViewController{
                gvc.user = user!
                gvc.group = group
            }
        }
    }
    
    func backClicked(){
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func refreshClicked(){
        canLoadMore = true
        members = [GroupMember]()
        indexMyGroups()
    }
    
    // MARK: -IndexMyEvents
    func indexMyGroups(){
        if !loading && canLoadMore{
            refreshButton!.title = Constants.RefreshingTitle
            refreshButton!.enabled = false
            loading = true
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupMembersController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.MyIndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(members.count)",
                          StudyPopClient.ParameterKeys.Token : user!.token!
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters: params) { (results,error) in
                
                self.loading = false
                func sendError(error: String){
                    self.refreshButton!.title = Constants.RefreshTitle
                    self.refreshButton!.enabled = true
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
                    if let membersDictionary = results![StudyPopClient.JSONReponseKeys.GroupMembers] as? [[String:AnyObject]]{
                        for i in membersDictionary{
                            let dict = i as Dictionary<String,AnyObject>
                            let member = GroupMember.init(dictionary:dict, context: self.sharedContext)
                            self.members.append(member)
                        }
                        print("you got back \(membersDictionary.count) members")
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
    
    // MARK: - Drop from Group
    func dropGroup(safekey: String){
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupMembersController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.DeleteMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.SafeKey: safekey,
                      StudyPopClient.ParameterKeys.Token : self.user!.token!
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
            func sendError(error: String){
                self.simpleError(error)
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error]!)")
                return
            }
            
        }
    }
    
    func updateUI(){
        performOnMain(){
            self.loading = false
            self.refreshButton!.title = Constants.RefreshTitle
            self.refreshButton!.enabled = true
            self.tableView.reloadData()
        }
    }
}
