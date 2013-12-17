ObjectiveDDP
============
Connect your iOS applications written in Objective-C to server applications that communicate with the [DDP protocol created by Meteor](https://github.com/meteor/meteor/blob/devel/packages/livedata/DDP.md) and, if required by your server, authenticate with [SRP](http://srp.stanford.edu/). Out of the box, this library allows your iOS applications to communicate and authenticate with Meteor servers or any server using the DDP/SRP protocols.

What's Inside
-------------

ObjectiveDDP should run well with iOS projects using ARC and iOS 6.0 or above. __**Check out the [example application](https://github.com/boundsj/ObjectiveDDP/wiki/Example-Application) and the [project wiki](https://github.com/boundsj/ObjectiveDDP/wiki) for more information.**__ Here is a sneak peak:

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

##### Logon using SRP authentication:

```objective-c
[self.meteor logonWithUsername:self.username.text password:self.password.text responseCallback:^(NSDictionary *response, NSError *error) {
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
[self.meteor callMethodName:@"/awesome_server_mongo_collection/insert/remove" 
                 parameters:@[@{@"_id": anId}] 
           responseCallback:nil];
```

License
--------------
**[MIT]**

[MIT]: http://opensource.org/licenses/MIT


