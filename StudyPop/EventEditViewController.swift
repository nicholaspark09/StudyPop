//
//  EventEditViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/11/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol EventEditProtocol{
    func saveClicked(sender: UIBarButtonItem)
}


class EventEditViewController: UIViewController, WDImagePickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    struct Constants{
        static let Controller = "EventEdit"
        static let StartAction = "Start"
        static let EndAction = "End"
        static let StartDateSegue = "StartDate Segue"
        static let EndDateSegue = "EndDate Segue"
        static let PickSubjectSegue = "PickSubject Segue"
        static let PickCitySegue = "PickCity Segue"
        static let PickLocationSegue = "PickLocation Segue"
        static let UnwindToEventViewSegue = "UnwindToEventView Segue"
        static let DeadlineAction = "DeadlineAction"
        static let PickDeadlineSegue = "PickDeadline Segue"
    }
    
    
    /**
     Variables Section
     */
    // MARK: SharedContext
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    var user:User?
    var event:Event?
    var location:Location?
    var privateOptions = ["Public","Private (Searchable)","Private (Dark)"]
    var imagePicker: WDImagePicker!
    var photo:Photo?
    var startDate = ""
    var endDate = ""
    var deadlineDate = ""
    
    
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var infoTextView: UITextView!
    @IBOutlet var maxPeopleTextField: UITextField!
    @IBOutlet var isPublicPickerView: UIPickerView!
    @IBOutlet var priceTextField: UITextField!
    @IBOutlet var startButton: UIButton!
    @IBOutlet var endButton: UIButton!
    @IBOutlet var cityButton: UIButton!
    @IBOutlet var subjectButton: UIButton!
    @IBOutlet var locationButton: UIButton!
    @IBOutlet var eventImageView: UIImageView!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var deadlineButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

 
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(EventEditProtocol.saveClicked(_:)))
        self.navigationItem.setRightBarButtonItem(saveButton, animated: true)
        title = event!.name!
        location = event!.location!
        updateUI()
    }
    
    func updateUI(){
        performOnMain(){
            if self.event != nil{
                self.titleTextField.text = self.event!.name!
                if self.event!.info != nil{
                    self.infoTextView.text = self.event!.info!
                }
                if self.event!.maxpeople != nil{
                    self.maxPeopleTextField.text = "\(self.event!.maxpeople!.intValue)"
                }
                if self.event!.price != nil{
                    self.priceTextField.text = "\(self.event!.price!.floatValue)"
                }
                if self.event!.start != nil{
                    self.startButton.setTitle(self.event!.start!.description, forState: .Normal)
                }
                if self.event!.end != nil{
                    self.endButton.setTitle(self.event!.end!.description, forState: .Normal)
                }
                if self.event!.city != nil{
                    self.cityButton.setTitle(self.event!.city!.name!, forState: .Normal)
                }
                if self.event!.subject != nil{
                    self.subjectButton.setTitle(self.event!.subject!.name!, forState: .Normal)
                }
                if self.event!.location != nil{
                    self.locationButton.setTitle("Lat: \(self.event!.location!.lat!)", forState: .Normal)
                }
                if self.event!.ispublic != nil{
                    self.isPublicPickerView.selectRow(Int(self.event!.ispublic!.intValue), inComponent: 0, animated: true)
                }
                if self.event!.deadline != nil{
                    self.deadlineButton.setTitle(self.event!.deadline!.description, forState: .Normal)
                }
                //Check to see if there's an image on db first
                if self.event!.hasPhoto != nil && self.event!.hasPhoto!.safekey != nil{
                    self.eventImageView.image = self.event!.hasPhoto!.photoImage
                    self.eventImageView.contentMode = UIViewContentMode.ScaleAspectFit
                }else if self.event!.image != nil && self.event!.image != ""{
                    var found = false
                    // First check the local db, you never know!
                    var oldEvent = self.findEventInDB()
                    if oldEvent != nil{
                        if oldEvent!.hasPhoto != nil && oldEvent!.hasPhoto!.blob != nil{
                            //Load old image first so the user isn't bored
                            let image = UIImage(data: oldEvent!.hasPhoto!.blob!)
                            self.eventImageView.image = image
                            self.eventImageView.contentMode = UIViewContentMode.ScaleAspectFit
                            //Check to see if it's the same image
                            if oldEvent!.hasPhoto!.safekey == self.event!.image!{
                                found = true
                            }
                        }
                        oldEvent = nil
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
                                if let oldEvent = self.findEventInDB(){
                                    self.sharedContext.deleteObject(oldEvent)
                                }
                                CoreDataStackManager.sharedInstance().saveContext()
                            }
                        }
                    }
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
    
    
    func saveClicked(sender: UIBarButtonItem){
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        if startDate == "" && event!.start != nil{
            startDate = dateFormatter.stringFromDate(event!.start!)
        }
        if endDate == "" && event!.end != nil{
            endDate = dateFormatter.stringFromDate(event!.end!)
        }
        let title = titleTextField.text!
        let info = infoTextView.text!
        let maxPeople = maxPeopleTextField.text!
        let isPublic = "\(isPublicPickerView.selectedRowInComponent(0))"
        let price = priceTextField.text!
        if title.characters.count < 1{
            self.simpleError("Please put in a title")
            titleTextField.becomeFirstResponder()
        }else if startDate == ""{
            self.simpleError("Please put in a start date")
        }else{
            sender.enabled = false
            var lat = ""
            var lng = ""
            var cityKey = ""
            var subjectKey = ""
            var latInfo = ""
            var locationKey = ""
            if location != nil{
                lat = "\(location!.lat!)"
                lng = "\(location!.lng!)"
                if location!.info != nil{
                    latInfo = location!.info!
                }
                if location!.safekey != nil{
                    locationKey = location!.safekey!
                }
            }
            if event!.city != nil && event!.city!.safekey != nil{
                cityKey = event!.city!.safekey!
            }
            if event!.subject != nil && event!.subject!.safekey != nil{
                subjectKey = event!.subject!.safekey!
            }
            self.loadingView.startAnimating()
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.EditMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.SafeKey : event!.safekey!,
                          Event.Keys.City : cityKey,
                          Event.Keys.Subject : subjectKey,
                          Location.Keys.Lat : lat,
                          Location.Keys.Lng : lng,
                          StudyPopClient.ParameterKeys.LocationSafeKey : locationKey,
                          StudyPopClient.ParameterKeys.LatInfo : latInfo
            ]
            let jsonBody = [Event.Keys.Name : title, Event.Keys.Info: info, Event.Keys.MaxPeople : maxPeople, Event.Keys.IsPublic : isPublic, Event.Keys.Price : price, Location.Keys.Lat : lat, Location.Keys.Lng : lng, Event.Keys.Start : startDate, Event.Keys.End : endDate, Event.Keys.Deadline : deadlineDate]
            StudyPopClient.sharedInstance.POST("", parameters: params, jsonBody: jsonBody){ (results,error) in
                func sendError(error: String){
                    print("Error in transmission: \(error)")
                    self.simpleError(error)
                    performOnMain(){
                        sender.enabled = true
                        self.loadingView.stopAnimating()
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

                    performOnMain(){
                        self.loadingView.stopAnimating()
                        sender.enabled = true
                        self.performSegueWithIdentifier(Constants.UnwindToEventViewSegue, sender: nil)
                    }
            }
        }
    }
    
    // MARK: - Unwind To This Controller
    /*
     All the select options that lead to other controllers should come back here
     */
    @IBAction func unwindToAddEventEdit(sender: UIStoryboardSegue){
        if let sourceViewController = sender.sourceViewController as? CityPickerViewController{
            if sourceViewController.currentCityKey != ""{
                let cityDict = [City.Keys.Name : sourceViewController.cityName, City.Keys.SafeKey : sourceViewController.currentCityKey]
                if let foundCity = self.findCityInDB(cityDict[City.Keys.SafeKey]!){
                    //City was found
                    event!.city = foundCity
                }else{
                    event!.city = City.init(dictionary: cityDict, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                cityButton.setTitle(event!.city!.name!, forState: .Normal)
            }else{
                cityButton.setTitle("No City", forState: .Normal)
            }
        }else if let svc = sender.sourceViewController as? StudyPickerViewController{
            if svc.subjectKey != ""{
                let subjectDict = [Subject.Keys.Name : svc.subjectName, Subject.Keys.SafeKey : svc.subjectKey]
                if let foundSubject = self.findSubjectInDB(subjectDict[Subject.Keys.SafeKey]!){
                    event!.subject = foundSubject
                }else{
                    event!.subject = Subject.init(dictionary: subjectDict, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                subjectButton.setTitle(event!.subject!.name!, forState: .Normal)
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
            if dvc.previousAction == Constants.StartAction{
                startDate = dvc.currentDate!
                startButton.setTitle("Start: \(dvc.currentDate!)", forState: .Normal)
            }else if dvc.previousAction == Constants.EndAction{
                endDate = dvc.currentDate!
                endButton.setTitle("End: \(endDate)", forState: .Normal)
            }else{
                deadlineDate = dvc.currentDate!
                deadlineButton.setTitle(deadlineDate, forState: .Normal)
            }
        }
    }
    
    //Image Picker
    //MARK: -WDImagePicker Delegates
    
    // MARK: - ImagePicker with Crop
    @IBAction func picImageClicked(sender: AnyObject) {
        self.imagePicker = WDImagePicker()
        self.imagePicker.cropSize = CGSizeMake(300, 300)
        self.imagePicker.delegate = self
        self.presentViewController(self.imagePicker.imagePickerController, animated: true, completion: nil)
    }
    
    
    // Got the image back
    func imagePicker(imagePicker: WDImagePicker, pickedImage: UIImage) {
        self.hideImagePicker()
        let compressionQuailty = 0.85
        let scaledBig = resizeImage(pickedImage, newWidth: 400)
        let bigData = UIImageJPEGRepresentation(scaledBig, CGFloat(compressionQuailty))
        let dict = [Photo.Keys.Name : "Event Pic", Photo.Keys.TheType: "\(1)", Photo.Keys.Controller : "events", Photo.Keys.ParentKey : self.event!.safekey!, Photo.Keys.Blob : bigData!]
        self.photo = Photo.init(dictionary: dict, context: self.sharedContext)
        self.eventImageView.image = pickedImage
        let bigImage = bigData!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        self.uploadImage(bigImage)
    }
    
    // MARK: UploadGroupImage
    func uploadImage(bigImage: String){
        print("This is happening")
        let params = [
            StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventsController,
            StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.ProfileAdd,
            StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
            StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
            StudyPopClient.ParameterKeys.Token : user!.token!,
            StudyPopClient.ParameterKeys.SafeKey : event!.safekey!
        ]
        let tempDict = [StudyPopClient.ParameterKeys.Body:bigImage]
        self.loadingView.startAnimating()
        StudyPopClient.sharedInstance.POST("", parameters: params, jsonBody: tempDict){ (results,error) in
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
            
            if let safekey = results[StudyPopClient.JSONReponseKeys.SafeKey] as? String{
                performOnMain(){
                    self.photo!.safekey = safekey
                    self.loadingView.stopAnimating()
                    self.event!.image = safekey
                    self.event!.hasPhoto = self.photo!
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
            
        }
    }
    
    func hideImagePicker() {
        
        self.imagePicker.imagePickerController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.eventImageView.image = image
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func resizeImage(image:UIImage, newWidth: CGFloat) -> UIImage{
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
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
    


    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.StartDateSegue{
            if let pvc = segue.destinationViewController as? PickDateViewController{
                pvc.previousController = Constants.Controller
                pvc.previousAction = Constants.StartAction
            }
        }else if segue.identifier == Constants.EndDateSegue{
            if let pvc = segue.destinationViewController as? PickDateViewController{
                pvc.previousController = Constants.Controller
                pvc.previousAction = Constants.EndAction
            }
        }else if segue.identifier == Constants.PickDeadlineSegue{
            if let pvc = segue.destinationViewController as? PickDateViewController{
                pvc.previousController = Constants.Controller
                pvc.previousAction = Constants.DeadlineAction
            }
        }else if segue.identifier == Constants.PickSubjectSegue{
            if let svc = segue.destinationViewController as? StudyPickerViewController{
                svc.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.PickCitySegue{
            if let pvc = segue.destinationViewController as? CityPickerViewController{
                pvc.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.PickLocationSegue{
            if let plc = segue.destinationViewController.contentViewController as? LocationPickViewController{
                plc.controller = Constants.Controller
                if location != nil{
                    plc.location = location
                }
            }
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

}
