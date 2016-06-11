//
//  EditProfileViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/6/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class EditProfileViewController: UIViewController, WDImagePickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    struct Constants{
        static let Controller = "EditProfile"
        static let SubjectPickSegue = "SubjectPick Segue"
        static let CityPickSegue = "CityPick Segue"
    }

    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var infoTextView: UITextView!
    @IBOutlet var subjectButton: UIButton!
    @IBOutlet var cityButton: UIButton!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    var user:User?
    var profile:Profile?
    var imagePicker: WDImagePicker!
    var photo:Photo?
    var subject:Subject?
    var city:City?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = profile!.name!
        nameTextField.text = profile!.name!
        infoTextView.text = profile!.info!
        if profile!.hasPhoto != nil{
            profileImageView.image = profile!.hasPhoto!.photoImage
            profileImageView.contentMode = UIViewContentMode.ScaleAspectFit
        }
        
        if subject == nil{
            subjectButton.setTitle("No Subject", forState: .Normal)
        }else{
           subjectButton.setTitle(subject!.name!, forState: .Normal)
        }
        if city == nil{
            cityButton.setTitle("No City", forState: .Normal)
        }else{
            cityButton.setTitle(city!.name!, forState: .Normal)
        }
    }

    
    // MARK: ImagePicker Delegate Methods
    @IBAction func profileImageViewClicked(sender: UIButton) {
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
        let dict = [Photo.Keys.Name : "Profile Pic", Photo.Keys.TheType: "\(1)", Photo.Keys.Controller : "profiles", Photo.Keys.ParentKey : self.profile!.safekey!, Photo.Keys.Blob : bigData!]
        self.photo = Photo.init(dictionary: dict, context: self.sharedContext)
        self.profileImageView.image = pickedImage
        let bigImage = bigData!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        uploadImage(bigImage)
    }
    
    // MARK: UploadGroupImage
    func uploadImage(bigImage: String){
        print("This is happening")
        let params = [
            StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.PicsController,
            StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.ProfileAdd,
            StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
            StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
            StudyPopClient.ParameterKeys.Token : user!.token!,
            StudyPopClient.ParameterKeys.SafeKey : profile!.safekey!
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
                    self.profile!.image = safekey
                    self.profile!.hasPhoto = self.photo!
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
        self.profileImageView.image = image
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /**
                End Image Picker Methods
     **/
    
    
    @IBAction func cancelClicked(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Unwind Segues come here!
    @IBAction func unwindToEditProfile(sender: UIStoryboardSegue){
        if let sourceViewController = sender.sourceViewController as? CityPickerViewController{
            if sourceViewController.currentCityKey != ""{
                let cityDict = [City.Keys.Name : sourceViewController.cityName, City.Keys.SafeKey : sourceViewController.currentCityKey]
                if let foundCity = StudyPopClient.sharedInstance.findCityInDB(cityDict[City.Keys.SafeKey]!, sharedContext: self.sharedContext){
                    //City was found
                    self.city = foundCity
                }else{
                    self.city = City.init(dictionary: cityDict, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                self.cityButton.setTitle(self.city!.name!, forState: .Normal)
            }else{
                self.cityButton.setTitle("No City", forState: .Normal)
            }
        }else if let svc = sender.sourceViewController as? StudyPickerViewController{
            if svc.subjectKey != ""{
                print("You are in this method")
                let subjectDict = [Subject.Keys.Name : svc.subjectName, Subject.Keys.SafeKey : svc.subjectKey]
                
                if let foundSubject = StudyPopClient.sharedInstance.findSubjectInDB(subjectDict[Subject.Keys.SafeKey]!, sharedContext: self.sharedContext){
                    self.subject = foundSubject
                }else{
                    self.subject = Subject.init(dictionary: subjectDict, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                print("This should be updating")
                self.subjectButton.setTitle(self.subject!.name!, forState: .Normal)
            }else{
                print("Or this....")
                self.subjectButton.setTitle("No Subject", forState: .Normal)
            }
        }
    }
    
    // MARK: - SaveProfileMethod
    @IBAction func saveClicked(sender: UIBarButtonItem) {
        saveButton.enabled = false
        let name = nameTextField.text!
        if name.characters.count < 1{
            self.simpleError("Please enter in a name")
            nameTextField.becomeFirstResponder()
        }else{
            var cityKey = ""
            var subjectKey = ""
            if self.city != nil{
                cityKey = self.city!.safekey!
            }
            if self.subject != nil{
                subjectKey = self.subject!.safekey!
            }
            let params = [
                StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.ProfilesController,
                StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.EditMethod,
                StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                StudyPopClient.ParameterKeys.Token : user!.token!,
                StudyPopClient.ParameterKeys.SafeKey : profile!.safekey!,
                Profile.Keys.Name : name,
                Profile.Keys.Info : infoTextView.text!,
                Profile.Keys.City : cityKey,
                Profile.Keys.Subject : subjectKey
            ]
            self.loadingView.startAnimating()
            StudyPopClient.sharedInstance.httpGet("", parameters: params){(results,error) in
                func sendError(error: String){
                    performOnMain(){
                        self.loadingView.stopAnimating()
                        self.saveButton.enabled = true
                    }
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
                
                //Everything has been saved
                performOnMain(){
                    self.loadingView.stopAnimating()
                    self.saveButton.enabled = true
                }
            }
        }
    }
    
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.SubjectPickSegue{
            if let spc = segue.destinationViewController as? StudyPickerViewController{
                spc.previousController = Constants.Controller
            }
        }else if segue.identifier == Constants.CityPickSegue{
            if let cpc = segue.destinationViewController as? CityPickerViewController{
                cpc.previousController = Constants.Controller
            }
        }
    }

}
