//
//  GroupsViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/27/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

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
    let threshold = 100.0
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
        if user != nil{
            if subjectKey != "" || cityKey != ""{
                searchGroups()
            }else{
                indexGroups()
            }
        }
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
            groups = []
            searching = false
            indexGroups()
        }else{
            searching = true
            groups = []
            updateUI()
            searchGroups()
        }
    }
    
    
    // MARK: - IndexGroups
    func indexGroups(){
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
                    var x = 0
                    for i in groupDictionary{
                        let dict = i as Dictionary<String,AnyObject>
                        let group = Group.init(dictionary: dict, context: self.sharedContext)
                        self.groups.append(group)
                        x+=1
                    }
                    print("There are \(x) number or groups in this batch")
                    if x < 10{
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
                    var x = 0
                    for i in groupDictionary{
                        let dict = i as Dictionary<String,AnyObject>
                        let group = Group.init(dictionary: dict, context: self.sharedContext)
                        self.groups.append(group)
                        x+=1
                    }
                    print("There are \(x) number or groups in this batch")
                    if x < 10{
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

    func updateUI(){
        performOnMain(){
            self.tableView.reloadData()
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
        }
    }
    
    // MARK: - TableView Delegates
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! GroupTableViewCell
        let group = groups[indexPath.row]
        cell.group = group
        if group.hasCity == nil && group.city != nil && group.city != ""{
            StudyPopClient.sharedInstance.findCity(user!.token!, safekey: group.city!){ (results,error) in
                if let error = error{
                    self.simpleError(error)
                }else if results != nil{
                    let dict = [City.Keys.Name : results!, City.Keys.User : group.city!]
                    performOnMain(){
                        //Save the city in the
                        let city = City.init(dictionary: dict, context: self.sharedContext)
                        self.groups[indexPath.row].hasCity = city
                        cell.cityLabel.text = city.name!
                    }
                }
            }
        }else if group.hasCity != nil{
            cell.cityLabel.text = group.hasCity!.name!
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        group = groups[indexPath.row]
        performSegueWithIdentifier(Constants.GroupViewSegue, sender: group)
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
