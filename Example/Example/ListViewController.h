#import <UIKit/UIKit.h>
#import "MeteorClient.h"

@interface ListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) MeteorClient *meteor;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
               meteor:(MeteorClient *)meteor;
@property (copy, nonatomic) NSString *userId;

@end
