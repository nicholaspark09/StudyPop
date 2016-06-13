//
//  LocationPickViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/31/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationPickViewController: UIViewController, MKMapViewDelegate {

    
    /**
        Local Constants
    **/
    struct Constants{
        static let PinReuseIdentifier = "Pin"
        static let UnwindToAddSegue = "UnwindToAdd Segue"
        static let UnwindToEditSegue = "UnwindToEdit Segue"
        static let UnwindToAddGroupEventSegue = "UnwindToAddGroupEvent Segue"
        static let UnwindToEventEditSegue = "UnwindToEventEdit Segue"
    }
    
    /**
        Local Variables
    **/
    var controller = ""
    var info = ""
    var location: Location?
    var annotation: MKAnnotation?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    @IBOutlet var mapView: MKMapView!{
        didSet{
            mapView!.delegate = self
        }
    }
    
    @IBOutlet var saveButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.showsUserLocation = true
        if location != nil && location!.lat! != 0{
            print("The location center is  \(location!.lat!)")
            let lat = self.location!.lat!.doubleValue
            let lng = self.location!.lng!.doubleValue
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let currentAnnotation = MKPointAnnotation()
            currentAnnotation.coordinate = coordinate
            annotation = currentAnnotation
            mapView.addAnnotation(annotation!)
            
            //Zoom in on point
            var region = MKCoordinateRegion()
            var span = MKCoordinateSpan()
            span.latitudeDelta = 0.01
            span.longitudeDelta = 0.01
            region.span = span
            region.center = coordinate
            mapView.setRegion(region, animated: true)
            mapView.regionThatFits(region)
        }
    }
    
    func zoomInOnUser(){
        let userLocation = mapView.userLocation
        
        let region = MKCoordinateRegionMakeWithDistance(userLocation.location!.coordinate, 2000, 2000)
        mapView.setRegion(region, animated: true)
    }
    

    @IBAction func cancelClicked(sender: AnyObject) {
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func mapHeld(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Ended{
            let point = sender.locationOfTouch(0,inView: mapView)
            let coordinate = mapView.convertPoint(point, toCoordinateFromView: mapView)
            let currentAnnotation = MKPointAnnotation()
            currentAnnotation.coordinate = coordinate
            if annotation != nil{
                mapView.removeAnnotation(annotation!)
            }
            annotation = currentAnnotation
            mapView.addAnnotation(annotation!)
            let tempLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            self.saveButton.enabled = false
            CLGeocoder().reverseGeocodeLocation(tempLocation){ (placemarks,error) in
                performOnMain(){
                    self.saveButton.enabled = true
                }
                if error != nil{
                    self.simpleError("No location found")
                }else{
                    if placemarks!.count > 0{
                            self.info = "\(placemarks![0].locality),\(placemarks![0].country!)"
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
    
    //Draggable pin
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        switch (newState) {
            case .Starting:
                view.dragState = .Dragging
            case .Ending, .Canceling:
                view.dragState = .None
            default: break
        }
    }
    
    
    @IBAction func saveClicked(sender: AnyObject) {
        if annotation != nil{
            let temp = [
                Location.Keys.Lat: annotation!.coordinate.latitude,
                Location.Keys.Lng: annotation!.coordinate.longitude,
            ]
            location = Location.init(dictionary: temp, context: sharedContext)
            location!.info = self.info
            if controller == AddGroupViewController.Constants.Controller{
                performSegueWithIdentifier(Constants.UnwindToAddSegue, sender: nil)
            }else if controller == GroupEditViewController.Constants.Controller{
                performSegueWithIdentifier(Constants.UnwindToEditSegue, sender: nil)
            }else if controller == AddEventViewController.Constants.Controller{
                performSegueWithIdentifier(Constants.UnwindToAddGroupEventSegue, sender: nil)
            }else if controller == EventEditViewController.Constants.Controller{
                performSegueWithIdentifier(Constants.UnwindToEventEditSegue, sender: nil)
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
