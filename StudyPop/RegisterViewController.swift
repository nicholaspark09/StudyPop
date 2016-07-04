//
//  RegisterViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/25/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol RegisterViewProtocol{
    func hideKeyboard()
    func keyboardWillShow(sender: NSNotification)
    func keyboardWillHide(sender: NSNotification)
}

class RegisterViewController: UIViewController{

    
    struct Constants{
        static let HomeTabSegue = "HomeTab Segue"
    }
    
    
    var name: String?
    var email: String?{
        didSet{
            print("The email was \(email)")
        }
    }
    var user:User?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var confirmTextField: UITextField!
    @IBOutlet var registerButton: UIButton!

    
    @IBOutlet var errorLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(RegisterViewProtocol.hideKeyboard))
        view.addGestureRecognizer(tap)
        
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        let appDelegate = UIApplication.sharedApplication().delegate
        center.addObserverForName(StudyPopClient.Constants.UserNotification, object: appDelegate, queue: queue) {notification -> Void in
            performOnMain(){
                self.performSegueWithIdentifier(Constants.HomeTabSegue, sender: nil)
            }
        }
        
    }


    @IBAction func backClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    //Hide the keyboard
    func hideKeyboard(){
        view.endEditing(true)
    }
    

    
    func register(){
        //Check fields first
        let name = nameTextField.text
        let email = emailTextField.text
        let confirm = confirmTextField.text
        if name?.characters.count < 1{
            nameTextField.placeholder = "Please fill in your name"
            nameTextField.becomeFirstResponder()
        }else if email?.characters.count < 1 {
            emailTextField.placeholder = "Please fill in your email"
            emailTextField.becomeFirstResponder()
        }else if confirm?.characters.count < 1{
            confirmTextField.placeholder = "Please re-enter your email"
            confirmTextField.becomeFirstResponder()
        }else if email != confirm{
            simpleError("Email and Confirmation Email have to be the same")
        }else{
            errorLabel.text = "Loading..."
            registerButton.enabled = false
            StudyPopClient.sharedInstance.registerUser(name!, email: email!){ (results,error) in
                if let error = error{
                    self.errorLabel.text = error
                }else if let safekey = results{
                    performOnMain({
                        //Save the token in defaults
                        let defaults = NSUserDefaults.standardUserDefaults()
                        defaults.setValue(email, forKey: User.Keys.Email)
                        defaults.setValue(safekey, forKey: User.Keys.Token)
                        defaults.synchronize()
                        self.errorLabel.text = "Please check your email for a login link"
                    })
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        unsubscribeToKeyboardNotifications()
        //super.viewWillDisappear(animated)
    }
    
    
    /*
     KEYBOARD shtuff
     */
    func keyboardWillShow(sender: NSNotification){

            self.view.frame.origin.y -= getKeyboardHeight(sender)
    }
    
    func keyboardWillHide(sender: NSNotification){
 
            self.view.frame.origin.y += getKeyboardHeight(sender)
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }
    
    // MARK: Notification Methods
    //Add an observer for the keyboard both on attachment and detachment
    func subscribeToKeyboardNotifications(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RegisterViewProtocol.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RegisterViewProtocol.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeToKeyboardNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    
    @IBAction func registerClicked(sender: UIButton) {
        register()
        
    }
    
    @IBAction func facebookLoginClicked(sender: AnyObject) {
        
        errorLabel.text = "Connecting to Facebook..."
        
        let login = FBSDKLoginManager.init()
        login.logInWithReadPermissions(["public_profile"], fromViewController: self.parentViewController, handler: { (result,error) in
            
            func sendMessage(message: String){
                performOnMain(){
                    self.errorLabel.text = message
                }
            }
            
            if let error = error{
                sendMessage("LoginError: \(error.localizedDescription)")
            }else if result.isCancelled{
                sendMessage("Login cancelled")
                
            }else{
                sendMessage("Connected to facebook. Logging you in...")
                
                // GET Profile information from Facebook so you can finally save this dang user
                let token = result.token.tokenString
                let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name"], tokenString: token, version: nil, HTTPMethod: "GET")
                request.startWithCompletionHandler({ (connection,result,error: NSError!) in
                    if let error = error{
                        sendMessage("Error: \(error.localizedDescription)")
                    }else{
                        let facebookId = result.valueForKey("id") as! String
                        let userName = result.valueForKey("name") as! String
                        print("You got a user name back with id \(facebookId) and username: \(userName)")
                        //Login the user to StudyPop API
                        //Check to see if there's already a local user
                        
                        let request = NSFetchRequest(entityName: "User")
                        request.fetchLimit = 1
                        request.predicate = NSPredicate(format: "oauthtokenuid == %@", facebookId)
                        do{
                            let results = try self.sharedContext.executeFetchRequest(request)
                            if results.count > 0{
                                if let temp = results[0] as? User{
                                    self.user = temp
                                    self.user!.logged = true
                                    self.user!.accesstoken = token
                                    performOnMain(){
                                        CoreDataStackManager.sharedInstance().saveContext()
                                        self.performSegueWithIdentifier(Constants.HomeTabSegue, sender: nil)
                                    }
                                }
                            }else{
                                //No User, so register them into the StudyPop API first!
                                let params = [
                                    StudyPopClient.ParameterKeys.Controller : StudyPopClient.ParameterValues.UserController,
                                    StudyPopClient.ParameterKeys.Method : StudyPopClient.ParameterValues.FacebookLoginMethod,
                                    StudyPopClient.ParameterKeys.ApiKey : StudyPopClient.Constants.ApiKey,
                                    StudyPopClient.ParameterKeys.ApiSecret : StudyPopClient.Constants.ApiSecret,
                                    StudyPopClient.ParameterKeys.OauthUid : facebookId,
                                    User.Keys.Name : userName
                                ]
                                StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
                                    
                                    
                                    guard error == nil else{
                                        sendMessage("Error: \(error!.localizedDescription)")
                                        return
                                    }
                                    guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                                        sendMessage("Nothing came back from the server")
                                        return
                                    }
                                    
                                    guard stat == StudyPopClient.JSONResponseValues.Success else{
                                        sendMessage("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                                        return
                                    }
                                    
                                    guard let safekey = results[StudyPopClient.JSONReponseKeys.SafeKey] as? String else{
                                        sendMessage("Couldn't find the safekey in the response")
                                        return
                                    }
                                    
                                    //You have a returned item, go ahead and save it as a new user!
                                    let userDict = [User.Keys.Name : userName, User.Keys.SafeKey : safekey, User.Keys.Token : safekey, User.Keys.Oauthtokenuid : facebookId, User.Keys.AccessToken : token]
                                    self.user = User.init(dictionary: userDict, context: self.sharedContext)
                                    self.user!.logged = true
                                    performOnMain(){
                                        CoreDataStackManager.sharedInstance().saveContext()
                                        self.performSegueWithIdentifier(Constants.HomeTabSegue, sender: nil)
                                    }
                                }
                            }
                        } catch {
                            let fetchError = error as NSError
                            print("Couldn't access CoreData: \(fetchError.localizedDescription)")
                        }
                    }
                    
                })
            }
        })
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
