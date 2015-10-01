//
//  LoginViewController.swift
//  swiftddp
//
//  Created by Michael Arthur on 12/08/14.
//  Copyright (c) 2014. All rights reserved.
//

import Foundation
import UIKit

class LoginViewController: UIViewController {
    
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var connectionStatusLight: UIImageView!
    @IBOutlet weak var connectionStatusText: UILabel!
    var meteor:MeteorClient!
    
    override func viewWillAppear(animated: Bool) {
        let observingOption = NSKeyValueObservingOptions.New
        meteor.addObserver(self, forKeyPath:"websocketReady", options: observingOption, context:nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if (keyPath == "websocketReady" && meteor.websocketReady) {
            connectionStatusText.text = "Connected to Todo Server"
            let image:UIImage = UIImage(named: "green_light.png")!
            connectionStatusLight.image = image
        }
        
    }

    
    
    @IBAction func didTapLoginButton(sender: AnyObject) {
        if (!meteor.websocketReady) {
            let notConnectedAlert = UIAlertView(title: "Connection Error", message: "Can't find the Todo server, try again", delegate: nil, cancelButtonTitle: "OK")
            notConnectedAlert.show()
            return
        }
        
        meteor.logonWithEmail(self.email.text, password: self.password.text) {(response, error) -> Void in
            
            if((error) != nil) {
                self.handleFailedAuth(error)
                return
            }
            self.handleSuccessfulAuth()
        }
    }
    
    func handleSuccessfulAuth() {
        let listViewController = ListViewController(nibName: "ListViewController", bundle: nil, meteor: self.meteor)
        
        listViewController.userId = self.meteor.userId
        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func handleFailedAuth(error: NSError) {
        UIAlertView(title: "Meteor Todos", message:error.localizedDescription, delegate: nil, cancelButtonTitle: "Try Again").show()
    }
    
    @IBAction func didTapSayHiButton(sender: AnyObject) {
        self.meteor.callMethodName("sayHelloTo", parameters:[self.email.text!]) {(response, error) -> Void in
            
            if((error) != nil) {
                self.handleFailedAuth(error)
                return
            }
            let message = response["result"] as! String
            UIAlertView(title: "Meteor Todos", message: message, delegate: nil, cancelButtonTitle:"Great").show()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
}

