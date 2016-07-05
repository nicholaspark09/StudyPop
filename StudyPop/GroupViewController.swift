//
//  GroupViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/30/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData
import MapKit

@objc protocol GroupViewProtocol{
    func editClicked()
    func deleteClicked()
    func joinClicked()
}

class GroupViewController: UIViewController, MKMapViewDelegate {

    struct Constants{
        static let EditTitle = "Edit"
        static let GroupEditSegue = "GroupEdit Segue"
        static let PinReuseIdentifier = "Pin"
        static let DeleteTitle = "Delete"
        static let ViewMembersSegue = "ViewMembers Segue"
        static let EventsViewSegue = "EventsView Segue"
        static let GroupPostsSegue = "GroupPosts Segue"
        static let GroupRequestsSegue = "GroupRequests Segue"
        static let GroupPicsSegue = "GroupPics Segue"
    }
    
    
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var realInfoView: UILabel!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var groupImageView: UIImageView!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var subjectLabel: UILabel!
    
    
    var group:Group?
    var oldGroup: Group?
    var safekey = ""
    var user:User?
    var groupMember: GroupMember?
    var rightButton: UIBarButtonItem?

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getUser()
        self.title = group?.name!
        realInfoView.text = group!.info!
        print("The group info is \(group!.info!)")
        //findGroupInDB()
        getGroup()
        let image = UIImage(named: "AddSmall")
        let button = UIButton.init(type: UIButtonType.Custom)
        button.bounds = CGRectMake(0, 0, image!.size.width, image!.size.height)
        button.setImage(image, forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(GroupViewProtocol.joinClicked), forControlEvents: UIControlEvents.TouchUpInside)
        self.rightButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = self.rightButton
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backClicked(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    /**
        Only use this if there is no connection
        
            Want to insure data integrity
            All users should have up to date versions as admins can change data at will 
            and there may be more than one admin
    **/
    func findGroupInDB() -> Group?{
        let request = NSFetchRequest(entityName: "Group")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "safekey == %@", group!.safekey!)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0{
                if let temp = results[0] as? Group{
                    let tempgroup = temp
                    return tempgroup
                }
            }
        } catch {
            let fetchError = error as NSError
            print("The error was \(fetchError)")
            return nil
        }
        return nil
    }
    
    //Always get a live, updated version of the group
    //This also checks for permissions
    func getGroup(){
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.ViewMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.SafeKey: group!.safekey!,
                      StudyPopClient.ParameterKeys.Token : user!.token!
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
            
            performOnMain(){
                self.loadingView.stopAnimating()
            }
            
            func sendError(error: String){
                self.simpleError(error)
                performOnMain(){
                    self.group = self.findGroupInDB()
                    self.updateUI()
        
                    
                
                }
            }
            
            guard error == nil else{
                print("An error from GET: \(error!)")
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("Error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                return
            }
            
            let memberKey = results[StudyPopClient.JSONReponseKeys.MemberKey] as? String
            if memberKey != "" {
                //You are a member
                //Hide the join view
                performOnMain(){
                    self.navigationItem.rightBarButtonItem = nil
                    
                    if let dict = results[StudyPopClient.JSONReponseKeys.GroupMember] as? [String:AnyObject]{
                        self.groupMember = GroupMember.init(dictionary: dict, context: self.sharedContext)
                        self.groupMember!.safekey = memberKey!
                        if self.groupMember!.role! == 1{
                            //This is an admin
                            //Create an edit Button
                            let image = UIImage(named: "EditSmall")
                            let button = UIButton.init(type: UIButtonType.Custom)
                            button.bounds = CGRectMake(0, 0, image!.size.width, image!.size.height)
                            button.setImage(image, forState: UIControlState.Normal)
                            button.addTarget(self, action: #selector(GroupViewProtocol.editClicked), forControlEvents: UIControlEvents.TouchUpInside)
                            let editButton = UIBarButtonItem(customView: button)
                            //Create a delete button
                            let deleteImage = UIImage(named: "DeleteSmall")
                            let deleteButton = UIButton.init(type: UIButtonType.Custom)
                            deleteButton.bounds = CGRectMake(0, 0, deleteImage!.size.width, deleteImage!.size.height)
                            deleteButton.setImage(deleteImage, forState: UIControlState.Normal)
                            deleteButton.addTarget(self, action: #selector(GroupViewProtocol.deleteClicked), forControlEvents: UIControlEvents.TouchUpInside)
                            let rightDeleteButton = UIBarButtonItem(customView: deleteButton)
                            self.navigationItem.setRightBarButtonItems([editButton,rightDeleteButton], animated: true)
                        }
                    }
                }
            }
            self.updateUI()
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
    
    
    // Sends User to Edit Controller
    //Available only to certain users
    func editClicked(){
        performSegueWithIdentifier(Constants.GroupEditSegue, sender: nil)
    }
    
    @IBAction func postClicked(sender: UIButton) {
        if group?.ispublic?.intValue < 3{
            performSegueWithIdentifier(Constants.GroupPostsSegue, sender: nil)
        }else if groupMember != nil && groupMember!.safekey != nil{
            performSegueWithIdentifier(Constants.GroupPostsSegue, sender: nil)
        }
    }
    
    
    // MARK: DELETE Group
    func deleteClicked(){
        let refreshAlert = UIAlertController(title: Constants.DeleteTitle, message: "Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: Constants.DeleteTitle, style: .Default, handler: { (action: UIAlertAction!) in
            //Start Deleting...
            self.loadingView.startAnimating()
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupsController,
                StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.DeleteMethod,
                StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                StudyPopClient.ParameterKeys.SafeKey: self.group!.safekey!,
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
                
                performOnMain(){
                    self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                }
                
            }
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler:nil))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func unwindToGroupView(sender: UIStoryboardSegue){
        if let svc = sender.sourceViewController as? GroupEditViewController{
            self.group = svc.group!
            self.updateUI()
        }
    }

    func joinClicked() {
        
        rightButton!.enabled = false
        loadingView.startAnimating()
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupRequestsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.AddMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Group: group!.safekey!,
                      StudyPopClient.ParameterKeys.Token : user!.token!
        ]
        StudyPopClient.sharedInstance.httpPost("", parameters: params, jsonBody: ""){(results,error) in
            
            
            func sendError(error: String){
                self.simpleError(error)
                
                performOnMain(){
                    self.rightButton!.enabled = true
                }
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error]!)")
                return
            }

                self.simpleError("Requested")
            
                performOnMain(){
                    self.loadingView.stopAnimating()
                    if self.group != nil && self.group?.ispublic?.intValue < 2{
                        self.getGroup()
                    }
                }

        }
        
    }
    
    // Update UI with Group Info
    func updateUI(){
        performOnMain(){
            if self.group!.city != nil{
                self.cityLabel.text = self.group!.city!.name!
            }
            if self.group!.subject != nil{
                self.subjectLabel.text = self.group!.subject!.name!
            }
            self.realInfoView.text = self.group!.info!
            //Set the map
            if self.group!.location != nil && self.group!.location!.lat != 0{
                let lat = self.group!.location!.lat!.doubleValue
                let lng = self.group!.location!.lng!.doubleValue
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let currentAnnotation = MKPointAnnotation()
                currentAnnotation.coordinate = coordinate
                self.mapView.addAnnotation(currentAnnotation)
                
                //Zoom in on point
                var region = MKCoordinateRegion()
                var span = MKCoordinateSpan()
                span.latitudeDelta = 0.01
                span.longitudeDelta = 0.01
                region.span = span
                region.center = coordinate
                self.mapView.setRegion(region, animated: true)
                self.mapView.regionThatFits(region)
            }
            //Check to see if there's an image on db first
            if self.group!.hasProfilePhoto != nil && self.group!.hasProfilePhoto!.safekey != nil{
                self.groupImageView.image = self.group!.hasProfilePhoto!.photoImage
                self.groupImageView.contentMode = UIViewContentMode.ScaleAspectFit
            }else if self.group!.image != nil && self.group!.image != ""{
                var found = false
                // First check the local db, you never know!
                if let oldGroup = self.findGroupInDB(){
                    if oldGroup.hasProfilePhoto != nil && oldGroup.hasProfilePhoto!.blob != nil{
                        //Load old image first so the user isn't bored
                        let image = UIImage(data: oldGroup.hasProfilePhoto!.blob!)
                        self.groupImageView.image = image
                        self.groupImageView.contentMode = UIViewContentMode.ScaleAspectFit
                        //Check to see if it's the same image
                        if oldGroup.hasProfilePhoto!.safekey == self.group!.image!{
                            found = true
                        }
                    }
                }
                if !found{
                    print("loading it up!")
                    //Find the image
                    StudyPopClient.sharedInstance.findPicture(self.user!.token!, safekey: self.group!.image!){ (imageData,error) in
                        func sendError(error: String){
                            self.simpleError(error)
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
                            self.groupImageView.image = image
                            self.groupImageView.contentMode = UIViewContentMode.ScaleAspectFit
                            
                            print("The group safekey is \(self.group!.safekey)")
                            
                            
                            let photoDict = [Photo.Keys.Blob : imageData, Photo.Keys.Controller : "groups", Photo.Keys.TheType : "\(1)", Photo.Keys.SafeKey : self.group!.image!, Photo.Keys.ParentKey : self.group!.safekey!]
                            let photo = Photo.init(dictionary: photoDict, context: self.sharedContext)
                            self.group!.hasProfilePhoto = photo
                        }
                    }
                }
            }
        }
    }
    


    
    // MARK: MapViewDelegates
    // MARK: - MKMapViewDelegate Add Pin to MapView
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.PinReuseIdentifier) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.PinReuseIdentifier)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView?.draggable = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
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


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.GroupEditSegue{
            if let gec = segue.destinationViewController as? GroupEditViewController{
                gec.user = user!
                gec.group = group!
            }
        }else if segue.identifier == Constants.ViewMembersSegue{
            if let mvc = segue.destinationViewController as? MembersViewController{
                mvc.group = group!
                mvc.user = user!
            }
        }else if segue.identifier == Constants.EventsViewSegue{
            if let evc = segue.destinationViewController as? GroupEventsTableViewController{
                evc.user = user!
                evc.group = group!
            }
        }else if segue.identifier == Constants.GroupPostsSegue{
            if let gvc = segue.destinationViewController as? GroupPostsViewController{
                gvc.user = user!
                gvc.group = group!
            }
        }else if segue.identifier == Constants.GroupRequestsSegue{
            if let grc = segue.destinationViewController as? GroupRequestIndexViewController{
                grc.user = user!
                grc.group = group!
            }
        }else if segue.identifier == Constants.GroupPicsSegue{
            if let gpc = segue.destinationViewController as? GroupPicIndexViewController{
                gpc.user = user!
                gpc.group = group!
            }
        }
    }
    

}
