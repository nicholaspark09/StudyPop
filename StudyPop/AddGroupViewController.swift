//
//  AddGroupViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/31/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class AddGroupViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    struct Constants{
        static let AlertTitle = "Confirm"
        static let AlertMessage = "Are you sure you want to exit?"
        static let AlertClose = "Close"
        static let AlertDont = "Don't Close"
        static let PickCitySegue = "PickCity Segue"
        static let SubjectPickSegue = "SubjectPick Segue"
        static let Controller = "AddGroup"
        static let UnwindSegue = "UnwindAfterAdded Segue"
        static let AddLocationSegue = "AddLocation Segue"
        
    }
    
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var groupImageView: UIImageView!
    @IBOutlet var groupTextView: UITextView!
    @IBOutlet var nameTextField: UITextField!{
        didSet{
            nameTextField.delegate = self
        }
    }
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    var currentCityKey = ""
    var currentCityName = ""
    var currentSubject = ""
    var currentSubjectKey = ""
    var bigImage = ""
    var smallImage = ""
    var user: User?
    var location: Location?
    var safekey = ""
    var city: City?
    var subject: Subject?
    var group:Group?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    var privateOptions = ["Public","Private (Searchable)","Private (Dark)"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        (currentCityName, currentCityKey) = appDelegate.getCity()
        (currentSubject, currentSubjectKey) = appDelegate.getSubject()
        if currentCityKey != ""{
            cityLabel.text = currentCityName
        }
        if currentSubjectKey != ""{
            subjectLabel.text = currentSubject
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        
        let cancelAlert = UIAlertController(title: Constants.AlertTitle, message: Constants.AlertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        
        cancelAlert.addAction(UIAlertAction(title: Constants.AlertClose, style: .Default, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        cancelAlert.addAction(UIAlertAction(title: Constants.AlertDont, style: .Cancel, handler:nil))
        
        presentViewController(cancelAlert, animated: true, completion: nil)
        
    }
    
    // MARK: - Unwind From other Segues to Here
    @IBAction func unwindToAdd(sender: UIStoryboardSegue){
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
                cityLabel.text = self.city!.name!
            }else{
                cityLabel.text = "No City"
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
                subjectLabel.text = self.subject!.name!
            }else{
                subjectLabel.text = "No Subject"
            }
        }else if let lvc = sender.sourceViewController as? LocationPickViewController{
            if lvc.location != nil{
                location = lvc.location
                locationLabel.text = "Map Set: \(location!.lat!)"
            }else{
                locationLabel.text = "No location"
            }
        }
   
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        groupTextView.becomeFirstResponder()
        return true
    }
 
        /* Image Picker
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
        self.groupImageView.image = pickedImage
        let imageData = UIImagePNGRepresentation(pickedImage)
        bigImage = imageData!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        //Create a thumb
        let smallThumb = resizeImage(pickedImage, newWidth: 100)
        let data = UIImagePNGRepresentation(smallThumb)
        smallImage = data!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        self.hideImagePicker()
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
    
    
    
    func hideImagePicker() {
       
            self.imagePicker.imagePickerController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.groupImageView.image = image
            picker.dismissViewControllerAnimated(true, completion: nil)
    }
 */
    
    // MARK: - AddGroupMethod
    /**
        Send and save it
            - The save button should be disabled at this time
    **/
    
    @IBAction func saveClicked(sender: UIBarButtonItem) {
        
        let name = nameTextField.text!
        if name.characters.count < 1 {
            simpleError("Please enter in a title")
            nameTextField.becomeFirstResponder()
        }else{
            sender.enabled = false
            let info = groupTextView.text!
            print("The user token is \(user!.token!)")
            var cityKey = ""
            var subjectKey = ""
            if city != nil{
                cityKey = city!.safekey!
            }
            if subject != nil{
                subjectKey = subject!.safekey!
            }
            var lat = 0.0
            var lng = 0.0
            var locInfo = ""
            if location != nil{
                lat = location!.lat!.doubleValue
                lng = location!.lng!.doubleValue
                if location!.info != nil{
                    locInfo = location!.info!
                }
            }
            let privateOption = pickerView.selectedRowInComponent(0)+1
            let params = [
                StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupsController,
                StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.AddMethod,
                StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                StudyPopClient.ParameterKeys.Token : user!.token!,
                Group.Keys.Name: name,
                Group.Keys.Info: info,
                Group.Keys.City: cityKey,
                Group.Keys.Subject: subjectKey,
                StudyPopClient.ParameterKeys.IsPublic: "\(privateOption)",
                StudyPopClient.ParameterKeys.People : "\(100000)",
                StudyPopClient.ParameterKeys.Lat : "\(lat)",
                StudyPopClient.ParameterKeys.Lng : "\(lng)",
                StudyPopClient.ParameterKeys.LatInfo : locInfo
            ]
            StudyPopClient.sharedInstance.httpPost("", parameters: params, jsonBody: ""){ (results,error) in
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
                
                guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                    sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                    return
                }
                
                self.safekey = results[StudyPopClient.JSONReponseKeys.SafeKey] as! String
                
                let groupDict = [Group.Keys.Name: name, Group.Keys.Info: info, Group.Keys.City: cityKey, Group.Keys.Subject: subjectKey, Group.Keys.SafeKey: self.safekey]
                
                self.group = Group.init(dictionary: groupDict, context: self.sharedContext)
                performOnMain(){
                    if self.subject != nil{
                        self.group!.subject = self.subject!
                    }
                    if self.city != nil{
                        self.group!.city = self.city!
                    }
                    if self.location != nil{
                        self.group!.location = self.location!
                    }
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.performSegueWithIdentifier(Constants.UnwindSegue, sender: nil)
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
    
    
    // MARK: - UIPickerView Delegate Methods
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int{
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return privateOptions.count
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return privateOptions[row]
    }
    

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.PickCitySegue{
            if let pvc = segue.destinationViewController as? CityPickerViewController{
                pvc.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.SubjectPickSegue{
            if let svc = segue.destinationViewController as? StudyPickerViewController{
                svc.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.AddLocationSegue{
            if let lvc = segue.destinationViewController.contentViewController as? LocationPickViewController{
                lvc.controller = Constants.Controller
                if location != nil{
                    lvc.location = location!
                }
            }
        }
    }


}
