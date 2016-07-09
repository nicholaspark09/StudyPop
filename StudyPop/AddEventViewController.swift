//
//  AddEventViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/9/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol AddEventProtocol{
    func keyboardWillShow(sender: NSNotification)
    func keybaordWillHide(sender: NSNotification)
    func saveClicked(sender: UIBarButtonItem)
    func hideKeyboard()
}


class AddEventViewController: UIViewController, UIPopoverPresentationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    
    struct Constants{
        static let Controller = "AddEvent"
        static let PickSubjectSegue = "PickSubject Segue"
        static let PickCitySegue = "PickCity Segue"
        static let PickLocationSegue = "PickLocation Segue"
        static let PickDateSegue = "PickDate Segue"
        static let PickEndSegue = "PickEnd Segue"
        static let StartAction = "StartAction"
        static let EndAction = "EndAction"
        static let DeadlineAction = "DeadlineAction"
        static let SaveTitle = "Save"
        static let UnwindToGroupEventsSegue = "UnwindToGroupEvents Segue"
        static let PickDeadlineSegue = "PickDeadline Segue"
    }
    
    
    var user: User?
    var group:Group?
    var city:City?
    var subject:Subject?
    var location:Location?
    var startDate = ""
    var endDate = ""
    var deadlineDate = ""
    var safekey: String?
    var privateOptions = ["Public","Private (Searchable)","Private (Dark)"]
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    //IBOutlets
    @IBOutlet var startButton: UIButton!
    @IBOutlet var endButton: UIButton!
    @IBOutlet var deadlineButton: UIButton!
    @IBOutlet var priceTextField: UITextField!
    @IBOutlet var maxTextField: UITextField!
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var eventTitleTextField: UITextField!
    @IBOutlet var infoTextView: UITextView!
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
        
        
        if group?.city != nil {
            cityButton.setTitle(group!.city!.name!, forState: .Normal)
            city = group!.city
        }
        if group?.subject != nil{
            subjectButton.setTitle(group!.subject!.name!, forState: .Normal)
            subject = group!.subject
        }
        if group?.location != nil{
            location = group!.location!
            locationButton.setTitle("Map: \(group!.location!.lat!)", forState: .Normal)
            location = group!.location
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "SaveSmall"), style: .Plain, target: self, action: #selector(AddEventProtocol.saveClicked(_:)))
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(AddEventProtocol.hideKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(animated: Bool){
        
        super.viewWillAppear(animated)
    }
    
    // MARK: Notification Methods
    //Add an observer for the keyboard both on attachment and detachment
    func subscribeToKeyboardNotifications(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AddEventProtocol.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AddEventProtocol.keybaordWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeToKeyboardNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    /*
     KEYBOARD shtuff
     */
    
    func keyboardWillShow(sender: NSNotification){
        if priceTextField.isFirstResponder(){
            self.view.frame.origin.y -= getKeyboardHeight(sender)
        }
    }
    
    func keybaordWillHide(sender: NSNotification){
        if priceTextField.isFirstResponder(){
            self.view.frame.origin.y += getKeyboardHeight(sender)
        }
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }
    
    
    //Hide the keyboard
    func hideKeyboard(){
        view.endEditing(true)
    }
    
    
    // MARK: - Unwind To This Controller
    /*
        All the select options that lead to other controllers should come back here
     */
    @IBAction func unwindToAddGroupEvent(sender: UIStoryboardSegue){
        if let sourceViewController = sender.sourceViewController as? CityPickerViewController{
            if sourceViewController.currentCityKey != ""{
                let cityDict = [City.Keys.Name : sourceViewController.cityName, City.Keys.SafeKey : sourceViewController.currentCityKey]
                if let foundCity = self.findCityInDB(cityDict[City.Keys.SafeKey]!){
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
                let subjectDict = [Subject.Keys.Name : svc.subjectName, Subject.Keys.SafeKey : svc.subjectKey]
                if let foundSubject = self.findSubjectInDB(subjectDict[Subject.Keys.SafeKey]!){
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
        }else if let dvc = sender.sourceViewController as? PickDateViewController{
            print("You are here")
            print("The previous action is \(dvc.previousAction)")
            if dvc.previousAction == Constants.StartAction{
                startDate = dvc.currentDate!
                startButton.setTitle("Start: \(startDate)", forState: .Normal)
            }else if dvc.previousAction == Constants.EndAction{
                endDate = dvc.currentDate!
                endButton.setTitle("End: \(endDate)", forState: .Normal)
            }else{
                deadlineDate = dvc.currentDate!
                deadlineButton.setTitle("Deadline: \(deadlineDate)", forState: .Normal)
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
        }else if segue.identifier == Constants.PickDateSegue{
            if let pdc = segue.destinationViewController as? PickDateViewController{
                pdc.previousController = Constants.Controller
                pdc.previousAction = Constants.StartAction
                if let ppc = pdc.popoverPresentationController{
                    ppc.delegate = self
                }
            }
        }else if segue.identifier == Constants.PickEndSegue{
            if let pdc = segue.destinationViewController as? PickDateViewController{
                pdc.previousController = Constants.Controller
                pdc.previousAction = Constants.EndAction
                if let ppc = pdc.popoverPresentationController{
                    ppc.delegate = self
                }
            }
        }else if segue.identifier == Constants.PickDeadlineSegue{
            if let pdc = segue.destinationViewController as? PickDateViewController{
                pdc.previousController = Constants.Controller
                pdc.previousAction = Constants.DeadlineAction
                if let ppc = pdc.popoverPresentationController{
                    ppc.delegate = self
                }
            }
        }
    }
    
    /*
        PickerView Delegate Methods
 
     */
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return privateOptions.count;
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return privateOptions[row]
    }
    
    // MARK: - Save Event
    func saveClicked(sender: UIBarButtonItem){
       
        let title = eventTitleTextField.text!
        let info = infoTextView.text!
        let maxPeople = maxTextField.text!
        let isPublic = "\(pickerView.selectedRowInComponent(0)+1)"
        let price = priceTextField.text!
        if title.characters.count < 1{
            self.simpleError("Please put in a title")
            eventTitleTextField.becomeFirstResponder()
        }else if startDate == ""{
            self.simpleError("Please put in a start date")
        }else{
             sender.enabled = false
             var lat = ""
             var lng = ""
             var cityKey = ""
             var subjectKey = ""
            var latInfo = ""
            if location != nil{
                lat = "\(location!.lat!)"
                lng = "\(location!.lng!)"
                if location!.info != nil{
                    latInfo = location!.info!
                }
            }
            if city != nil{
                cityKey = city!.safekey!
            }
            if subject != nil{
                subjectKey = subject!.safekey!
            }
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventsController,
                          StudyPopClient.ParameterKeys.Method: "testadd",
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.Group : group!.safekey!,
                          Event.Keys.City : cityKey,
                          Event.Keys.Subject : subjectKey,
                          Location.Keys.Lat : lat,
                          Location.Keys.Lng : lng,
                          StudyPopClient.ParameterKeys.LatInfo : latInfo,
                          Event.Keys.Start : startDate,
                          Event.Keys.End : endDate
            ]
            let jsonBody = [Event.Keys.Name : title, Event.Keys.Info: info, Event.Keys.MaxPeople : maxPeople, Event.Keys.IsPublic : isPublic, Event.Keys.Price : price, Location.Keys.Lat : lat, Location.Keys.Lng : lng, Event.Keys.Start : startDate, Event.Keys.End : endDate, Event.Keys.Deadline : deadlineDate]
    
            StudyPopClient.sharedInstance.POST("", parameters: params, jsonBody: jsonBody){ (results,error) in
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
                
                self.safekey = results[StudyPopClient.JSONReponseKeys.SafeKey] as? String
                if self.safekey != nil{
                    performOnMain(){
                        self.performSegueWithIdentifier(Constants.UnwindToGroupEventsSegue, sender: nil)
                    }
                }
            }
            
            /*
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.AddMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.Group : group!.safekey!,
                          Event.Keys.Name: title,
                          Event.Keys.Info : info,
                          Event.Keys.MaxPeople : maxPeople,
                          Event.Keys.City : cityKey,
                          Event.Keys.Subject : subjectKey,
                          Event.Keys.IsPublic : isPublic,
                          Event.Keys.Price : price,
                          Location.Keys.Lat : lat,
                          Location.Keys.Lng : lng,
                          StudyPopClient.ParameterKeys.LatInfo : latInfo,
                          Event.Keys.Start : startDate,
                          Event.Keys.End : endDate
            ]
            print("You are saving it with a title \(title)")
            StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
                func sendError(error: String){
                    print("Error in transmission: \(error)")
                    self.simpleError(error)
                    performOnMain(){
                        sender.enabled = true
                    }
                }
                
                guard error == nil else{
                    sendError(error!.localizedDescription)
                    return
                }
                
                guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                    sendError("Weird formatting came back. Try again")
                    return
                }
                
                guard stat == StudyPopClient.JSONResponseValues.Success else{
                    sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                    return
                }
                
                self.safekey = results[StudyPopClient.JSONReponseKeys.SafeKey] as? String
                if self.safekey != nil{
                    performOnMain(){
                        self.performSegueWithIdentifier(Constants.UnwindToGroupEventsSegue, sender: nil)
                    }
                }
            }
 */
        }
    }

    // Obviously...Finding the Subject
    func findSubjectInDB(safekey: String) -> Subject?{
        let request = NSFetchRequest(entityName: "Subject")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "safekey == %@", safekey)
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
        request.predicate = NSPredicate(format: "safekey == %@", safekey)
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
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }

}
