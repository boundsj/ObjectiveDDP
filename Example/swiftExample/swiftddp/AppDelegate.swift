//
//  AppDelegate.swift
//  swiftddp
//
//  Created by Michael Arthur on 7/6/14.
//  Copyright (c) 2014 . All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var navController: UINavigationController!
    
    // Override point for customization after application launch. creates our singleton
    var meteorClient = initialiseMeteor("pre2", "wss://ddptester.meteor.com/websocket");
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        
        
        meteorClient.addSubscription("things")
        meteorClient.addSubscription("lists")
        
        let loginController:LoginViewController = LoginViewController(nibName: "LoginViewController", bundle: nil)
        loginController.meteor = self.meteorClient
        
        self.navController = UINavigationController(rootViewController:loginController)
        self.navController.navigationBarHidden = true
        
        //This needs to be modified to fix the screen size issue. (Currently a Bug)
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = self.navController
        self.window!.makeKeyAndVisible()
        print(self.window?.frame)
        
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reportConnection", name: MeteorClientDidConnectNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reportDisconnection", name: MeteorClientDidDisconnectNotification, object: nil)
        
        return true
    }
    
    func reportConnection() {
        print("================> connected to server!")
    }
    
    func reportDisconnection() {
        print("================> disconnected from server!")
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

