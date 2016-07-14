//
//  EventPaymentsViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/9/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class EventPaymentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate {

    struct Constants{
        static let CellReuseIdentifier = "EventPayment Cell"
        static let Controller = "events"
        static let CashPaySegue = "AddCashPay Segue"
        static let ViewPaymentSegue = "ViewPayment Segue"
        static let ViewPaymentController = "ViewPayment Controller"
        static let PaymentOptionsTitle = "Payment Options"
        static let RefundTitle = "Refund"
        static let EmailTitle = "Email Receipt"
        static let CancelTitle = "Cancel"
    }
    
    
    let cashImage = UIImage(named: "CashSmall")
    let creditImage = UIImage(named: "CreditSmall")
    
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var pricePerPersonLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    
    
    var event:Event?
    var user:User?
    var payments = [Payment]()
    var formatter:NSDateFormatter!
    var loading = false
    var canLoadMore = true
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameLabel.text  = event!.name!
        formatter = NSDateFormatter()
        formatter.dateFormat = "MMM d, H:mm a"
        if event!.price != nil{
            pricePerPersonLabel.text = "\(event!.price!.floatValue)"
        }
        indexPayments()
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if payments.count < 1 {
            return "No one has paid yet"
        }
        return nil
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return payments.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let payment = payments[indexPath.row]
        let refreshAlert = UIAlertController(title: Constants.PaymentOptionsTitle, message: payment.name!, preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: Constants.RefundTitle, style: .Default, handler: { (action: UIAlertAction!) in
            //Start Deleting...
            self.loadingView.startAnimating()
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventsController,
                StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.DeleteMethod,
                StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                StudyPopClient.ParameterKeys.SafeKey: payment.safekey!,
                StudyPopClient.ParameterKeys.Token : self.user!.token!
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
                func sendError(error: String){
                    self.simpleError(error)
                }
                
                guard error == nil else{
                    sendError(error!.localizedDescription)
                    return
                }
                
                guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                    sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error]!)")
                    return
                }
                
            }
        }))
        
        
        refreshAlert.addAction(UIAlertAction(title: Constants.EmailTitle, style: .Default, handler:nil))
        
        refreshAlert.addAction(UIAlertAction(title: Constants.CancelTitle, style: .Cancel, handler:nil))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! EventPaymentTableViewCell
        let payment = payments[indexPath.row]
        cell.nameLabel.text = payment.name!
        if payment.created != nil{
            cell.dateLabel.text = formatter.stringFromDate(payment.created!)
        }
        if payment.total != nil{
            cell.priceLabel.text = "\(payment.totalpaid!.floatValue)"
        }
        cell.infoTextView.text = payment.info!
        if payment.paymenttype != nil{
            if payment.paymenttype!.intValue == 1{
                //Cash
                cell.paymentImageView.image = cashImage
            }else{
                //Credit
                cell.paymentImageView.image = creditImage
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            dropPayment(payments[indexPath.row].safekey!)
            payments.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    

    // MARK: -IndexEventPayments
    func indexPayments(){
        if !loading && canLoadMore{
            loading = true
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.PaymentsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(payments.count)",
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.TheController : Constants.Controller,
                          StudyPopClient.ParameterKeys.Action : event!.safekey!
            ]
            self.loadingView.startAnimating()
            StudyPopClient.sharedInstance.httpGet("", parameters: params) { (results,error) in
                
                self.loading = false
                func sendError(error: String){
                    self.simpleError(error)
                    performOnMain(){
                        self.loadingView.stopAnimating()
                    }
                }
                
                guard error == nil else{
                    sendError(error!.localizedDescription)
                    return
                }
                
                guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                    sendError("StudyPopApi: Could not get proper response from server")
                    return
                }
                
                if stat == StudyPopClient.JSONResponseValues.Success{
                    
                    if let paymentsDictionary = results![StudyPopClient.JSONReponseKeys.Payments] as? [[String:AnyObject]]{
                        for i in paymentsDictionary{
                            let dict = i as Dictionary<String,AnyObject>
                            let payment = Payment.init(dictionary:dict, context: self.sharedContext)
                            self.payments.append(payment)
                        }
                        if paymentsDictionary.count < 500{
                            self.canLoadMore = false
                        }else{
                            self.canLoadMore = true
                        }
                    }
                }else if let responseError = results[StudyPopClient.JSONReponseKeys.Error] as? String{
                    sendError(responseError)
                }
                self.updateUI()
            }
        }
    }
    
    @IBAction func unwindToEventPayments(segue: UIStoryboardSegue){
        if let cpc = segue.sourceViewController as? CashPayViewController{
            let payment = cpc.payment!
            self.payments.insert(payment, atIndex: 0)
            updateUI()
        }
    }
    
    @IBAction func backClicked(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Update the UI from this function
    // Everything here runs on the main thread
    func updateUI(){
        performOnMain(){
            self.loadingView.stopAnimating()
            self.tableView.reloadData()
        }
    }
    
    func dropPayment(safekey: String){
        //Delete this payment from the server
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.PaymentsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.DeleteMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.SafeKey: safekey,
                      StudyPopClient.ParameterKeys.Token : self.user!.token!
        ]
        loadingView.startAnimating()
        StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
            
            performOnMain(){
                self.loadingView.stopAnimating()
            }
            func sendError(error: String){
                self.simpleError(error)
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error]!)")
                return
            }
            
            
        }
    }


    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.CashPaySegue{
            if let cvc = segue.destinationViewController as? CashPayViewController{
                cvc.modalPresentationStyle = UIModalPresentationStyle.Popover
                cvc.popoverPresentationController!.delegate = self
                cvc.event = event!
                cvc.user = user!
            }
        }
    }


}
