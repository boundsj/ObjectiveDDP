#import "LoginViewController.h"
#import "srp.h"

@interface LoginViewController ()

@property (assign, nonatomic) BOOL connectedToMeteor;

@end

@implementation LoginViewController

///
// SRP vars
///
struct SRPUser     * usr;

SRP_HashAlgorithm alg     = SRP_SHA256;
SRP_NGType        ng_type = SRP_NG_1024;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark <DDPAuthDelegate>

- (void)didConnectToMeteorServer {
    self.connectionStatusText.text = @"Connected to Todo Server";
    self.connectedToMeteor = YES;
    UIImage *image = [UIImage imageNamed: @"green_light.png"];
    [self.connectionStatusLight setImage:image];
}

- (void)didReceiveLoginChallengeWithResponse:(NSDictionary *)response {
    NSString *B_string = response[@"B"];
    const char *B = [B_string cStringUsingEncoding:NSASCIIStringEncoding];

    NSString *salt_string = response[@"salt"];
    const char *salt = [salt_string cStringUsingEncoding:NSASCIIStringEncoding];

    NSString *identity_string = response[@"identity"];
    const char *identity = [identity_string cStringUsingEncoding:NSASCIIStringEncoding];

    const char * password_str = [self.password.text cStringUsingEncoding:NSASCIIStringEncoding];

    const char * Mstr;
    srp_user_process_meteor_challenge(usr, password_str, salt, identity, B, &Mstr);
    NSString *M_final = [NSString stringWithCString:Mstr encoding:NSASCIIStringEncoding];

    NSArray *params = @[@{@"srp":@{@"M":M_final}}];

    // send login (challenge reponse) to meteor
    [self.meteor sendWithMethodName:@"login"
                         parameters:params];
}

- (void)didReceiveHAMKVerificationWithRespons:(NSDictionary *)response {
    //self.HAMK = message[@"result"][@"HAMK"];

    srp_user_verify_meteor_session(usr, [response[@"HAMK"] cStringUsingEncoding:NSASCIIStringEncoding]);

    // TODO: set app state to "logged in" (whatever that means) here
    if (srp_user_is_authenticated) {
        //self.userId = message[@"result"][@"id"];
        NSLog(@"=========> logged in");

        // push the todo list controller on the stack with whatever state makes sense
    }
}

#pragma mark UI Actions

- (IBAction)didTapLoginButton:(id)sender {
    if (!self.connectedToMeteor) {
        UIAlertView *notConnectedAlert = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                                    message:@"Can't find the Todo server, try again"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
        [notConnectedAlert show];
        return;
    }

    NSArray *params = @[@{@"A": [self generateVerificationKey],
            @"user": @{@"email":self.username.text}}];

    [self.meteor sendWithMethodName:@"beginPasswordExchange"
                         parameters:params];
}


// TODO: This should be moved to a shared library
#pragma mark SRP

- (NSString *)generateVerificationKey {
    //TODO: don't really need to keep bytes_A and len_A here, could remove them
    // and push into srp lib
    const unsigned char * bytes_A = 0;
    int len_A   = 0;
    const char * Astr = 0;
    const char * auth_username = 0;

    const char * username_str = [self.username.text cStringUsingEncoding:NSASCIIStringEncoding];
    const char * password_str = [self.password.text cStringUsingEncoding:NSASCIIStringEncoding];

    /* Begin authentication process */
    usr = srp_user_new(alg,
            ng_type,
            username_str,
            password_str,
            strlen(password_str),
            NULL,
            NULL);

    srp_user_start_authentication(usr,
            &auth_username,
            &bytes_A,
            &len_A,
            &Astr);

    return [NSString stringWithCString:Astr encoding:NSASCIIStringEncoding];
}
@end
