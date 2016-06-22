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
    }
    
    
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var realInfoView: UILabel!
    @IBOutlet var joinButton: UIButton!
    @IBOutlet var infoTextView: UITextView!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var joinView: UIView!
    @IBOutlet var groupImageView: UIImageView!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var subjectLabel: UILabel!
    
    
    var group:Group?
    var oldGroup: Group?
    var safekey = ""
    var user:User?
    var groupMember: GroupMember?

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getUser()
        self.title = group?.name!
        infoTextView.text = group!.info!
        realInfoView.text = group!.info!
        print("The group info is \(group!.info!)")
        //findGroupInDB()
        getGroup()
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
                    //Couldn't access the server for whatever reason, so find your latest backup!
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
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                return
            }
            
            let memberKey = results[StudyPopClient.JSONReponseKeys.MemberKey] as? String
            if memberKey != "" {
                //You are a member
                //Hide the join view
                performOnMain(){
                    
                    self.joinView.hidden = true
                    self.joinButton.hidden = true
                    
                    if let dict = results[StudyPopClient.JSONReponseKeys.GroupMember] as? [String:AnyObject]{
                        self.groupMember = GroupMember.init(dictionary: dict, context: self.sharedContext)
                        self.groupMember!.safekey = memberKey!
                        if self.groupMember!.role! == 1{
                            //This is an admin
                            //Create an edit Button
                            let editButton = UIBarButtonItem(title: Constants.EditTitle, style: .Plain, target: self, action: #selector(GroupViewProtocol.editClicked))
                            let deleteButton = UIBarButtonItem(title: Constants.DeleteTitle, style: .Plain, target: self, action: #selector(GroupViewProtocol.deleteClicked))
                            self.navigationItem.setRightBarButtonItems([editButton,deleteButton], animated: true)
                        }
                    }
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.updateUI()
                }
            }else{
                //Check for request first
                performOnMain(){
                    let request = NSFetchRequest(entityName: "GroupRequest")
                    request.fetchLimit = 1
                    let predicate = NSPredicate(format: "groupkey == %@", self.group!.safekey!)
                    let secondPredicate = NSPredicate(format: "user == %@", self.user!.token!)
                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,secondPredicate])
                    do{
                        let results = try self.sharedContext.executeFetchRequest(request)
                        if results.count > 0{
                            self.joinButton.setTitle("Join Requested. Waiting", forState: .Normal)
                        }
                    } catch{
                        let fetchError = error as NSError
                        print("The fetch error was \(fetchError)")
                    }
                }
            }
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

    @IBAction func joinClicked(sender: UIButton) {
        
        sender.enabled = false
        loadingView.startAnimating()
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupRequestsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.AddMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Group: group!.user!,
                      StudyPopClient.ParameterKeys.Token : user!.token!
        ]
        StudyPopClient.sharedInstance.httpPost("", parameters: params, jsonBody: ""){(results,error) in
            
            
            func sendError(error: String){
                self.simpleError(error)
                
                performOnMain(){
                    sender.enabled = true
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
            
            if let safekey = results[StudyPopClient.JSONReponseKeys.SafeKey] as? String{
                performOnMain(){
                    self.loadingView.stopAnimating()
                    self.joinButton.setTitle("Requested. Waiting for Approval", forState: .Normal)
                        //A Safekey was found, so save the GroupRequest
                    let dict = [GroupRequest.Keys.Name: "Request to \(self.group!.name!)",GroupRequest.Keys.GroupKey: self.group!.safekey!, GroupRequest.Keys.User : self.user!.token!, GroupRequest.Keys.SafeKey : safekey, GroupRequest.Keys.Seen: "\(0)", GroupRequest.Keys.Accepted: "\(-1)"]
                    let groupRequest = GroupRequest.init(dictionary: dict, context: self.sharedContext)
                    print("You are saving a request with \(groupRequest.name)")
                    CoreDataStackManager.sharedInstance().saveContext()
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
            self.infoTextView.text = self.group!.info!
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
                            let photoDict = [Photo.Keys.Blob : imageData, Photo.Keys.Controller : "groups", Photo.Keys.TheType : "\(1)", Photo.Keys.SafeKey : self.group!.image!, Photo.Keys.ParentKey : self.group!.safekey!]
                            let photo = Photo.init(dictionary: photoDict, context: self.sharedContext)
                            self.group!.hasProfilePhoto = photo
                            CoreDataStackManager.sharedInstance().saveContext()
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
        }
    }
    

}
