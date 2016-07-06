//
//  LocationViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/6/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import MapKit

class LocationViewController: UIViewController, MKMapViewDelegate {

    struct Constants{
        static let PinReuseIdentifier = "Pin"
    }
    
    
    var event:Event?
    
    
    
    @IBOutlet var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Map of Event"
        if event!.location != nil{
            showLocation()
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
