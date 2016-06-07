//
//  GroupEditViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/4/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol GroupEditProtocol{
    func saveClicked(sender: AnyObject)
}


class GroupEditViewController: UIViewController, WDImagePickerDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    
    struct Constants{
        static let Title = "Edit"
        static let SaveTitle = "Save"
        static let Controller = "GroupEdit"
        static let CityPickSegue = "CityPick Segue"
        static let LocationPickSegue = "LocationPick Segue"
        static let UnwindToView = "UnwindToGroup Segue"
        static let SubjectPickSegue = "SubjectPick Segue"
    }
    
    /**
     Variables Section
     */
    // MARK: SharedContext
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    var group: Group?
    var user:User?
    var city: City?
    var location: Location?
    var currentSubject = ""
    var currentSubjectKey = ""
    var imagePicker: WDImagePicker!
    var privateOptions = ["Public","Private (Searchable)","Private (Dark)"]
    var photo:Photo?
 
    @IBOutlet var groupImageView: UIImageView!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var infoTextView: UITextView!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Constants.Title
        nameTextField.text = group!.name!
        infoTextView.text = group!.info!
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: Constants.SaveTitle, style: .Plain, target: self, action: #selector(GroupEditProtocol.saveClicked(_:)))
        
        if group!.hasCity != nil{
            self.cityLabel.text = group!.hasCity!.name!
        }
        
        if group!.hasSubject != nil{
            self.subjectLabel.text = group!.hasSubject!.name!
        }
        
        if group!.hasLocation != nil{
            self.locationLabel.text = "Map Lat: \(group!.hasLocation!.lat!)"
        }
        
        if group!.hasProfilePhoto != nil{
            self.groupImageView.image = group!.hasProfilePhoto!.photoImage!
            self.groupImageView.contentMode = UIViewContentMode.ScaleAspectFit
        }
    }

    
    func saveClicked(sender: AnyObject){
        if let button = sender as? UIBarButtonItem{
            button.enabled = false
            
            let name = nameTextField.text!
            if name.characters.count < 1 {
                simpleError("Please enter in a title")
                nameTextField.becomeFirstResponder()
            }else{
                let info = infoTextView.text!
                print("The user token is \(user!.token!)")
                var cityKey = ""
                var subjectKey = ""
                if group!.hasCity != nil{
                    cityKey = group!.hasCity!.user!
                }
                if group!.hasSubject != nil{
                    subjectKey = group!.hasSubject!.user!
                }
                let privateOption = pickerView.selectedRowInComponent(0)+1
                var lat = ""
                var lng = ""
                if group!.hasLocation != nil{
                    lat = "\(group!.hasLocation!.lat!)"
                    lng = "\(group!.hasLocation!.lng!)"
                }
                let params = [
                    StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupsController,
                    StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.EditMethod,
                    StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                    StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                    StudyPopClient.ParameterKeys.Token : user!.token!,
                    StudyPopClient.ParameterKeys.SafeKey : group!.user!,
                    Group.Keys.Name: name,
                    Group.Keys.Info: info,
                    Group.Keys.City: cityKey,
                    Group.Keys.Subject: subjectKey,
                    StudyPopClient.ParameterKeys.IsPublic: "\(privateOption)",
                    StudyPopClient.ParameterKeys.People : "\(100000)",
                    StudyPopClient.ParameterKeys.Lat :lat,
                    StudyPopClient.ParameterKeys.Lng :lng
                ]
                loadingView.startAnimating()
                StudyPopClient.sharedInstance.httpPost("", parameters: params, jsonBody: ""){ (results,error) in
                    func sendError(error: String){
                        print("Error in transmission: \(error)")
                        self.simpleError(error)
                        performOnMain(){
                            button.enabled = true
                            self.loadingView.stopAnimating()
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
                    
                    if let safekey = results[StudyPopClient.JSONReponseKeys.SafeKey] as? String{
                        let locationKey = results[StudyPopClient.JSONReponseKeys.LocationKey] as! String
                
                        performOnMain(){
                            self.loadingView.stopAnimating()
                            if self.group!.hasLocation != nil && locationKey != ""{
                                self.group!.hasLocation!.safekey = locationKey
                            }
                            self.group!.user = safekey
                            CoreDataStackManager.sharedInstance().saveContext()
                            self.performSegueWithIdentifier(Constants.UnwindToView, sender: nil)
                        }
                    }
                }
            }
            
        }
    }

    
    
    // MARK: - Unwind From other Segues to Here
    @IBAction func unwindToEdit(sender: UIStoryboardSegue){
        print("this is happening")
        if let sourceViewController = sender.sourceViewController as? CityPickerViewController{
            if sourceViewController.currentCityKey != ""{
                print("The city name is \(sourceViewController.cityName)")
                let cityDict = [City.Keys.Name : sourceViewController.cityName, City.Keys.User : sourceViewController.currentCityKey]
                if let foundCity = self.findCityInDB(cityDict[City.Keys.User]!){
                    //City was found
                    self.group!.hasCity = foundCity
                }else{
                    self.city = City.init(dictionary: cityDict, context: self.sharedContext)
                    self.group!.hasCity = self.city!
                }
                
            }
            if self.group!.hasCity != nil{
                cityLabel.text = self.group!.hasCity!.name!
            }
        }else if let svc = sender.sourceViewController as? StudyPickerViewController{
            
            if svc.subjectKey != ""{
                let subjectDict = [Subject.Keys.Name : svc.subjectName, Subject.Keys.User : svc.subjectKey]
                if let foundSubject = self.findSubjectInDB(subjectDict[Subject.Keys.User]!){
                    self.group!.hasSubject = foundSubject
                }else{
                    let subject = Subject.init(dictionary: subjectDict, context: self.sharedContext)
                    self.group!.hasSubject = subject
                }
            }
            if self.group!.hasSubject != nil{
                subjectLabel.text = self.group!.hasSubject!.name!
            }
        }else if let lvc = sender.sourceViewController as? LocationPickViewController{
            if lvc.location != nil{
                group!.hasLocation = lvc.location
                locationLabel.text = "Map Set: \(group!.hasLocation!.lat!)"
            }
        }
        CoreDataStackManager.sharedInstance().saveContext()
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
         let compressionQuailty = 0.7
         let scaledBig = resizeImage(pickedImage, newWidth: 250)
         let bigData = UIImageJPEGRepresentation(scaledBig, CGFloat(compressionQuailty))
         let dict = [Photo.Keys.Name : "Group Pic", Photo.Keys.TheType: "\(1)", Photo.Keys.Controller : "groups", Photo.Keys.ParentKey : self.group!.user!, Photo.Keys.Blob : bigData!]
         self.photo = Photo.init(dictionary: dict, context: self.sharedContext)
         self.groupImageView.image = pickedImage
         let bigImage = bigData!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
         self.uploadImage(bigImage)
     }
    
    // MARK: UploadGroupImage
    func uploadImage(bigImage: String){
        print("This is happening")
        let params = [
            StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupsController,
            StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.ProfileAdd,
            StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
            StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
            StudyPopClient.ParameterKeys.Token : user!.token!,
            StudyPopClient.ParameterKeys.SafeKey : group!.user!
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
                    self.group!.image = safekey
                    self.group!.hasProfilePhoto = self.photo!
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
            
        }
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
    
    // Obviously...Finding the Location
    func findLocationInDB(safekey: String) -> Location?{
        let request = NSFetchRequest(entityName: "Location")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "safekey == %@", safekey)
        do{
            let results = try self.sharedContext.executeFetchRequest(request)
            if results.count > 0 {
                let city = results[0] as? Location
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

 
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.CityPickSegue{
            if let cpc = segue.destinationViewController as? CityPickerViewController{
                cpc.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.LocationPickSegue{
            if let lvc = segue.destinationViewController.contentViewController as? LocationPickViewController{
                lvc.controller = Constants.Controller
                if group!.hasLocation != nil{
                    lvc.location = group!.hasLocation
                }
            }
        }else if segue.identifier == Constants.SubjectPickSegue{
            if let svc = segue.destinationViewController as? StudyPickerViewController{
                svc.previousController = Constants.Controller
            }
        }
    }

}
