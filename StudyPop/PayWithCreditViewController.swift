//
//  PayWithCreditViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/6/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class PayWithCreditViewController: UIViewController {

    struct Constants{
        
    }
    
    
    var user:User?
    var name = ""
    var Controller = ""
    var Action = ""
    var total:Float?
    
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
                    performOnMain(){
                        self.errorLabel.text = "Submitting payment..."
                    }
                }
            }
        }else{
            self.errorLabel.text = "Please fill in the credit card info"
            
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
