//
//  RegisterViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/25/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

@objc protocol RegisterViewProtocol{
    func hideKeyboard()
    func keyboardWillShow(sender: NSNotification)
    func keyboardWillHide(sender: NSNotification)
}

class RegisterViewController: UIViewController{

    
    var name: String?
    var email: String?{
        didSet{
            print("The email was \(email)")
        }
    }
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var confirmTextField: UITextField!
    @IBOutlet var registerButton: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(RegisterViewProtocol.hideKeyboard))
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            registerButton.enabled = false
            StudyPopClient.sharedInstance.registerUser(name!, email: email!){ (results,error) in
                if let error = error{
                    self.simpleError(error)
                }else if let safekey = results{
                    performOnMain({
                        //Save the token in defaults
                        let defaults = NSUserDefaults.standardUserDefaults()
                        defaults.setValue(email, forKey: User.Keys.Email)
                        defaults.setValue(safekey, forKey: User.Keys.Token)
                        defaults.synchronize()
                        
                    })
                    self.simpleError("Please check your email for a login link")
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
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
