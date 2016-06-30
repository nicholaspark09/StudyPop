//
//  GroupRequestViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/30/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class GroupRequestViewController: UIViewController {

    struct Constants{
        static let GroupViewSegue = "GroupView Segue"
        static let Accepted = 2
    }
    
    
    var alert:Alert?
    var request:GroupRequest?
    var profile:Profile?
    var user:User?
    var group:Group?
    var checked = false
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var infoTextView: UITextView!
    @IBOutlet var groupButton: UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if alert != nil{
            titleLabel.text = alert!.name!
        }
        getRequest()
    }


    @IBAction func backClicked(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func getRequest(){
        loadingView.startAnimating()
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupRequestsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.ViewMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.SafeKey : alert!.safekey!
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters:params){(results,error) in
                func sendError(error: String){
                    self.simpleError(error)
                    performOnMain(){
                        self.loadingView.stopAnimating()
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
                
                if let profileDictionary = results![StudyPopClient.JSONReponseKeys.Profile] as? [String:AnyObject]{
                    self.profile = Profile.init(dictionary: profileDictionary, context: self.sharedContext)
                    
                }
                if let requestDictionary = results![StudyPopClient.JSONReponseKeys.GroupRequest] as? [String:AnyObject]{
                    self.request = GroupRequest.init(dictionary: requestDictionary, context: self.sharedContext)
                }
                
                if let groupDict = results![StudyPopClient.JSONReponseKeys.Group] as? [String:AnyObject]{
                    self.group = Group.init(dictionary: groupDict, context: self.sharedContext)
                    
                }
                
                self.updateUI()
            }

    }
    
    func updateUI(){
        performOnMain(){
            self.loadingView.stopAnimating()
            if self.profile != nil{
                self.nameLabel.text = self.profile!.name!
                if self.profile!.city != nil{
                    self.cityLabel.text = self.profile!.city!.name!
                }
                self.infoTextView.text = self.profile!.info!
            }
            if self.group != nil{
                self.groupButton.setTitle(self.group!.name!, forState: .Normal)
            }
        }
        if profile != nil && !checked{
            checked = true
            print("The original user key is \(alert!.originaluser!)")
            StudyPopClient.sharedInstance.findProfileImage(self.user!.token!, safekey: self.profile!.safekey!){ (imageData,error) in
                func sendError(error: String){
                    print("The error was: \(error)")
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
                }
            }
        }
    }
    
    
    @IBAction func deleteClicked(sender: UIButton) {
        if request != nil{
            sender.enabled = false
            self.loadingView.startAnimating()
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupRequestsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.DeleteMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.SafeKey : alert!.safekey!,
                          StudyPopClient.ParameterKeys.AlertKey : alert!.user!
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters:params){(results,error) in
                func sendError(error: String){
                    self.simpleError(error)
                    performOnMain(){
                        self.loadingView.stopAnimating()
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
                
                //It has been deleted
                performOnMain(){
                    self.loadingView.stopAnimating()
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        }else{
            self.simpleError("Please wait till everything is loaded")
        }
        
    }
    
    @IBAction func acceptIt(sender: UIButton){
        self.loadingView.startAnimating()
        sender.enabled = false
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupRequestsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.ResponseMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Token : user!.token!,
                      StudyPopClient.ParameterKeys.SafeKey : alert!.safekey!,
                      GroupRequest.Keys.Accepted : "\(Constants.Accepted)",
                      StudyPopClient.ParameterKeys.AlertKey : alert!.user!
                      ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){(results,error) in
            
            performOnMain(){
                self.loadingView.stopAnimating()
                sender.enabled = true
            }
            
            func sendError(error: String){
                self.simpleError(error)
                
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                sendError("Got nothing from the server. Please try again")
                return
            }
            
            if stat == StudyPopClient.JSONResponseValues.Success{
                performOnMain(){
                    self.loadingView.stopAnimating()
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
            }
        }
    }
    
    
    @IBAction func groupClicked(sender: AnyObject) {
        
        if group != nil{
            performSegueWithIdentifier(Constants.GroupViewSegue, sender: nil)
        }
    }
    

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.GroupViewSegue{
            if let gvc = segue.destinationViewController.contentViewController as? GroupViewController{
                gvc.user = user!
                gvc.group = group!
            }
        }
    }
    

}
