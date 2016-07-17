//
//  AccountViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/16/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol AccountViewProtocol{
    func refreshClicked(sender: UIBarButtonItem)
}

class AccountViewController: UIViewController {
    
    var account:Account?
    var group:Group?
    var user:User?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var phoneLabel: UILabel!
    @IBOutlet var stripeIdLabel: UILabel!
    @IBOutlet var balanceLabel: UILabel!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Account: "+group!.name!
        
        updateUI()
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(AccountViewProtocol.refreshClicked(_:)))
    }
    
    
    func refreshClicked(sender: UIBarButtonItem){
        sender.enabled = false
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.AccountsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.ViewMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.SafeKey: group!.safekey!,
                      StudyPopClient.ParameterKeys.Token : user!.token!
        ]
        loadingView.startAnimating()
        StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
            
            performOnMain(){
                sender.enabled = true
                self.loadingView.stopAnimating()
            }
            
            func sendError(error: String){
                self.simpleError(error)
            }
            
            guard error == nil else{
                print("An error from GET: \(error!)")
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                sendError("No response from server")
                return
            }
            
            if stat == StudyPopClient.JSONResponseValues.Success{
                if let dict = results[StudyPopClient.JSONReponseKeys.Account] as? [String:AnyObject]{
                    performOnMain(){
                        self.sharedContext.deleteObject(self.account!)
                        self.account = Account.init(dictionary: dict, context: self.sharedContext)
                        self.account!.groupkey = self.group!.safekey!
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                    self.updateUI()
                }
            }else{
                sendError("Error: \(results[StudyPopClient.JSONReponseKeys.Error])")
            }
        }
    }
    
    func updateUI(){
        performOnMain(){
            if self.account != nil{
                self.nameLabel.text = self.account!.name!
                self.emailLabel.text = self.account!.email
                self.phoneLabel.text = self.account!.phone
                self.stripeIdLabel.text = self.account!.clientid
                let balance = Double((100*self.account!.balance!.floatValue)/100)
                self.balanceLabel.text = "\(balance)"
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
