//
//  ProfileViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/6/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class ProfileViewController: UIViewController {

    
    struct Constants{
        static let Controller = "ProfileView"
        static let EditProfileSegue = "ProfileEdit Segue"
    }
    
    @IBOutlet var editButton: UIButton!
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var infoTextView: UITextView!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var profileImageView: UIImageView!
    
    
    var user: User?{
        didSet{
            print("YOu set this")
        }
    }
    var profile:Profile?
    var city:City?
    var subject:Subject?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if user != nil && profile == nil{
            print("You should be grabbing it")
            //This is your profile
            editButton.hidden = false
            getMyProfile()
        }else{
            //This is someone else's profile
        }
    }

    
    @IBAction func backClicked(sender: UIButton) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: MyProfileViewMethod
    func getMyProfile(){
        self.loadingView.startAnimating()
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.ProfilesController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.MyProfileMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Token : user!.token!
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
            func sendError(error: String){
                self.simpleError(error)
                self.loadingView.stopAnimating()
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
                self.loadingView.stopAnimating()
            }
            if let profileDict = results[StudyPopClient.JSONReponseKeys.Profile] as? [String:AnyObject]{
                
                self.profile = Profile.init(dictionary: profileDict, context: self.sharedContext)
                if let safekey = results[StudyPopClient.JSONReponseKeys.SafeKey] as? String{
                    self.profile!.safekey = safekey
                    print("YOu found a safekey with \(safekey) as the value")
                }
                self.profile!.user = self.user!.token!
                self.updateUI()
            }else{
                print("You ended up here...")
            }
        }
    }
    
    
    
    func updateUI(){
        performOnMain(){
            self.nameLabel.text = self.profile!.name!
            self.infoTextView.text = self.profile!.info!
            //Check the DB for a profile Pic
            if self.profile!.hasPhoto != nil{
                
            }else if self.profile!.image != nil && self.profile!.image! != ""{
                var found = false
                if let oldProfile = self.findProfileInDB(){
                    if oldProfile.image != nil && oldProfile.image! == self.profile!.image! {
                        if oldProfile.hasPhoto != nil{
                            self.profileImageView.image = oldProfile.hasPhoto!.photoImage!
                            self.profileImageView.contentMode = UIViewContentMode.ScaleAspectFit
                            found = true
                        }
                    }
                }
                if !found {
                    print("The Profile safekey is \(self.profile!.safekey!)")
                    //Look up the image from the DB
                    //Find the image
                    StudyPopClient.sharedInstance.findProfileImage(self.user!.token!, safekey: self.profile!.safekey!){ (imageData,error) in
                        func sendError(error: String){
                            print("The error was: \(error)")
                            //Do not interrupt the user for this image GET
                            //If this doesn't update, it's not super important
                        }
                        
                        guard error == nil else{
                            sendError(error!)
                            return
                        }
                        
                        guard let imageData = imageData else{
                            sendError("No image")
                            return
                        }
                        
                        performOnMain(){
                            let image = UIImage(data: imageData)
                            self.profileImageView.image = image
                            self.profileImageView.contentMode = UIViewContentMode.ScaleAspectFit
                            let photoDict = [Photo.Keys.Blob : imageData, Photo.Keys.Controller : "profiles", Photo.Keys.TheType : "\(1)", Photo.Keys.SafeKey :"", Photo.Keys.ParentKey : self.profile!.safekey!]
                            let photo = Photo.init(dictionary: photoDict, context: self.sharedContext)
                            self.profile!.hasPhoto = photo
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                }
            }
        
            
            if self.profile!.city != nil && self.profile!.city! != ""{
                
                self.city = StudyPopClient.sharedInstance.findCityInDB(self.profile!.city!, sharedContext: self.sharedContext)
                if self.city == nil{
                    //City wasn't in DB, so look on the server!
                    StudyPopClient.sharedInstance.findCity(self.user!.token!, safekey: self.profile!.city!){ (results,error) in
                        func sendError(error: String){
                            print("The error was: \(error)")
                        }
                        
                        guard error == nil else{
                            sendError(error!)
                            return
                        }
                        
                        let cityDict = [City.Keys.Name : results!, City.Keys.User : self.profile!.city!]
                        self.city = City.init(dictionary: cityDict, context: self.sharedContext)
                        performOnMain(){
                            self.cityLabel.text = self.city!.name!
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                }else{
                    self.cityLabel.text = self.city!.name!
                }
            }else{
                self.cityLabel.text = "No City"
            }
            if self.profile!.subject != nil && self.profile!.subject != ""{
                print("1")
                self.subject  = StudyPopClient.sharedInstance.findSubjectInDB(self.profile!.subject!, sharedContext: self.sharedContext)
                if self.subject == nil{
                    //Subject wasn't in DB, so look on the server!
                    StudyPopClient.sharedInstance.findSubject(self.user!.token!, safekey: self.profile!.subject!){ (results,error) in
                        func sendError(error: String){
                            print("The error was: \(error)")
                        }
                        
                        guard error == nil else{
                            sendError(error!)
                            return
                        }
                        
                        guard let results = results else{
                            sendError("Didn't find a subject")
                            return
                        }
                        
                        self.subject = Subject.init(dictionary: results, context: self.sharedContext)
                        performOnMain(){
                            self.subjectLabel.text = self.subject!.name!
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                }else{
                    self.subjectLabel.text = self.subject!.name!
                }
            }else{
                self.subjectLabel.text = "No Subject"
            }
        }
    }
    
    // MARK: FindProfile from Local DB
    func findProfileInDB() -> Profile?{
        let request = NSFetchRequest(entityName: "Profile")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "user == %@", user!.token!)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0{
                if let temp = results[0] as? Profile{
                    return temp
                }
            }
        } catch {
            let fetchError = error as NSError
            print("The error was \(fetchError)")
        }
        return nil
    }

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.EditProfileSegue{
            if let epc = segue.destinationViewController.contentViewController as? EditProfileViewController{
                epc.user = user!
                epc.profile = profile!
                epc.city = self.city
                epc.subject = self.subject
            }
        }
    }


}
