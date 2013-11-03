ObjectiveDDP
============
Easily connect your applications written in Objective-C to server applications that communicate with the [DDP protocol created by Meteor] and, if required by your server, authenticate with [SRP]. Out of the box, this library allows your iOS applications to communicate and authenticate with Meteor servers or any server using the DDP/SRP protocols.

Requirements
--------------
ObjectiveDDP should run well in iOS projects using ARC and iOS 5.0 or above. If you don't know what ARC is and a cocoapod sounds like something that goes in the fancy office coffee machine then you should probably ask one of your iOS nerd friends to help you out.

Quick Start: The Sample App
--------------
ObjectiveDDP ships with a todo application (of course) that illustrates much about how ObjectiveDDP helps a native iOS app interact with a Meteor server. To run it:

* Clone this repo and navigate to the Example app:

    * git clone git@github.com:boundsj/ObjectiveDDP.git
    * cd Example/
    
* Get the ObjectiveDDP cocoapod: (if you don't already have cocoapods, [get it])

    * git clone git@github.com:boundsj/ObjectiveDDP.git    
    * pod install
    
* Open the Example app in xcode:

    * open Example.xcworkspace

* Build and run the app in the simluator with the run command: ⌘R

Todo App Screenshots:
![alt text](https://raw.github.com/boundsj/ObjectiveDDP/master/screenshots.png "Screenshots")

**NOTE: The app connects to a meteor server [http://ddptester.meteor.com](http://ddptester.meteor.com) and has a hardcoded user name.**
    
Development: Writing Your Own App
--------------

_Note: ObjectiveDDP is a work in progress and subject to project setup and breaking API changes!_

#### ObjectiveDDP Boilerplate ####
The example application illustrates everything you need to know about integrating ObjectiveDDP into your iOS application. You can also reference the technical walkthrough in the wiki [ios boilerplate] section for the step by step details of creating a simple iOS app that can connect to a meteor server.

#### Development Branch: The Bleeding Edge ####
Please use this branch if you have forked the project and plan to send pull requests. It is also useful for testing new features that you read about in issues but are not in the master branch yet.

#### Tests ####
All tests are in the Specs directory and tests (which are actually the best documenatation) for the DDP protocol implementation are in the [ddp tests] file.

General Information
--------------
This project is independent, open source, and is not affiliated with Meteor. If you have questions, ideas about how to make it better, or want to help in any way, please feel free to leave issues and make pull requests on this repo! In particular documenatation pull requests are very much appreciated :)

###Special Thanks##

####ObjectiveDDP is supported by [ReachSocket]####
![alt text](https://s3.amazonaws.com/rebounds-dev/github/reachsocket-github.png "Screenshots")

####Contributors####

 * @stevemanuel
 * @ewindso
 * @boundsj (author)

License
--------------
**[MIT]**
[DDP protocol created by Meteor]: https://github.com/meteor/meteor/blob/devel/packages/livedata/DDP.md
[SRP]: http://srp.stanford.edu/
[git-repo-url]: git@github.com:boundsj/objectiveddp.git
[ios boilerplate]: https://github.com/boundsj/ObjectiveDDP/wiki/ObjectiveDDP-iOS-Boilerplate
[ddp tests]: https://github.com/boundsj/ObjectiveDDP/blob/master/Specs/ObjectiveDDPSpec.mm
[get it]: http://docs.cocoapods.org/guides/installing_cocoapods.html
[ReachSocket]: http://reachsocket.com/
[MIT]: http://opensource.org/licenses/MIT


