//
//  ViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/16/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

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
        // Do any additional setup after loading the view, typically from a nib.
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

