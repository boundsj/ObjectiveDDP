#import "LoginViewController.h"
#import "ListViewController.h"
#import <ObjectiveDDP/MeteorClient.h>

@implementation LoginViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.meteor addObserver:self
                  forKeyPath:@"websocketReady"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
}

#pragma mark <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"websocketReady"]) {
        self.connectionStatusText.text = @"Connected to Todo Server";
        UIImage *image = [UIImage imageNamed: @"green_light.png"];
        [self.connectionStatusLight setImage:image];
    }
}

#pragma mark UI Actions

- (IBAction)didTapLoginButton:(id)sender {
    if (!self.meteor.websocketReady) {
        UIAlertView *notConnectedAlert = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                                    message:@"Can't find the Todo server, try again"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
        [notConnectedAlert show];
        return;
    }

    [self.meteor logonWithUsername:self.username.text password:self.password.text];
}

#pragma mark DDPAuthDelegate

- (void)authenticationWasSuccessful {
    ListViewController *controller = [[ListViewController alloc] initWithNibName:@"ListViewController"
                                                                          bundle:nil
                                                                          meteor:self.meteor];
    controller.userId = self.meteor.userId;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)authenticationFailed {
  // TODO: handle not authenticated case here
}

@end
