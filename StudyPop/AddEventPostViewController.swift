//
//  AddEventPostViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/28/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class AddEventPostViewController: UIViewController {

    
    struct Constants{
        static let CancelTitle = "Cancel"
        static let CloseTitle = "Close"
        static let KeepWorkingTitle = "Keep Working"
        static let LoadingTitle = "Loading..."
        static let UnwindToEventPostsSegue = "UnwindToEventPosts Segue"
    }
    
    
    var event: Event?
    var user:User?
    var post:EventPost?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var submitButton: UIButton!
    @IBOutlet var textView: UITextView!
    @IBOutlet var loadingLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func cancelClicked(sender: UIButton) {
        
        let text = textView!.text!
        if text.characters.count > 0 {
            let refreshAlert = UIAlertController(title: Constants.CancelTitle, message: "Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
            
            refreshAlert.addAction(UIAlertAction(title: Constants.CloseTitle, style: .Default, handler: { (action: UIAlertAction!) in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            refreshAlert.addAction(UIAlertAction(title: Constants.KeepWorkingTitle, style: .Cancel, handler:nil))
            
            presentViewController(refreshAlert, animated: true, completion: nil)
        }else{
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func submitClicked(sender: UIButton) {
        let text = textView.text!
        if text.characters.count < 1 {
            self.loadingLabel.text = "Please write a post"
            self.textView.becomeFirstResponder()
        }else{
            submitButton.enabled = false
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventPostsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.AddMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.SafeKey : event!.safekey!,
            ]
            let date = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            let created = formatter.stringFromDate(date)
            let jsonBody = [EventPost.Keys.Body : text, EventPost.Keys.TheType : "\(1)", EventPost.Keys.Created : created]
            StudyPopClient.sharedInstance.POST("", parameters: params, jsonBody: jsonBody){(results,error) in
                
                func sendError(error: String){
                    self.loadingLabel.text = error
                    self.submitButton.enabled = true
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
                    let safekey = results[StudyPopClient.JSONReponseKeys.SafeKey] as! String
                    performOnMain(){
                        self.loadingLabel.text = "Saved!"
                        
                        let postDict = [EventPost.Keys.Name : "Me", EventPost.Keys.User : self.user!.token!, EventPost.Keys.Pretty : text, EventPost.Keys.SafeKey : safekey]
                        self.post = EventPost.init(dictionary: postDict, context: self.sharedContext)
                        self.post!.created = NSDate()
                        self.performSegueWithIdentifier(Constants.UnwindToEventPostsSegue, sender: nil)
                    }
                }else{
                    sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                }
            }
        }
    }

    
    
    override var preferredContentSize: CGSize {
        get{
            return super.preferredContentSize
        }
        set{super.preferredContentSize = newValue}
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
