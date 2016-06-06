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
}

class LoginViewController: UIViewController {
    
    struct Constants{
        static let LoadingText = "Loading..."
        static let RegisterSegue = "Register Segue"
        static let HomeTabSegue = "HomeTab Segue"
    }
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var errorLabel: UILabel!
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
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    @IBAction func loginClicked(sender: UIButton) {
        
        login()
        
        
    }

    func login(){
        errorLabel.text = Constants.LoadingText
        loginButton.enabled = false
        errorLabel.text = "Logging in..."
        let email = emailTextField.text!
        StudyPopClient.sharedInstance.login(email){ (result,error) in
            if let error = error{
                performOnMain({ 
                    self.errorLabel.text = error
                    self.loginButton.enabled = true
                })
            }else if let safekey = result{
                print("The resulting safekey is \(safekey)")
                performOnMain({
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

