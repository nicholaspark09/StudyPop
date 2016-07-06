//
//  AppDelegate.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/16/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    struct Constants{
        static let StoryboardName = "Main"
        static let UserEntity = "User"
        static let StoryboardLoginView = "LoginView"
        static let StoryboardGroupsView = "GroupsView"
        static let StoryboardHomeTab = "HomeTab"
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        Stripe.setDefaultPublishableKey("pk_test_IeR8DmaKtT6Gi5W7vvySoCiO")
        
        //Check for a logged in user first
        let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
        let request = NSFetchRequest(entityName: Constants.UserEntity)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "logged == %@", true)
        do{
           let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0{
                //A user was found!
                //Send them to the tabcontroller
                
                let storyboard = UIStoryboard.init(name: Constants.StoryboardName, bundle: nil)
                let hc = storyboard.instantiateViewControllerWithIdentifier(Constants.StoryboardHomeTab) as UIViewController
                self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
                self.window?.rootViewController = hc
                self.window?.makeKeyAndVisible()
                
            }else{
                print("The user wasn't logged in")
                //No logged in user
                let storyboard = UIStoryboard.init(name: Constants.StoryboardName, bundle: nil)
                let lc = storyboard.instantiateViewControllerWithIdentifier(Constants.StoryboardLoginView) as UIViewController
                self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
                self.window?.rootViewController = lc
                self.window?.makeKeyAndVisible()
            }
        } catch {
            let fetchError = error as NSError
            print("The error was \(fetchError)")
        }
        
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        
        
       
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        print("Are you even running this?")
        
        let urlString = url.absoluteString
        let data = urlString.componentsSeparatedByString("/")
        if data.count > 0{
            if data[2] == "login"{
                
                //Check the login safekey
                let defaults = NSUserDefaults.standardUserDefaults()
                let safekey = defaults.objectForKey(User.Keys.Token) as? String
                if safekey == nil{
                    print("Error: Nothing was found")
                }else{
                    
                    //First check to see if the user exists
                    let email = defaults.objectForKey(User.Keys.Email)! as! String
                    var user = getUser(email)
                    if user == nil{
                        let userDetails = [User.Keys.Name:"",User.Keys.Email: defaults.objectForKey(User.Keys.Email)!,User.Keys.Logged:true,User.Keys.Token:safekey!,User.Keys.SafeKey: safekey!]
                        user = User.init(dictionary: userDetails, context: CoreDataStackManager.sharedInstance().managedObjectContext)
                    }else{
                        user!.token = safekey!
                        user!.safekey = safekey!
                        user!.logged = true
                    }
                    print("You have a user with email: \(user!.email)")
                    CoreDataStackManager.sharedInstance().saveContext()
                    let center = NSNotificationCenter.defaultCenter()
                    let notification = NSNotification(name: StudyPopClient.Constants.UserNotification, object: self, userInfo: [User.Keys.Token: safekey!])
                    center.postNotification(notification)
                }
                /*
                 print("You observed it. Now broadcast it")
                 let center = NSNotificationCenter.defaultCenter()
                 let notification = NSNotification(name: StudyPopClient.Constants.LoginNotification, object: self, userInfo: [StudyPopClient.Constants.LoginKey:data[3]])
                 center.postNotification(notification)
                 */
            }
        }
        
        
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    //Get the locale
    /*
        On the StudyPop API (Which I unfortunately made...)
            all locales are based on language_CountryCode
            
    */
    func getLocale() -> String{
        let locale = NSLocale.currentLocale()
        let countryCode = locale.objectForKey(NSLocaleCountryCode) as! String
        var language:String = "en-US"
        language = locale.objectForKey(NSLocaleLanguageCode) as! String
        language = "\(language)_\(countryCode)"
        return language
    }
    
    
    // MARK: GetCity - Returns CityName, CityKey
    func getCity() -> (String,String){
        let defaults = NSUserDefaults.standardUserDefaults()
        var cityName = "No city"
        var cityKey = ""
        let savedCityName = defaults.objectForKey(StudyPopClient.Constants.City)
        let savedCityKey = defaults.objectForKey(StudyPopClient.Constants.CityKey)
        if savedCityName != nil{
            cityName = savedCityName as! String
            cityKey = savedCityKey as! String
        }
        return (cityName,cityKey)
    }

    func getSubject() -> (String, String){
        let defaults = NSUserDefaults.standardUserDefaults()
        var subjectName = "No Subject"
        var subjectKey = ""
        let savedSubjectName = defaults.objectForKey(StudyPopClient.Constants.Subject)
        let savedSubjectKey = defaults.objectForKey(StudyPopClient.Constants.SubjectKey)
        if savedSubjectName != nil{
            subjectName = savedSubjectName as! String
            subjectKey = savedSubjectKey as! String
        }
        return (subjectName,subjectKey)
    }
    
    func getUser(email: String) -> User?{
        let request = NSFetchRequest(entityName: "User")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "email == %@", email)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0{
                if let temp = results[0] as? User{
                    return temp
                }
            }
        } catch {
            let fetchError = error as NSError
            print("The error was \(fetchError)")
        }
        return nil
    }
 
}

