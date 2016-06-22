//
//  PeopleViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/6/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class PeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    struct Constants{
        static let MyProfileSegue = "MyProfile Segue"
        static let PickedCityImage = "CityBlue"
        static let UnpickedCityImage = "CityWhite"
        static let PickedSubjectImage = "SubjectBlue"
        static let UnpickedSubjectImage = "SubjectWhite"
        static let PickSubjectSegue = "PickSubject Segue"
        static let PickCitySegue = "PickCity Segue"
        static let Controller = "PeopleView"
        static let SearchingLabel = "Searching..."
        static let SearchLabel = "Search"
        static let CellReuseIdentifier = "Profile Cell"
        static let ProfileViewSegue = "ProfileView Segue"
        static let LogoutTitle = "Logout of Account"
        static let LogoutMessage = "Logout"
        static let LogoutCancel = "Don't Logout"
        static let UnwindToLoginSegue = "UnwindToLogin Segue"
    }
    
    
    
    //Keep IBOutlets in the same place
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var cityButton: UIButton!
    @IBOutlet var subjectButton: UIButton!
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var nameTextField: UITextField!
    
    //All the variables should be here
    var user:User?
    var profiles = [Profile]()
    var currentCityName = ""
    var currentCityKey = ""{
        didSet{
            if currentCityKey == ""{
                performOnMain(){
                    self.cityButton.setImage(UIImage(named:Constants.UnpickedCityImage), forState: .Normal)
                }
            }else{
                performOnMain(){
                    self.cityButton.setImage(UIImage(named:Constants.PickedCityImage), forState: .Normal)
                }
            }
        }
    }
    var currentSubjectName = ""
    var currentSubjectKey = ""{
        didSet{
            if currentSubjectKey == ""{
                performOnMain(){
                    self.subjectButton.setImage(UIImage(named:Constants.UnpickedSubjectImage), forState: .Normal)
                }
            }else{
                performOnMain(){
                    self.subjectButton.setImage(UIImage(named:Constants.PickedSubjectImage), forState: .Normal)
                }
            }
        }
    }
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getUser()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        (currentCityName,currentCityKey) = appDelegate.getCity()
        (currentSubjectName,currentSubjectKey) = appDelegate.getSubject()
        indexProfiles()
    }

    
    @IBAction func searchClicked(sender: UIButton) {
        
            profiles = [Profile]()
            indexProfiles()
    }


    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.MyProfileSegue{
            print("YOu should be performing Segue")
            if let pvc = segue.destinationViewController as? ProfileViewController{
                pvc.user = user!
            }
        }else if segue.identifier == Constants.PickSubjectSegue{
            if let svc = segue.destinationViewController as? StudyPickerViewController{
                svc.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.PickCitySegue{
            if let cvc = segue.destinationViewController as? CityPickerViewController{
                cvc.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.ProfileViewSegue{
            if let pvc = segue.destinationViewController as? ProfileViewController{
                pvc.user = user!
                pvc.profile = profiles[tableView.indexPathForSelectedRow!.row]
            }
        }
    }
    
    //Unwind from other Controllers to this ViewController
    @IBAction func unwindToPeople(sender: UIStoryboardSegue){
        if let svc = sender.sourceViewController as? StudyPickerViewController{
            currentSubjectKey = svc.subjectKey
        }else if let cvc = sender.sourceViewController as? CityPickerViewController{
            currentCityKey = cvc.currentCityKey
        }
    }
    
    
    //Search
    func indexProfiles(){
        let name = nameTextField.text!
        searchButton.enabled = false
        searchButton.setTitle(Constants.SearchingLabel, forState: .Normal)
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.ProfilesController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.SearchMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Name : name,
                          Profile.Keys.Subject : currentSubjectKey,
                          Profile.Keys.City : currentCityKey,
                          StudyPopClient.ParameterKeys.Offset : "\(profiles.count)",
                          StudyPopClient.ParameterKeys.Token : user!.token!
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
                
                performOnMain(){
                    self.searchButton.setTitle(Constants.SearchLabel, forState: .Normal)
                    self.searchButton.enabled = true
                }
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
                
                performOnMain(){
                    if let profileDictionary = results![StudyPopClient.JSONReponseKeys.Profiles] as? [[String:AnyObject]]{
                        for i in profileDictionary{
                            let dict = i as Dictionary<String,AnyObject>
                            let profile = Profile.init(dictionary: dict, context: self.sharedContext)
                            self.profiles.append(profile)
                            print("Got another profile with name: \(profile.name!)")
                        }
                        self.updateUI()
                    }
                }
            }
    }
    
    
    // MARK: - TableView Delegates
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profiles.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! ProfileTableViewCell
        let profile = profiles[indexPath.row]
        cell.profile = profile
        if profile.thumbblob != nil{
            cell.thumbData = profile.thumbblob!
        }
        if profile.checked == false{
            StudyPopClient.sharedInstance.findUserPicture(profile.user!){(results,error) in
                if let error = error{
                    self.profiles[indexPath.row].checked = true
                    print("Couldn't find a picture: \(error)")
                }else if results != nil{
                    print("Found a pic!")
                    performOnMain(){
                        cell.thumbData = results!
                    }
                }
            }
        }
        return cell
    }
    
    
    
    @IBAction func logoutClicked(sender: UIButton) {
        let refreshAlert = UIAlertController(title: Constants.LogoutTitle, message: "Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: Constants.LogoutCancel, style: .Default, handler: nil))
        refreshAlert.addAction(UIAlertAction(title: Constants.LogoutMessage, style: .Cancel, handler: { (action: UIAlertAction!) in
            if self.user != nil{
                self.user!.logged = false
                CoreDataStackManager.sharedInstance().saveContext()
                self.performSegueWithIdentifier(Constants.UnwindToLoginSegue, sender: nil)
            }
        }))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
        
        
        
    }
    
    

    func updateUI(){
        performOnMain(){
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

}
