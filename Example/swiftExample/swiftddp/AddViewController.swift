//
//  AddViewController.swift
//  swiftddp
//
//  Created by Michael Arthur on 13/08/14.
//  Copyright (c) 2014. All rights reserved.
//

import Foundation
import UIKit

class AddViewController : UIViewController {
    
    
    @IBOutlet weak var messageTextView: UITextView!
    var delegate:AddViewControllerDelegate!
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }    
    
    @IBAction func didTouchAddButton(sender: AnyObject!) {
        self.delegate.didAddThing(self.messageTextView.text)
    }
    
    
    
}

protocol AddViewControllerDelegate {
    
    func didAddThing(message:NSString!)
}
