#import "AppDelegate.h"
#import "ViewController.h"
#import "LoginViewController.h"
#import "MeteorClient.h"
#import "ObjectiveDDP.h"
#import <ObjectiveDDP/MeteorClient.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.meteorClient = [[MeteorClient alloc] init];

    [self.meteorClient addSubscription:@"things"];
    [self.meteorClient addSubscription:@"lists"];

    LoginViewController *loginController = [[LoginViewController alloc] initWithNibName:@"LoginViewController"
                                                                                 bundle:nil];
    loginController.meteor = self.meteorClient;

    ObjectiveDDP *ddp = [[ObjectiveDDP alloc] initWithURLString:@"wss://ddptester.meteor.com/websocket" delegate:self.meteorClient];
    // useful for local testing
    //ObjectiveDDP *ddp = [[ObjectiveDDP alloc] initWithURLString:@"ws://localhost:3000/websocket" delegate:self.meteorClient];

    self.meteorClient.ddp = ddp;
    self.meteorClient.authDelegate = loginController;

    self.navController = [[UINavigationController alloc] initWithRootViewController:loginController];
    self.navController.navigationBarHidden = YES;

    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.meteorClient resetCollections];
    [self.meteorClient.ddp connectWebSocket];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
