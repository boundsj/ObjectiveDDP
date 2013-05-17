#import <UIKit/UIKit.h>
#import <ObjectiveDDP/MeteorClient.h>

@interface LoginViewController : UIViewController<DDPAuthDelegate>

@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusText;
@property (weak, nonatomic) IBOutlet UIImageView *connectionStatusLight;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) MeteorClient *meteor;

- (IBAction)didTapLoginButton:(id)sender;

@end
