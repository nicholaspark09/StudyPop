//
//  ViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/16/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

@objc protocol LoginViewProtocol{
    func hideKeyboard()
}

class LoginViewController: UIViewController {
    
    struct Constants{
        static let LoadingText = "Loading..."
        static let RegisterSegue = "Register Segue"
    }
    
    @IBOutlet var emailTextField: UITextField!

    @IBOutlet var loginButton: UIButton!
    
    @IBOutlet var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(LoginViewProtocol.hideKeyboard))
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
}

