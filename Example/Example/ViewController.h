#import <UIKit/UIKit.h>
#import "AddViewController.h"

@class ObjectiveDDP;

@interface ViewController : UIViewController <UITableViewDataSource, AddViewControllerDelegate>
@property (strong, nonatomic) ObjectiveDDP *ddp;
@end
