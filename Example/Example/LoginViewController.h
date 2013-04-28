#import <UIKit/UIKit.h>
#import "MeteorClient.h"

@interface LoginViewController : UIViewController<DDPAuthDelegate>

@property (weak, nonatomic) IBOutlet UILabel *connectionStatusText;
@property (weak, nonatomic) IBOutlet UIImageView *connectionStatusLight;

@end
