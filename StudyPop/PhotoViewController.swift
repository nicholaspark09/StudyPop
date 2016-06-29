//
//  PhotoViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/24/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData


class PhotoViewController: UIViewController {

    struct Constants{
        static let DeleteTitle = "Delete Photo"
        static let DeleteMessage = "Delete"
        static let CancelTitle = "Cancel"
        static let UnwindToGroupPicSegue = "UnwindToGroupPic Segue"
    }
    
    
    var thumb:Thumb?
    var group:Group?
    var event: Event?
    var user:User?
    var controller = ""
    var index: Int = -1
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.imageView.image = thumb!.photoImage
        self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
        displayBigImage()
        if thumb!.hasPic == nil {
            StudyPopClient.sharedInstance.findThumbParent(user!.token!, safekey: thumb!.user!){ (results,error) in
                performOnMain(){
                    self.loadingView.stopAnimating()
                }
                if let error = error {
                    self.simpleError(error)
                }else if results != nil{
                    let photo = Photo.init(dictionary: results!, context: self.sharedContext)
                    self.thumb!.hasPic = photo
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.displayBigImage()
                }else{
                    print("Couldn't find anything")
                }
            }
        }
    }
    
    func displayBigImage(){
        if thumb!.hasPic != nil{
            performOnMain(){
                self.imageView.image = self.thumb!.hasPic!.photoImage
                self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
            }
        }
    }

    @IBAction func backClicked(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func deleteClicked(sender: UIButton) {
        let refreshAlert = UIAlertController(title: Constants.DeleteTitle, message: "Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        refreshAlert.addAction(UIAlertAction(title: Constants.DeleteMessage, style: .Default, handler: { (action: UIAlertAction!) in
            //Start Deleting...
            self.loadingView.startAnimating()
            sender.enabled = false
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.PicsController,
                StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.DeleteMethod,
                StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                StudyPopClient.ParameterKeys.SafeKey: self.thumb!.user!,
                StudyPopClient.ParameterKeys.Token : self.user!.token!
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
                
                func sendError(error: String){
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
                    sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error]!)")
                    return
                }
                
                performOnMain(){
                    self.performSegueWithIdentifier(Constants.UnwindToGroupPicSegue, sender: nil)
                }
                
            }
        }))
        
        refreshAlert.addAction(UIAlertAction(title: Constants.CancelTitle, style: .Cancel, handler:nil))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
        
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
