//
//  MembersViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/7/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class MembersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct Constants{
        static let CellReuseIdentifier = "Member Cell"
        static let ProfileViewSegue = "ProfileView Segue"
    }
    
    var group:Group?
    var user:User?
    var members = [GroupMember]()
    var isLoading = false
    var canLoadMore = true
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var searchButton: UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "\(group!.name!) Members"
        indexMembers()
    }

    func indexMembers(){
        isLoading = true
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupMembersController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Offset: "\(members.count)",
                      StudyPopClient.ParameterKeys.Group : group!.safekey!,
                      StudyPopClient.ParameterKeys.Token : user!.token!
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters:params){(results,error) in
            func sendError(error: String){
                self.simpleError(error)
                self.isLoading = false
                self.canLoadMore = false
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
                if let groupDictionary = results![StudyPopClient.JSONReponseKeys.GroupMembers] as? [[String:AnyObject]]{
                    var x = 0
                    for i in groupDictionary{
                        let dict = i as Dictionary<String,AnyObject>
                        let member = GroupMember.init(dictionary: dict, context: self.sharedContext)
                        self.members.append(member)
                        x+=1
                    }
                    print("There are \(x) number or groups in this batch")
                    if x < 10{
                        self.canLoadMore = false
                    }else{
                        self.canLoadMore = true
                    }
                    self.updateUI()
                }
                self.isLoading = false
            }
        }
    }
    
    func updateUI(){
        performOnMain(){
            self.tableView.reloadData()
        }
    }
    
    // MARK: - TableViewDelegates
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return members.count
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! GroupMemberTableViewCell
        let member = members[indexPath.row]
        cell.groupMember = member
        if cell.groupMember!.photoblob == nil && !cell.groupMember!.checked{
            cell.groupMember!.checked = true
            StudyPopClient.sharedInstance.findUserPicture(cell.groupMember!.user!){(results,error) in
                if let error = error{
                    print("Couldn't find a picture: \(error)")
                }else if results != nil{
                    cell.groupMember!.photoblob = results!
                    performOnMain(){
                        cell.imageData = cell.groupMember!.photoblob!
                    }
                }
            }
        }else if cell.groupMember!.photoblob != nil{
            cell.imageData = cell.groupMember!.photoblob!
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

            performSegueWithIdentifier(Constants.ProfileViewSegue, sender: nil)
    }

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.ProfileViewSegue{
            let member = members[tableView.indexPathForSelectedRow!.row]
            if let pvc = segue.destinationViewController as? ProfileViewController{
                pvc.profileUser = member.user!
                pvc.user = user!
            }
        }
    }
    

}
