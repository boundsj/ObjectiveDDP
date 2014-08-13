//
//  ViewController.swift
//  swiftddp
//
//  Created by Michael Arthur on 7/6/14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource, AddViewControllerDelegate {
    
    var meteor:MeteorClient!
    var listName:NSString!
    var userId:NSString!
    
    @IBOutlet weak var tableview: UITableView!
    
    required init(coder aDecoder: NSCoder!) {
        super.init()
        if aDecoder != nil {
            
        }
        
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        if(self != nil) {
            
        }
    }
    
    init(nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!, meteor: MeteorClient!, listName:NSString!) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        if(self != nil) {
            self.meteor = meteor
            self.listName = listName
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.title = self.listName
        UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "didTouchAdd:")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveUpdate:", name: "added", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveUpdate:", name: "removed", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func didReceiveUpdate(notification:NSNotification) {
        self.tableview.reloadData()
    }
    
    func computedList() -> NSArray {
        var pred:NSPredicate = NSPredicate(format: "(listName like %@)", self.listName)
        return self.meteor.collections["things"].filteredArrayUsingPredicate(pred)
    }
    
    @IBAction func didTouchAdd(sender: AnyObject) {
        var addController = AddViewController(nibName: "AddViewController", bundle: nil)
        
        addController.delegate = self
        self.presentViewController(addController, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return self.computedList().count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cellIdentifier:NSString! = "thing"
        var cell:UITableViewCell
        
        if var tmpCell: AnyObject = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) {
            cell = tmpCell as UITableViewCell
        } else {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier) as UITableViewCell
        }
        
        var thing:NSDictionary = self.computedList()[indexPath.row] as NSDictionary
        cell.textLabel.text = thing["msg"] as String
        
        return cell
    }
    
    func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        if(editingStyle == UITableViewCellEditingStyle.Delete) {
            var thing:NSDictionary = self.computedList()[indexPath.row] as NSDictionary
            self.meteor.callMethodName("/things/remove", parameters: [["_id":thing["_id"]]], responseCallback: nil)
        }
    }
    
    func didAddThing(message: NSString!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        var parameters:NSArray = [["_id": NSUUID.UUID().UUIDString,
                                    "msg":message,
                                    "owner":self.userId,
                                    "listName":self.listName]]
        
        self.meteor.callMethodName("/things/insert", parameters: parameters, responseCallback: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

