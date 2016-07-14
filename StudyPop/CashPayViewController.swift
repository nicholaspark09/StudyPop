//
//  CashPayViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/13/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class CashPayViewController: UIViewController {

    struct Constants{
        static let CashPaymentMethod = "cashpayment"
        static let UnwindToPaymentsSegue = "UnwindToPayments Segue"
    }
    
    
    var user:User?
    var event:Event?
    var payment:Payment?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var findQRButton: UIButton!
    @IBOutlet var totalTextField: UITextField!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var submitButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var infoTextView: UITextView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    
    @IBAction func submitClicked(sender: UIButton) {
        
        let name = nameTextField.text!
        let email = emailTextField.text!
        let total = totalTextField.text!
        let info = infoTextView.text!
        
        if name == ""{
            self.simpleError("Please fill in a name")
        }else{
            submitButton.enabled = false
            addCashPayment(name, email: email, total: total, info: info)
        }
        
    }
    
    func addCashPayment(name:String,email:String, total:String,info:String){
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.PaymentsController,
                      StudyPopClient.ParameterKeys.Method: Constants.CashPaymentMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Token : user!.token!,
                      StudyPopClient.ParameterKeys.SafeKey : event!.safekey!
        ]
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let created = formatter.stringFromDate(date)
        let jsonBody = [Payment.Keys.Name : name, User.Keys.Email : email, Payment.Keys.Total : total, Payment.Keys.Info : info, Payment.Keys.Controller : "events", Payment.Keys.Action : event!.safekey!, "thetype" : "\(1)", Payment.Keys.Created : created]
        loadingView.startAnimating()
        StudyPopClient.sharedInstance.POST("", parameters: params, jsonBody: jsonBody){ (results,error) in
            
            func sendError(error: String){
                self.loadingView.stopAnimating()
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
                if let paymentDict = results[StudyPopClient.JSONReponseKeys.Payment] as? [String:AnyObject]{
                    self.payment = Payment.init(dictionary:paymentDict, context: self.sharedContext)
                    //Send this back!
                    performOnMain(){
                        self.performSegueWithIdentifier(Constants.UnwindToPaymentsSegue, sender: nil)
                    }
                }
            }else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
            }
        }
    }
    
    
    
    @IBAction func cancelClicked(sender: UIButton) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
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
