//
//  ViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/16/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData



@objc protocol LoginViewProtocol{
    func hideKeyboard()
    //func tokenChanged(notification:NSNotification)
}

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    struct Constants{
        static let LoadingText = "Loading..."
        static let RegisterSegue = "Register Segue"
        static let HomeTabSegue = "HomeTab Segue"
    }
    
    @IBOutlet var emailTextField: UITextField!{
        didSet{
            emailTextField.delegate = self
        }
    }
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    
    var user:User?
    
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(LoginViewProtocol.hideKeyboard))
        view.addGestureRecognizer(tap)
        
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        let appDelegate = UIApplication.sharedApplication().delegate
        center.addObserverForName(StudyPopClient.Constants.UserNotification, object: appDelegate, queue: queue) {notification -> Void in
            performOnMain(){
                self.performSegueWithIdentifier(Constants.HomeTabSegue, sender: nil)
            }
        }
        
        getUser()
        if user != nil{
            self.performSegueWithIdentifier(Constants.HomeTabSegue, sender: nil)
        }else{
            print("The user is nil!")
        }
        
        /*
        FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewProtocol.tokenChanged(_:)), name: FBSDKProfileDidChangeNotification, object: nil)
 */
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if emailTextField.text?.characters.count > 1{
            emailTextField.resignFirstResponder()
            login()
        }
        return true
    }
    
    @IBAction func loginClicked(sender: UIButton) {
        
        login()
        
    }

    func login(){
        errorLabel.text = Constants.LoadingText
        loginButton.enabled = false
        errorLabel.text = "Logging in..."
        let email = emailTextField.text!
        loadingView.startAnimating()
        StudyPopClient.sharedInstance.login(email){ (result,error) in
            if let error = error{
                performOnMain({ 
                    self.errorLabel.text = error
                    self.loginButton.enabled = true
                    self.loadingView.stopAnimating()
                })
            }else if let safekey = result{
                print("The resulting safekey is \(safekey)")
                performOnMain({
                    self.loadingView.stopAnimating()
                    //Save the token in defaults
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setValue(email, forKey: User.Keys.Email)
                    defaults.setValue(safekey, forKey: User.Keys.Token)
                    defaults.synchronize()
                    self.errorLabel.textColor = UIColor.greenColor()
                    self.errorLabel.text = "Please check your email for the login link"
                })
            }
        }
    }
    

    @IBAction func unwindToLoginViewController(sender: UIStoryboardSegue){
        user = nil
        self.loginButton.enabled = true
        self.emailTextField.text = ""
    }
    
    //Hide the keyboard
    func hideKeyboard(){
        view.endEditing(true)
    }
    
    // MARK: SeguePrep
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.RegisterSegue{
            if let rc = segue.destinationViewController as? RegisterViewController{
                rc.email = emailTextField.text
            }
        }
    }
    
    @IBAction func facebookLoginClicked(sender: AnyObject) {
        
        errorLabel.text = "Connecting to Facebook..."
        self.loadingView.startAnimating()
        let login = FBSDKLoginManager.init()
        login.logInWithReadPermissions(["public_profile"], fromViewController: self.parentViewController, handler: { (result,error) in
            
            func sendMessage(message: String){
                performOnMain(){
                    self.errorLabel.text = message
                    self.loadingView.stopAnimating()
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
                performOnMain(){
                    self.loadingView.startAnimating()
                }
                let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name"], tokenString: token, version: nil, HTTPMethod: "GET")
                request.startWithCompletionHandler({ (connection,result,error: NSError!) in
                    if let error = error{
                        sendMessage("Error: \(error.localizedDescription)")
                        performOnMain(){
                            self.loadingView.stopAnimating()
                        }
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
                                            self.loadingView.stopAnimating()
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
        Once you're logged on with facebook, the token should change and this function
        will be called per NSNotification
            - Get the profile information and update the server as well as save the
    func tokenChanged(notification:NSNotification){
        if FBSDKAccessToken.currentAccessToken() != nil{
            
        }
    }
 */
    
    
    func getUser(){
        let request = NSFetchRequest(entityName: "User")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "logged == %@", true)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0{
                if let temp = results[0] as? User{
                    user = temp
                }
            }
        } catch {
            let fetchError = error as NSError
            print("The error was \(fetchError)")
        }
    }
}

