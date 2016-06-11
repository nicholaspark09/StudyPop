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
                self.event!.user = self.safekey

            
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

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.EventEditSegue{
            if let evc = segue.destinationViewController as? EventEditViewController{
                evc.event = event!
                evc.user = user!
            }
        }
    }
    

}
