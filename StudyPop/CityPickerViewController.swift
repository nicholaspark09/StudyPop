//
//  CityPickerViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/29/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol CityPickerProtocol{
    func hideKeyboard()
    func textFieldDidChange(textField: UITextField)
}

class CityPickerViewController: UIViewController,UITableViewDelegate,UITableViewDataSource, UITextFieldDelegate {

    
    //Keep local constants here so I can see them on the monitor
    struct Constants{
        static let CellReuseIdentifier = "CityCell"
        static let UnwindSegue = "UnwindToGroups Segue"
        static let UnwindToAdd = "UnwindToAdd Segue"
    }
    
    
    @IBOutlet var theTable: UITableView!
    @IBOutlet var cityTextField: UITextField!{
        didSet{
            cityTextField.delegate = self
        }
    }
    
    var previousController = ""
    var currentCityKey = ""
    var cityName = ""
    var cities = [City]()
    var locale = "en_US"
    var running = false
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        (cityName,currentCityKey) = appDelegate.getCity()
        
        if currentCityKey != ""{
            cityTextField!.text = cityName
        }
        
        
        theTable.delegate = self
        theTable.dataSource = self
        theTable.allowsSelection = true
        theTable.userInteractionEnabled = true
        cityTextField.addTarget(self, action: #selector(CityPickerProtocol.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
       
    }

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        textField.text = ""
        return true
    }
    
    func textFieldDidChange(textField: UITextField){
        let text = textField.text
        if text?.characters.count > 2 && running == false{
            getCities()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        hideKeyboard()
        return true
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! CityTableViewCell
        let city = self.cities[indexPath.row]
        cell.city = city
        return cell
    }
    
    func getCities(){
        running = true
        cities.removeAll()
        theTable.reloadData()
        let params = [
            StudyPopClient.ParameterKeys.Controller : StudyPopClient.ParameterValues.CitiesController,
            StudyPopClient.ParameterKeys.Method : StudyPopClient.ParameterValues.SearchMethod,
            StudyPopClient.ParameterKeys.ApiKey : StudyPopClient.Constants.ApiKey,
            StudyPopClient.ParameterKeys.ApiSecret : StudyPopClient.Constants.ApiSecret,
            StudyPopClient.ParameterKeys.Name: cityTextField.text!,
            StudyPopClient.ParameterKeys.Locale:locale
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
            self.running = false
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
                //First city should be blank in case the use doesn't want any city
                let cityDict = [City.Keys.Name: "No City",City.Keys.User : ""]
                let firstCity = City.init(dictionary: cityDict, context: self.sharedContext)
                self.cities.append(firstCity)
                for i in cityDictionary{
                    let dict = i as Dictionary<String,AnyObject>
                    let city = City.init(dictionary: dict, context: self.sharedContext)
                    self.cities.append(city)
                }
                self.updateUI()
                /*
                 let _ = cityDictionary.map(){ (dictionary: [String:AnyObject]) -> City in
                 let city = City(dictionary: dictionary, context: self.tempContext)
                 self.cities.append(city)
                 return city
                 }
                 performOnMain(){
                 self.tableView.reloadData()
                 }
                 */
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let city = cities[indexPath.row]
        currentCityKey = city.user!
        cityName = city.name!
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(city.name!, forKey: StudyPopClient.Constants.City)
        defaults.setObject(city.user!, forKey: StudyPopClient.Constants.CityKey)
        defaults.synchronize()
        if previousController == GroupsViewController.Constants.Controller{
            performSegueWithIdentifier(Constants.UnwindSegue, sender: nil)
        }else{
            performSegueWithIdentifier(Constants.UnwindToAdd, sender: nil)
        }
        
    }
    
    func updateUI(){
        performOnMain(){
            self.theTable.reloadData()
        }
    }
    
    //Hide the keyboard
    func hideKeyboard(){
        view.endEditing(true)
    }
    

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }
    
}
