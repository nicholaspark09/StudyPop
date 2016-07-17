//
//  AddAccountViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/16/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class AddAccountViewController: UIViewController {

    struct Constants{
        static let UnwindToGroupSegue = "UnwindToGroup Segue"
    }
    
    
    var user:User?
    var group:Group?
    var account:Account?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var phoneTextField: UITextField!
    @IBOutlet var infoTextView: UITextView!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var submitButton: UIButton!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "+ Account: "+group!.name!
        let tap = UITapGestureRecognizer(target: self, action: #selector(PayWithCreditProtocol.hideKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    //Hide the keyboard
    func hideKeyboard(){
        view.endEditing(true)
    }
    


    @IBAction func submitClicked(sender: AnyObject) {
        let email = emailTextField.text
        let name = nameTextField.text
        let phone = phoneTextField.text
        let info = infoTextView.text
        if name == ""{
                errorLabel.text = "Please fill in a name"
        }else if email == ""{
            errorLabel.text = "You must put in an email address"
        }else{
            createAccount(name!, email: email!, phone: phone!, info: info!)
        }
    }
    
    func createAccount(name: String, email:String, phone: String, info: String){
        submitButton.enabled = false
        loadingView.startAnimating()
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.AccountsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.AddMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Token : user!.token!,
                      StudyPopClient.ParameterKeys.SafeKey : group!.safekey!
        ]
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let created = formatter.stringFromDate(date)
        let jsonBody = [Account.Keys.Name : name, Account.Keys.Email: email, Account.Keys.Info : info, Account.Keys.Phone : phone, GroupPost.Keys.Created : created]
        StudyPopClient.sharedInstance.POST("", parameters: params, jsonBody: jsonBody){ (results,error) in
            
            performOnMain(){
                self.loadingView.stopAnimating()
            }
            func sendError(error: String){
                performOnMain(){
                    self.errorLabel.text = error
                    self.submitButton.enabled = true
                }
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
                if let dict = results[StudyPopClient.JSONReponseKeys.Account] as? [String:AnyObject]{
                    self.account = Account.init(dictionary: dict, context: self.sharedContext)
                }
                performOnMain(){
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.performSegueWithIdentifier(Constants.UnwindToGroupSegue, sender: nil)
                }
            }else{
                sendError("Error: \(results[StudyPopClient.JSONReponseKeys.Error])")
            }
        }
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
