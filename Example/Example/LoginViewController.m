#import "LoginViewController.h"
#import "srp.h"
#import "ListViewController.h"

@interface LoginViewController ()

@property (assign, nonatomic) BOOL connectedToMeteor;

@end

@implementation LoginViewController

///
// SRP vars
///
struct SRPUser     * usr;

SRP_HashAlgorithm algLocal     = SRP_SHA256;
SRP_NGType        ng_typeLocal = SRP_NG_1024;

#pragma mark <DDPAuthDelegate>

- (void)didConnectToMeteorServer {
    self.connectionStatusText.text = @"Connected to Todo Server";
    self.connectedToMeteor = YES;
    UIImage *image = [UIImage imageNamed: @"green_light.png"];
    [self.connectionStatusLight setImage:image];
}

// TODO: probably makes sense to move these next to methods out of here
// and do everything on the MeteorClient - the MeteorClient can just
// call this delegate with a "success" or "failure" callback

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

- (void)didReceiveHAMKVerificationWithResponse:(NSDictionary *)response {
    srp_user_verify_meteor_session(usr, [response[@"HAMK"] cStringUsingEncoding:NSASCIIStringEncoding]);

    if (srp_user_is_authenticated) {
        ListViewController *controller = [[ListViewController alloc] initWithNibName:@"ListViewController"
                                                                              bundle:nil
                                                                              meteor:self.meteor];
        controller.userId = response[@"id"];
        self.meteor.sessionToken = response[@"token"];
        [self.navigationController pushViewController:controller animated:YES];
    }

    // TODO: handle not authenticated case here
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

// TODO: This should be moved to a shared library (or maybe just Meteor client)
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
    usr = srp_user_new(algLocal,
            ng_typeLocal,
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
