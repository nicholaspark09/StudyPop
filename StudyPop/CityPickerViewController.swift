//
//  CityPickerViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/27/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol CityPickerProtocol{
    func hideKeyboard()
    func textFieldDidChange(textField: UITextField)
}

class CityPickerViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var cityTextField: UITextField!{
        didSet{
            cityTextField!.delegate = self
        }
    }

    @IBOutlet var tableView: UITableView!
    
    //For the city search
    var running = false
    var locale = "en_US"
    var cities = [City]()
    
    var tempContext: NSManagedObjectContext = NSManagedObjectContext.init(concurrencyType: .PrivateQueueConcurrencyType)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        locale = appDelegate.getLocale()
        getCity()
        
        cityTextField.addTarget(self, action: #selector(CityPickerProtocol.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        //Tappy tapp tap 
        /*
                Poof! Gone goes the weekend
         */
        let tap = UITapGestureRecognizer(target: self, action: #selector(CityPickerProtocol.hideKeyboard))
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func textFieldDidChange(textField: UITextField){
        let text = textField.text
        if text?.characters.count > 2 && running == false{
            getCities()
        }
    }
    
    func getCity() -> String{
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let cityName = defaults.objectForKey(StudyPopClient.Constants.City)
        if cityName != nil{
            cityTextField.text = cityName as? String
        }
        return ""
    }
    
    // MARK: GetCities 
    func getCities(){
        running = true
        
        let params = [
            StudyPopClient.ParameterKeys.Controller : StudyPopClient.ParameterValues.CitiesController,
            StudyPopClient.ParameterKeys.Method : StudyPopClient.ParameterValues.SearchMethod,
            StudyPopClient.ParameterKeys.ApiKey : StudyPopClient.Constants.ApiKey,
            StudyPopClient.ParameterKeys.ApiSecret : StudyPopClient.Constants.ApiSecret,
            StudyPopClient.ParameterKeys.Name: cityTextField.text!,
            StudyPopClient.ParameterKeys.Locale:locale
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
            
            func sendError(error: String){
                self.simpleError(error)
            }
            
            guard error == nil else{
                sendError("Error: \(error!.localizedDescription)")
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                return
            }
            

            if let cityDictionary = results![StudyPopClient.JSONReponseKeys.Cities] as? [[String:AnyObject]]{
                let _ = cityDictionary.map(){ (dictionary: [String:AnyObject]) -> City in
                    let city = City(dictionary: dictionary, context: self.tempContext)
                    self.cities.append(city)
                    return city
                }
            }
        }
    }
    
    //Hide the keyboard
    func hideKeyboard(){
        view.endEditing(true)
    }

    override var preferredContentSize: CGSize {
        get{
            return super.preferredContentSize
        }
        set{super.preferredContentSize = newValue}
    }
}
