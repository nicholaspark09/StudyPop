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

    
    
    
    /**
     Variables Section
     */
    // MARK: SharedContext
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    var user:User?
    var event:Event?
    var privateOptions = ["Public","Private (Searchable)","Private (Dark)"]
    var imagePicker: WDImagePicker!
    var photo:Photo?
    
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

 
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(EventEditProtocol.saveClicked(_:)))
        self.navigationItem.setRightBarButtonItem(saveButton, animated: true)
        title = event!.name!
        
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
                    self.startButton.setTitle(self.event!.end!.description, forState: .Normal)
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
                                let photoDict = [Photo.Keys.Blob : imageData, Photo.Keys.Controller : "events", Photo.Keys.TheType : "\(1)", Photo.Keys.SafeKey : self.event!.image!, Photo.Keys.ParentKey : self.event!.user!]
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
        let dict = [Photo.Keys.Name : "Event Pic", Photo.Keys.TheType: "\(1)", Photo.Keys.Controller : "events", Photo.Keys.ParentKey : self.event!.user!, Photo.Keys.Blob : bigData!]
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
            StudyPopClient.ParameterKeys.SafeKey : event!.user!
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
        request.predicate = NSPredicate(format: "user == %@", event!.user!)
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
    
    @IBAction func imageButtonClicked(sender: UIButton) {
        
        
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
