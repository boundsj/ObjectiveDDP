#import <UIKit/UIKit.h>

@class ViewController, MeteorClient;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;
@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) MeteorClient *meteorClient;

@end
