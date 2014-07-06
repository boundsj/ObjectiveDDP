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
    if ([keyPath isEqualToString:@"websocketReady"] && self.meteor.websocketReady) {
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

    [self.meteor logonWithEmail:self.username.text password:self.password.text responseCallback:^(NSDictionary *response, NSError *error) {
        if (error) {
            [self handleFailedAuth:error];
            return;
        }
        [self handleSuccessfulAuth];
    }];
}

- (IBAction)didTapSayHiButton {
    [self.meteor callMethodName:@"sayHelloTo" parameters:@[self.email.text] responseCallback:^(NSDictionary *response, NSError *error) {
        NSString *message = response[@"result"];
        [[[UIAlertView alloc] initWithTitle:@"Meteor Todos" message:message delegate:nil cancelButtonTitle:@"Great" otherButtonTitles:nil] show];
    }];
}

#pragma mark - Internal

- (void)handleSuccessfulAuth {
    ListViewController *controller = [[ListViewController alloc] initWithNibName:@"ListViewController"
                                                                          bundle:nil
                                                                          meteor:self.meteor];
    controller.userId = self.meteor.userId;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)handleFailedAuth:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Meteor Todos" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Try Again" otherButtonTitles:nil] show];
}

@end
