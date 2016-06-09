//
//  AddEventViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/9/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData


class AddEventViewController: UIViewController {

    
    struct Constants{
        static let Controller = "AddEvent"
        static let PickSubjectSegue = "PickSubject Segue"
        static let PickCitySegue = "PickCity Segue"
        static let PickLocationSegue = "PickLocation Segue"
    }
    
    
    var user: User?
    var group:Group?
    var city:City?
    var subject:Subject?
    var location:Location?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    //IBOutlets
    
    @IBOutlet var cityButton: UIButton!{
        didSet{
            cityButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        }
    }
    @IBOutlet var subjectButton: UIButton!{
        didSet{
            subjectButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        }
    }
    @IBOutlet var locationButton: UIButton!{
        didSet{
            locationButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Event: \(group!.name!)"
        
        
        if group?.hasCity != nil && group?.hasCity!.user != ""{
            cityButton.setTitle(group!.hasCity!.name!, forState: .Normal)
        }
        if group?.hasSubject != nil && group?.hasSubject!.user != ""{
            subjectButton.setTitle(group!.hasSubject!.name!, forState: .Normal)
        }
        if group?.hasLocation != nil && group?.hasLocation!.user != ""{
            location = group!.hasLocation!
            locationButton.setTitle("Map: \(group!.hasLocation!.lat!)", forState: .Normal)
        }
    }
    
    
    @IBAction func unwindToAddGroupEvent(sender: UIStoryboardSegue){
        if let sourceViewController = sender.sourceViewController as? CityPickerViewController{
            if sourceViewController.currentCityKey != ""{
                let cityDict = [City.Keys.Name : sourceViewController.cityName, City.Keys.User : sourceViewController.currentCityKey]
                if let foundCity = self.findCityInDB(cityDict[City.Keys.User]!){
                    //City was found
                    self.city = foundCity
                }else{
                    self.city = City.init(dictionary: cityDict, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                cityButton.setTitle(city!.name!, forState: .Normal)
            }else{
                cityButton.setTitle("No City", forState: .Normal)
            }
        }else if let svc = sender.sourceViewController as? StudyPickerViewController{
            if svc.subjectKey != ""{
                let subjectDict = [Subject.Keys.Name : svc.subjectName, Subject.Keys.User : svc.subjectKey]
                if let foundSubject = self.findSubjectInDB(subjectDict[Subject.Keys.User]!){
                    self.subject = foundSubject
                }else{
                    self.subject = Subject.init(dictionary: subjectDict, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                subjectButton.setTitle(subject!.name!, forState: .Normal)
            }else{
                subjectButton.setTitle("No Subject", forState: .Normal)
            }
        }else if let lvc = sender.sourceViewController as? LocationPickViewController{
            if lvc.location != nil{
                location = lvc.location
                let mapText = "Map Set: \(location!.lat!)"
                locationButton.setTitle(mapText, forState: .Normal)
                
            }else{
                locationButton.setTitle("Location", forState: .Normal)
            }
        }
    }
    

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.PickSubjectSegue{
            if let spc = segue.destinationViewController as? StudyPickerViewController{
                spc.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.PickCitySegue{
            if let cvc = segue.destinationViewController as? CityPickerViewController{
                cvc.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.PickLocationSegue{
            if let plc = segue.destinationViewController.contentViewController as? LocationPickViewController{
                plc.controller = Constants.Controller
                if location != nil{
                    plc.location = location!
                }
            }
        }
    }
    
    // Obviously...Finding the Subject
    func findSubjectInDB(safekey: String) -> Subject?{
        let request = NSFetchRequest(entityName: "Subject")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "user == %@", safekey)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0 {
                let subject = results[0] as? Subject
                return subject
            }
        } catch {
            let fetchError = error as NSError
            print("The Error was \(fetchError)")
            return nil
        }
        return nil
    }
    
    // Obviously...Finding the City
    func findCityInDB(safekey: String) -> City?{
        let request = NSFetchRequest(entityName: "City")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "user == %@", safekey)
        do{
            let results = try self.sharedContext.executeFetchRequest(request)
            if results.count > 0 {
                let city = results[0] as? City
                return city
            }
        } catch {
            let fetchError = error as NSError
            print("The Error was \(fetchError)")
            return nil
        }
        return nil
    }

}
