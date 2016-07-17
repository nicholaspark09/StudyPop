//
//  PayWithCreditViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/6/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol PayWithCreditProtocol{
    func hideKeyboard()
    //func tokenChanged(notification:NSNotification)
}

class PayWithCreditViewController: UIViewController {

    struct Constants{
        static let EventPayCompletedSegue = "EventPayCompleted Segue"
    }
    
    
    var user:User?
    var name = ""
    var Controller = ""
    var Action = ""
    var payment:Payment?
    var total:Float?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var creditTextField: UITextField!
    @IBOutlet var cvcTextField: UITextField!
    @IBOutlet var monthTextField: UITextField!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var textView: UITextView!
    @IBOutlet var loadinvView: UIActivityIndicatorView!
    @IBOutlet var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.text = "Event: \(name), Price: $\(total!)"
        let tap = UITapGestureRecognizer(target: self, action: #selector(PayWithCreditProtocol.hideKeyboard))
        view.addGestureRecognizer(tap)
    }

    
    @IBAction func cancelClicked(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func submitClicked(sender: AnyObject) {
        let email = emailTextField.text
        let credit = creditTextField.text
        let month = monthTextField.text
        let cvc = cvcTextField.text
        if credit != ""{
            let creditCard = STPCard()
            creditCard.number = credit
            creditCard.cvc = cvc
            if (month != nil){
                let expArr = month!.componentsSeparatedByString("/")
                if (expArr.count > 1)
                {
                    let expMonth = UInt(expArr[0])!
                    let expYear = UInt(expArr[1])!
                    creditCard.expMonth = expMonth
                    creditCard.expYear = expYear
                }
            }
            self.loadinvView.startAnimating()
            self.errorLabel.text = "Checking card..."
            Stripe.createTokenWithCard(creditCard){ (token,stripeError) in
                if stripeError != nil{
                    performOnMain(){
                        self.loadinvView.stopAnimating()
                        self.errorLabel.text = "Error: \(stripeError!.localizedDescription)"
                    }
                }else{
                    self.chargeCard(token!.tokenId, stripeId:token!.stripeID)
                    performOnMain(){
                        self.errorLabel.text = "Submitting payment..."
                    }
                    
                }
            }
        }else{
            self.errorLabel.text = "Please fill in the credit card info"
            
        }
        
    }
    
    //Hide the keyboard
    func hideKeyboard(){
        view.endEditing(true)
    }
    
    func chargeCard(token: String, stripeId: String){
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.PaymentsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.AddMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Token : user!.token!,
        ]
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let created = formatter.stringFromDate(date)
        let jsonBody = [StudyPopClient.ParameterKeys.StripeToken : token, StudyPopClient.ParameterKeys.Name : name, StudyPopClient.ParameterKeys.Controller : Controller, StudyPopClient.ParameterKeys.Action : Action, Event.Keys.Price : "\(total!)", StudyPopClient.ParameterKeys.StripeId : stripeId, Payment.Keys.Created : created]
        performOnMain(){
            self.loadinvView.startAnimating()
            self.errorLabel.text = "Charging card"
        }
        StudyPopClient.sharedInstance.POST("", parameters: params, jsonBody: jsonBody){ (results,error) in
            func sendError(error: String){
                performOnMain(){
                    self.loadinvView.stopAnimating()
                    self.errorLabel.text = error
                }
            }
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                sendError("Got nothing back from the server")
                return
            }
            guard stat == StudyPopClient.JSONResponseValues.Success else{
                let error = results[StudyPopClient.JSONReponseKeys.Error] as! String
                sendError("Error: \(error)")
                return
            }
            
            
            performOnMain(){
                self.loadinvView.stopAnimating()
                self.errorLabel.text = "Successfully made payment"
            }
            
            if let dict = results[StudyPopClient.JSONReponseKeys.Payment] as? [String:AnyObject]{
                self.payment = Payment.init(dictionary: dict, context: self.sharedContext)
                performOnMain(){
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.performSegueWithIdentifier(Constants.EventPayCompletedSegue, sender: nil)
                }
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
    
    func updateUI(){
        
    }
    
    override var preferredContentSize: CGSize {
        get{
            return super.preferredContentSize
        }
        set{super.preferredContentSize = newValue}
    }

}
