ObjectiveDDP
============
Connect your applications written in Objective-C to server applications that communicate with the [DDP protocol created by Meteor] and, if required by your server, authenticate with [SRP]. Out of the box, this library allows your iOS applications to communicate and authenticate with Meteor servers or any server using the DDP/SRP protocols.

What's Inside
-------------

ObjectiveDDP should run well with iOS projects using ARC and iOS 6.0 or above. Check out the [example application](https://github.com/boundsj/ObjectiveDDP/wiki/Example-Application) and the [project wiki](https://github.com/boundsj/ObjectiveDDP/wiki) for more information. Here is a sneak peak:

##### Load the library and connect to a meteor server:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.meteorClient = [[MeteorClient alloc] init];
    [self.meteorClient addSubscription:@"awesome_server_mongo_collection"];
    loginController.meteor = self.meteorClient;
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

License
--------------
**[MIT]**
[DDP protocol created by Meteor]: https://github.com/meteor/meteor/blob/devel/packages/livedata/DDP.md
[MIT]: http://opensource.org/licenses/MIT


