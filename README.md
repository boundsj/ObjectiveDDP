ObjectiveDDP
============
You've made yourself a boss meteor server and a web client to match. Then one day you decide to write a native iOS client and the only easy way to display your content is with a WebView, Cordova, and/or some other non-optimal hackery. 

What you really want is for your iOS app to communicate directly with the Meteor server, to support Meteor auth, and to perform live updates. No problem.

Requirements
--------------
ObjectiveDDP should run well in iOS projects using ARC and iOS 5 or above (ok well maybe not iOS 7, yet) and with the more recent versions of xcode. If you don't know what ARC is and a cocoapod sounds like something that goes in the fancy office coffee machine then you should probably ask one of your iOS nerd friends to help you out.

Quick Start: The Sample App
--------------
ObjectiveDDP ships with a todo application (of course) that illustrates much about how ObjectiveDDP helps a native iOS app interact with a Meteor server. To run it:

* Clone this repo and navigate to the Example app:

    → git clone git@github.com:boundsj/ObjectiveDDP.git

    → cd Example/
    
* Open the Example app in xcode:

    → open Example.xcworkspace
    
* Start the todo meteor server:

    → cd todos
    
    → meteor

* Back in xcode, build and run the app in the simluator with the run command: ⌘R

**TODO: The app currently points to a hosted version of the meteor server and has a hardcoded user name. This will change soon.**
    
Development: Writing Your Own App
--------------

_Note: ObjectiveDDP is a brand new project and is very much subject to change. Please check this readme and the project wiki frequently for updates._

#### ObjectiveDDP Boilerplate ####
The example application illustrates everything you need to know about integrating ObjectiveDDP into your iOS application. You can also reference the technical walkthrough in the wiki [ios boilerplate] section for the step by step details of creating a simple iOS app that can connect to a meteor server.

#### Development Branch: The Bleeding Edge ####
TBD

#### Tests ####
TBD

General Information
--------------
This project is independent, open source, and is not affiliated with Meteor. If you have questions, ideas about how to make it better, or want to help in any way, please feel free to leave issues and make pull requests on this repo! In particular documenatation pull requests are very much appreciated :)

License
--------------
**MIT**

[git-repo-url]: git@github.com:boundsj/objectiveddp.git
[ios boilerplate]: https://github.com/boundsj/ObjectiveDDP/wiki/ObjectiveDDP-iOS-Boilerplate

  
  