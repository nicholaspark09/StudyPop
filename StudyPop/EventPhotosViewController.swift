//
//  EventPhotosViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/29/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class EventPhotosViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, WDImagePickerDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    struct Constants{
        static let Controller = "events"
        static let TheType = "\(2)"
        static let CellReuseIdentifier = "EventThumb Cell"
        static let ViewPicSegue = "ViewPic Segue"
    }
    
    var user:User?
    var event:Event?
    var thumbs = [Thumb]()
    var loading = false
    var canLoadMore = true
    var imagePicker: WDImagePicker!
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var collectionViewFlow: UICollectionViewFlowLayout!{
        didSet{
            collectionViewFlow!.minimumInteritemSpacing = 0
            collectionViewFlow!.minimumLineSpacing = 0
        }
    }
    @IBOutlet var collectionView: UICollectionView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        indexThumbs()
    }

    @IBAction func backClicked(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - Index Thumbs from Server
    func indexThumbs(){
        if !loading && canLoadMore {
            loading = true
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.PicsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(thumbs.count)",
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.SafeKey : event!.safekey!,
                          StudyPopClient.ParameterKeys.TheController: Constants.Controller,
                          Photo.Keys.TheType : Constants.TheType
            ]
            self.loadingView.startAnimating()
            StudyPopClient.sharedInstance.httpGet("", parameters: params){(results,error) in
                
                self.loading = false
                
                func sendError(error: String){
                    self.simpleError(error)
                }
                
                guard error == nil else{
                    sendError(error!.localizedDescription)
                    return
                }
                
                guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                    sendError("Got nothing from the server. Please try again")
                    return
                }
                
                if stat == StudyPopClient.JSONResponseValues.Success{
                    if let thumbsDict = results![StudyPopClient.JSONReponseKeys.Thumbs] as? [[String:AnyObject]]{
                        for i in thumbsDict{
                            let dict = i as Dictionary<String,AnyObject>
                            let thumb = Thumb.init(dictionary: dict, context: self.sharedContext)
                            self.thumbs.append(thumb)
                        }
                        if thumbsDict.count < 10{
                            self.canLoadMore = false
                        }else{
                            self.canLoadMore = true
                        }
                    }
                    self.updateUI()
                }else{
                    sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                }
            }
        }
    }
    
    func updateUI(){
        performOnMain(){
            self.loadingView.stopAnimating()
            self.collectionView.reloadData()
        }
    }
    
    // MARK: UICollectionView Methods
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbs.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! EventThumbCollectionViewCell
        let thumb = thumbs[indexPath.row]
        if thumb.photoImage == nil{
            thumb.photoImage = UIImage(data: thumb.blob!)
        }
        
        if thumb.photoImage != nil{
            performOnMain(){
                cell.imageView.image = thumb.photoImage
                cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit
            }
        }
        if indexPath.row == thumbs.count-1 && canLoadMore{
            //You've arrived at the last cell, so if you can load more, load more
            indexThumbs()
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        performSegueWithIdentifier(Constants.ViewPicSegue, sender: indexPath.row)
    }
    
    //Image Picker
    //MARK: -WDImagePicker Delegates
    
    // MARK: - ImagePicker with Crop
    @IBAction func addPic(sender: AnyObject){
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
        let bigImage = bigData!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        self.uploadImage(bigImage)
    }
    
    // MARK: UploadGroupImage
    func uploadImage(bigImage: String){
        self.loadingView.startAnimating()
        let params = [
            StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.PicsController,
            StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.AddMethod,
            StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
            StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
            StudyPopClient.ParameterKeys.Token : user!.token!,
            StudyPopClient.ParameterKeys.SafeKey : event!.safekey!,
            StudyPopClient.ParameterKeys.TheController : Constants.Controller,
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
                let thumbkey = results[StudyPopClient.JSONReponseKeys.ThumbKey] as! String
                let dict = [Thumb.Keys.Parent : self.event!.safekey!, Thumb.Keys.TheType : "\(2)", Thumb.Keys.Protection : "\(1)", Thumb.Keys.Pretty : bigImage, Thumb.Keys.User : thumbkey]
                let picDict = [Photo.Keys.Controller : Constants.Controller, Photo.Keys.SafeKey : safekey, Photo.Keys.TheType : "\(2)", Photo.Keys.ParentKey : self.event!.safekey!, Photo.Keys.Pretty : bigImage]
                performOnMain(){
                    let thumb = Thumb.init(dictionary: dict, context: self.sharedContext)
                    let photo = Photo.init(dictionary: picDict, context: self.sharedContext)
                    thumb.hasPic = photo
                    self.thumbs.insert(thumb, atIndex: 0)
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.updateUI()
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
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == Constants.ViewPicSegue{
            let index = sender as! Int
            let thumb = thumbs[index]
            if let pvc = segue.destinationViewController as? PhotoViewController{
                pvc.user = user!
                pvc.event = event!
                pvc.thumb = thumb
                pvc.index = index
                pvc.controller = Constants.Controller
            }
        }
        
    }
    
}
