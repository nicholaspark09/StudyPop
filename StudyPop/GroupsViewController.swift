//
//  GroupsViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/27/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol GroupsViewProtocol{
    func refreshClicked()
}

class GroupsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    struct Constants{
        static let LogoutAlertTitle = "Logout Confirmation"
        static let LogoutAlertMessage = "Are you sure you want to logout?"
        static let LogoutCancel = "Cancel"
        static let LogoutTitle = "Logout"
        static let CityPickerSegue = "CityPicker Segue"
        static let CityPickedButton = "CityBlue"
        static let CityUnpickedButton = "CityWhite"
        static let SubjectPickedButton = "SubjectBlue"
        static let SubjectUnpickedButton = "SubjectWhite"
        static let SubjectPickerSegue = "SubjectPicker Segue"
        static let CellReuseIdentifier = "Group Cell"
        static let Controller = "GroupsViewController"
        static let AddSegue = "AddGroup Segue"
        static let GroupViewSegue = "GroupView Segue"
        static let MyGroupsSegue = "MyGroups Segue"
    }
    
    /**
        Variables Section
    */
    // MARK: SharedContext
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    /*
    lazy var scratchContext: NSManagedObjectContext = {
        var context = NSManagedObjectContext()
        context.persistentStoreCoordinator = CoreDataStackManager.sharedInstance().persistentStoreCoordinator
        return context
    }()
 */

    var cityKey = ""
    var subjectKey = ""
    var query = ""
    var searching = false
    var groups = [Group]()
    var locale = "en_US"
    var user:User?
    var group: Group?
    var isLoading = false
    var canLoadMore = true
    let threshold = 50.0
    var refreshControl: UIRefreshControl!
    /**     
        IBOutlets

    **/
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var cityButton: UIButton!
    @IBOutlet var subjectButton: UIButton!
    @IBOutlet var searchTextField: UITextField!
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
        
        getUser()
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(GroupsViewProtocol.refreshClicked), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        getLocalGroups()
        /*
        if user != nil{
            if subjectKey != "" || cityKey != ""{
                searchGroups()
            }else{
                indexGroups()
            }
        }*/
        
    }

    // MARK: -ScrollView Delegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        
        if !isLoading && canLoadMore && (Double(maximumOffset) - Double(contentOffset) <= threshold) {
            // Get more data - API call
            indexGroups()
        }
    }
    
    func refreshClicked(){
        if !isLoading{
            groups = [Group]()
            updateUI()
            indexGroups()
        }
    }
    
    
    @IBAction func logoutClicked(sender: UIButton) {
        let logoutAlert = UIAlertController(title: Constants.LogoutAlertTitle, message: Constants.LogoutAlertMessage, preferredStyle: .Alert)
        //Add a cancel button
        logoutAlert.addAction(UIAlertAction(title: Constants.LogoutCancel, style: .Cancel, handler: nil))
        //Logout is confirmed
        logoutAlert.addAction(UIAlertAction(title: Constants.LogoutTitle, style: .Default, handler: {(action: UIAlertAction!) in
            //Get the user first
            let request = NSFetchRequest(entityName: "User")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "logged == %@", true)
            do{
                let users = try self.sharedContext.executeFetchRequest(request) as! [User]
                if users.count > 0{
                    users[0].logged = false
                    users[0].safekey = ""
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
            } catch let error as NSError{
                print("The error was \(error.localizedDescription)")
            }
        }))
        
        presentViewController(logoutAlert, animated: true, completion: nil)
    }
    
    
    // MARK: - Unwind From other Segues to Here
    @IBAction func unwindToGroups(sender: UIStoryboardSegue){
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
        }else if let avc = sender.sourceViewController as? AddGroupViewController{
            group = avc.group
            groups.insert(group!, atIndex: 0)
            updateUI()
        }
    }
    
    
    @IBAction func seachClicked(sender: UIButton) {
        self.canLoadMore = true
        let query = searchTextField.text!
        if cityKey == "" && subjectKey == "" && query.characters.count < 1{
            groups = [Group]()
            updateUI()
            searching = false
            indexGroups()
        }else{
            searching = true
            groups = [Group]()
            updateUI()
            searchGroups()
        }
    }
    
    
    // MARK: - IndexGroups
    func indexGroups(){
        if !isLoading{
            isLoading = true
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(groups.count)",
                          StudyPopClient.ParameterKeys.Locale:locale,
                          StudyPopClient.ParameterKeys.Token : user!.token!
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters:params){(results,error) in
                func sendError(error: String){
                    self.simpleError(error)
                    self.isLoading = false
                    self.canLoadMore = false
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
                    if let groupDictionary = results![StudyPopClient.JSONReponseKeys.Groups] as? [[String:AnyObject]]{
                        
                        for i in groupDictionary{
                            let dict = i as Dictionary<String,AnyObject>
                            
                            //Check to make sure there are no duplicates
                            let safekey = dict[Group.Keys.SafeKey] as! String
                            if let group = self.findGroup(safekey){
                                self.sharedContext.deleteObject(group)
                            }
                            let group = Group.init(dictionary: dict, context: self.sharedContext)
                            self.groups.append(group)
                        }
                        performOnMain(){
                            CoreDataStackManager.sharedInstance().saveContext()
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
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - SearchGroups
    func searchGroups(){
        self.isLoading = true
        let query = searchTextField.text!
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.SearchMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Offset: "\(groups.count)",
                      StudyPopClient.ParameterKeys.Locale:locale,
                      StudyPopClient.ParameterKeys.Token : user!.token!,
                      Group.Keys.City: cityKey,
                      Group.Keys.Subject: subjectKey,
                      Group.Keys.Name : query
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters:params){(results,error) in
            func sendError(error: String){
                self.simpleError(error)
                self.isLoading = false
                self.canLoadMore = false
                if self.groups.count < 1{
                    //Get the groups from the local DB
                    
                }
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                return
            }
            

                if let groupDictionary = results![StudyPopClient.JSONReponseKeys.Groups] as? [[String:AnyObject]]{
                    for i in groupDictionary{
                        let dict = i as Dictionary<String,AnyObject>
                        
                        //Check to make sure there are no duplicates
                        let safekey = dict[Group.Keys.SafeKey] as! String
                        if let group = self.findGroup(safekey){
                            self.sharedContext.deleteObject(group)
                        }
                        let group = Group.init(dictionary: dict, context: self.sharedContext)
                        self.groups.append(group)
                    }
                    performOnMain(){
                        CoreDataStackManager.sharedInstance().saveContext()
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
                self.isLoading = false
            
        }
    }

    func updateUI(){
        performOnMain(){
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
            self.isLoading = false
        }
    }
    
    func findGroup(safekey: String) -> Group?{
        let request = NSFetchRequest(entityName: "Group")
        request.predicate = NSPredicate(format: "safekey == %@", safekey)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0{
                if let temp = results[0] as? Group{
                    return temp
                }
            }
        } catch {
            let fetchError = error as NSError
            print("The error was \(fetchError)")
        }
        return nil
    }
    
    func getLocalGroups(){
        let fetchRequest = NSFetchRequest(entityName: "Group")
        do{
            self.groups = try sharedContext.executeFetchRequest(fetchRequest) as! [Group]
            if self.groups.count > 0{
                updateUI()
            }
        } catch let error as NSError{
            print("The error was \(error)")
        }
    }
    
    // MARK: - Navigation
    //Prep time
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.AddSegue{
            if let agc = segue.destinationViewController.contentViewController as? AddGroupViewController{
                agc.user = user
            }
        }else if segue.identifier == Constants.CityPickerSegue{
            if let cityPicker = segue.destinationViewController as? CityPickerViewController{
                cityPicker.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.SubjectPickerSegue{
            if let subjectPicker = segue.destinationViewController as? StudyPickerViewController{
                subjectPicker.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.GroupViewSegue{
            if let groupView = segue.destinationViewController.contentViewController as? GroupViewController{
                groupView.group = sender as? Group
            }
        }else if segue.identifier == Constants.MyGroupsSegue{
            if let mgc = segue.destinationViewController.contentViewController as? MyGroupsTableViewController{
                mgc.user = user!

            }
        }
    }
    
    // MARK: - TableView Delegates
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if groups.count < 1{
            return "No groups"
        }
        return nil
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! GroupTableViewCell
        let group = groups[indexPath.row]
        cell.group = group
        if group.city != nil{
            cell.cityLabel.text = group.city!.name!
        }
        if group.thumbblob == nil && group.image != nil && group.image != "" && group.checked == false{
            StudyPopClient.sharedInstance.findThumb(self.user!.token!, safekey: group.image!){(results,error) in
                self.groups[indexPath.row].checked = true
                if let error = error{
                    print("Couldn't find a picture: \(error)")
                }else if results != nil{
                    performOnMain(){
                        print("got back in image")
                        self.groups[indexPath.row].thumbblob = results!
                        cell.group = self.groups[indexPath.row]
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(Constants.GroupViewSegue, sender: groups[indexPath.row])
    }
    
    //Ensure the Popover is just the right size
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
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
