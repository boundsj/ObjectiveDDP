#import <UIKit/UIKit.h>
#import "AddViewController.h"
#import <ObjectiveDDP/MeteorClient.h>

@interface ViewController : UIViewController <UITableViewDataSource, AddViewControllerDelegate>

@property (strong, nonatomic) MeteorClient *meteor;
@property (copy, nonatomic) NSString *userId;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
               meteor:(MeteorClient *)meteor
             listName:(NSString *)listName;
@end
