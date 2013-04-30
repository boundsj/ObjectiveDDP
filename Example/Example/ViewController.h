#import <UIKit/UIKit.h>
#import "AddViewController.h"
#import "MeteorClient.h"

@interface ViewController : UIViewController <UITableViewDataSource, AddViewControllerDelegate, DDPDataDelegate>

@property (strong, nonatomic) MeteorClient *meteor;
@property (copy, nonatomic) NSString *userId;

@end
