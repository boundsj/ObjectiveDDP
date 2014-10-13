ObjectiveDDP
============

[![Build Status](https://travis-ci.org/boundsj/ObjectiveDDP.png)](https://travis-ci.org/boundsj/ObjectiveDDP)

```
Note:
Recent changes to meteor (https://github.com/meteor/meteor/blob/release/0.8.2/History.md) 
have fundamentally changed the way authorization works. Because of this, the current 
version of the master branch of this project (and all future releases) will only be 
compatible with meteor 0.8.2 and above. Please update your meteor server 
as soon as possible.
```

Connect your iOS applications written in Objective-C to server applications that communicate with the [DDP protocol created by Meteor](https://github.com/meteor/meteor/blob/devel/packages/ddp/DDP.md) and, if required by your server, authenticate with it.

What's Inside
-------------

ObjectiveDDP should run well with iOS projects using ARC and iOS 7.1 or above. __**Check out the [example application](https://github.com/boundsj/ObjectiveDDP/wiki/Example-Application) and the [project wiki](https://github.com/boundsj/ObjectiveDDP/wiki) for more information.**__ Here is a sneak peak:

##### Integrate it with your project using CocoaPods:

```
pod 'ObjectiveDDP', '~> 0.1.8'
```
For more information about this, check out [Linking and Building](https://github.com/boundsj/ObjectiveDDP/wiki/Linking-and-using-ObjectiveDDP) in the wiki.

##### Load the library and connect to a meteor server:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.meteorClient = [[MeteorClient alloc] init];
    [self.meteorClient addSubscription:@"awesome_server_mongo_collection"];
    ObjectiveDDP *ddp = [[ObjectiveDDP alloc] initWithURLString:@"wss://awesomeapp.meteor.com/websocket" delegate:self.meteorClient];
    self.meteorClient.ddp = ddp;
    [self.meteorClient.ddp connectWebSocket];
}
```

##### Signup with username:

```objective-c
[self.meteor signupWithUsername:self.username.text password:self.password.text fullname:self.fullname responseCallback:^(NSDictionary *response, NSError *error) {
    if (error) {
        [self handleFailedAuth:error];
        return;
    }
    [self handleSuccessfulAuth];
}];
```
or with email

```objective-c
[self.meteor signupWithEmail:self.email.text password:self.password.text fullname:self.fullname.text responseCallback:^(NSDictionary *response, NSError *error) {
    if (error) {
        [self handleFailedAuth:error];
        return;
    }
    [self handleSuccessfulAuth];
}];
```
or with both

```objective-c
[self.meteor signupWithUsernameAndEmail:self.username.text email:self.email.text password:self.password.text fullname:self.fullname.text responseCallback:^(NSDictionary *response, NSError *error) {
    if (error) {
        [self handleFailedAuth:error];
        return;
    }
    [self handleSuccessfulAuth];
}];
```


##### Logon using authentication:

```objective-c
[self.meteor logonWithUsername:self.username.text password:self.password.text responseCallback:^(NSDictionary *response, NSError *error) {
    if (error) {
        [self handleFailedAuth:error];
        return;
    }
    [self handleSuccessfulAuth];
}];
```
or with email

```objective-c
[self.meteor logonWithEmail:self.email.text password:self.password.text responseCallback:^(NSDictionary *response, NSError *error) {
    if (error) {
        [self handleFailedAuth:error];
        return;
    }
    [self handleSuccessfulAuth];
}];
```
or if you accept both

```objective-c
[self.meteor logonWithUsernameOrEmail:self.usernameOrEmail.text password:self.password.text responseCallback:^(NSDictionary *response, NSError *error) {
    if (error) {
        [self handleFailedAuth:error];
        return;
    }
    [self handleSuccessfulAuth];
}];
```

##### Call a remote function on the server:

```objecctive-c
[self.meteor callMethodName:@"sayHelloTo" parameters:@[self.username.text] responseCallback:^(NSDictionary *response, NSError *error) {
    NSString *message = response[@"result"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Meteor Todos"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"Great"
                                          otherButtonTitles:nil];
    [alert show];
}];
```

##### Listen for updates that meteor sends regarding the collection previously subscribed to:

```objective-c
- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveAddedUpdate:)
                                                 name:@"awesome_server_mongo_collection_added"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveRemovedUpdate:)
                                                 name:@"awesome_server_mongo_collection_removed"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveChangeUpdate:)
                                                 name:@"awesome_server_mongo_collection_changed"
                                               object:nil];
}
```

##### Send CRUD updates to the meteor server to change the collection:

```objective-c
NSString *message = @"I am the walrus";
NSString *anId = [[NSUUID UUID] UUIDString];
NSArray *parameters = @[@{@"_id": anId,
                          @"msg": message,
                          @"owner": self.userId,
                          @"info": self.importantInformation}];

// add a document
[self.meteor callMethodName:@"/awesome_server_mongo_collection/insert"
                 parameters:parameters
           responseCallback:nil];

// then remove it
[self.meteor callMethodName:@"/awesome_server_mongo_collection/remove"
                 parameters:@[@{@"_id": anId}]
           responseCallback:nil];
```

##### Listen for notifications:

MeteorClientConnectionReadyNotification - When the server responds as accepting the DDP protocal version to communicate on, you won't be able to call any methods to meteor until this happens

```objective-c

[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportConnection) name:MeteorClientDidConnectNotification object:nil];
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportConnectionReady) name:MeteorClientConnectionReadyNotification object:nil];
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportDisconnection) name:MeteorClientDidDisconnectNotification object:nil];

```


License
--------------
**[MIT]**

[MIT]: http://opensource.org/licenses/MIT
