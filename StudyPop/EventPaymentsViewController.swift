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
    }
    
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
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! EventPaymentTableViewCell
        let payment = payments[indexPath.row]
        cell.nameLabel.text = payment.name!
        if payment.created != nil{
            cell.dateLabel.text = formatter.stringFromDate(payment.created!)
        }
        return cell
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
    
    
    
    @IBAction func backClicked(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    func updateUI(){
        performOnMain(){
            self.loadingView.stopAnimating()
            self.tableView.reloadData()
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
