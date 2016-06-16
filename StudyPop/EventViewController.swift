//
//  EventViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/11/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData
import MapKit

@objc protocol EventViewProtocol{
    func joinClicked(sender: UIBarButtonItem)
    func editClicked(sender: UIBarButtonItem)
    func dropClicked(sender: UIBarButtonItem)
    func deleteClicked(sender: UIBarButtonItem)
}

class EventViewController: UIViewController, MKMapViewDelegate {

    
    struct Constants{
        static let PinReuseIdentifier = "Pin"
        static let EventEditSegue = "EventEdit Segue"
        static let DeleteTitle = "Delete Event"
        static let EventMembersSegue = "EventMembers Segue"
    }
    
    
    
    
    var safekey = ""
    var event: Event?
    var eventMember: EventMember?
    var user: User?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    @IBOutlet var eventDateLabel: UILabel!
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var infoTextView: UITextView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var eventImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if safekey != ""{
            getLiveEvent()
        }
    }
    
    
    // MARK: - GetEvent from Server
    // Always do this to check credentials and guarantee up to date event details
    func getLiveEvent(){
        loadingView.startAnimating()
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.ViewMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Token : user!.token!,
                      StudyPopClient.ParameterKeys.SafeKey : safekey
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){(results,error) in
            func sendError(error: String){
                self.simpleError(error)
                self.loadingView.stopAnimating()
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                sendError("Returned gibberish")
                return
            }
            
            guard stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                return
            }
            
            if let eventDict = results[StudyPopClient.JSONReponseKeys.Event] as? [String:AnyObject]{
                self.event = Event.init(dictionary: eventDict, context: self.sharedContext)
                self.event!.safekey = self.safekey

            
                // THE Api always returns a value for Member
                // Nonmembers return ""
                //Members always return a dict
                if let memberDict = results[StudyPopClient.JSONReponseKeys.EventMember] as? [String:AnyObject]{
                    if let safekey = memberDict[EventMember.Keys.SafeKey] as? String{
                            self.eventMember = self.checkEventMember(safekey)
                            self.eventMember = EventMember.init(dictionary: memberDict, context: self.sharedContext)
                    }
                }
                CoreDataStackManager.sharedInstance().saveContext()
                self.updateUI()
            }
        }
    }
    
    func updateUI(){
        if event != nil{
            performOnMain(){
                self.title = self.event!.name!
                if self.event!.start != nil{
                    self.eventDateLabel.text = self.event!.start!.description
                }
                self.infoTextView.text = self.event!.info!
                self.loadingView.stopAnimating()
                if self.event!.city != nil{
                    self.cityLabel.text = self.event!.city!.name!
                }
                if self.event!.subject != nil{
                    self.subjectLabel.text = self.event!.subject!.name!
                }
                if self.eventMember != nil{
                    //Show everything
                    if self.eventMember!.role!.intValue == 1{
                        //This is an Admin, so add an edit button
                        let editButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: #selector(EventViewProtocol.editClicked(_:)))
                        let deleteButton = UIBarButtonItem(title: "Delete", style: .Plain, target: self, action: #selector(EventViewProtocol.deleteClicked(_:)))
                        self.navigationItem.setRightBarButtonItems([editButton,deleteButton], animated: true)
                    }else{
                        //Just a regular member, add a drop button
                        let dropButton = UIBarButtonItem(title: "Drop", style: .Plain, target: self, action: #selector(EventViewProtocol.dropClicked(_:)))
                        self.navigationItem.rightBarButtonItem = dropButton
                    }
                    self.showLocation()
                }else{
                    //Check privacy level of Event
                    if self.event!.ispublic?.intValue == 1{
                        //Public event, show everything
                        self.showLocation()
                    }else if self.event!.ispublic?.intValue == 2{
                        // Part way private
                        // Show city, subject, location
                        
                    }else if self.event!.ispublic?.intValue == 3{
                        //Hide everything
                        self.cityLabel.text = ""
                        self.subjectLabel.text = ""
                    }
                    //Not a member, create a join button
                    let joinButton = UIBarButtonItem(title: "Join", style: .Plain, target: self, action: #selector(EventViewProtocol.joinClicked(_:)))
                    self.navigationItem.rightBarButtonItem = joinButton
                }
                //Check to see if there's an image on db first
                if self.event!.hasPhoto != nil && self.event!.hasPhoto!.safekey != nil{
                    self.eventImageView.image = self.event!.hasPhoto!.photoImage
                    self.eventImageView.contentMode = UIViewContentMode.ScaleAspectFit
                }else if self.event!.image != nil && self.event!.image != ""{
                    var found = false
                    // First check the local db, you never know!
                    if let oldEvent = self.findEventInDB(){
                        if oldEvent.hasPhoto != nil && oldEvent.hasPhoto!.blob != nil{
                            //Load old image first so the user isn't bored
                            let image = UIImage(data: oldEvent.hasPhoto!.blob!)
                            self.eventImageView.image = image
                            self.eventImageView.contentMode = UIViewContentMode.ScaleAspectFit
                            //Check to see if it's the same image
                            if oldEvent.hasPhoto!.safekey == self.event!.image!{
                                found = true
                            }
                        }
                    }
                    if !found{
                        print("loading it up!")
                        //Find the image
                        StudyPopClient.sharedInstance.findPicture(self.user!.token!, safekey: self.event!.image!){ (imageData,error) in
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
                                self.eventImageView.image = image
                                self.eventImageView.contentMode = UIViewContentMode.ScaleAspectFit
                                let photoDict = [Photo.Keys.Blob : imageData, Photo.Keys.Controller : "events", Photo.Keys.TheType : "\(1)", Photo.Keys.SafeKey : self.event!.image!, Photo.Keys.ParentKey : self.event!.safekey!]
                                let photo = Photo.init(dictionary: photoDict, context: self.sharedContext)
                                self.event!.hasPhoto = photo
                                CoreDataStackManager.sharedInstance().saveContext()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func showLocation(){
        if self.event!.location != nil{
            let lat = self.event!.location!.lat!.doubleValue
            let lng = self.event!.location!.lng!.doubleValue
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
    }
    
    func checkEventMember(safekey: String) -> EventMember?{
        let request = NSFetchRequest(entityName: StudyPopClient.JSONReponseKeys.EventMember)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "safekey == %@", safekey)
        do{
            let results = try self.sharedContext.executeFetchRequest(request)
            if results.count > 0{
                let member = results[0] as? EventMember
                return member
            }
        } catch {
            let fetchError = error as NSError
            print("The error is \(fetchError.localizedDescription)")
        }
        return nil
    }
    
    // Send user to EventEditViewController
    func editClicked(sender: UIBarButtonItem){
        performSegueWithIdentifier(Constants.EventEditSegue, sender: nil)
    }
    
    
    // MARK: - Drop User from Event
    func dropClicked(sender: UIBarButtonItem){
        
    }
    
    
    // MARK: - Add User to Event
    func joinClicked(sender: UIBarButtonItem){
        
    }
    
    // MARK: - Delete Event
    func deleteClicked(sender: UIBarButtonItem){
        let refreshAlert = UIAlertController(title: Constants.DeleteTitle, message: "Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: Constants.DeleteTitle, style: .Default, handler: { (action: UIAlertAction!) in
            //Start Deleting...
            self.loadingView.startAnimating()
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventsController,
                StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.DeleteMethod,
                StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                StudyPopClient.ParameterKeys.SafeKey: self.safekey,
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
    
    /**
     Only use this if there is no connection
     
     Want to insure data integrity
     All users should have up to date versions as admins can change data at will
     and there may be more than one admin
     **/
    func findEventInDB() -> Event?{
        let request = NSFetchRequest(entityName: "Event")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "safekey == %@", event!.safekey!)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0{
                if let temp = results[0] as? Event{
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
    
    @IBAction func unwindToEventView(sender: UIStoryboardSegue){
       
    }
    
    // Allows users to view members of this event
    @IBAction func membersClicked(sender: UIButton) {
        
        if event!.ispublic!.intValue < 3{
            //This is a viewable event, so we can see the people attending
            performSegueWithIdentifier(Constants.EventMembersSegue, sender: nil)
        }else{
            //Private event
            if eventMember != nil{
                // This user is a member, so they can view the members
                performSegueWithIdentifier(Constants.EventMembersSegue, sender: nil)
            }else{
                self.simpleError("Sorry, but members are only visible to members of this event")
            }
        }
        
    }

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.EventEditSegue{
            if let evc = segue.destinationViewController as? EventEditViewController{
                evc.event = event!
                evc.user = user!
            }
        }else if segue.identifier == Constants.EventMembersSegue{
            if let emc = segue.destinationViewController as? EventMembersTableViewController{
                emc.event = event!
                emc.user = user!
            }
        }
    }
    

}
