#import "MeteorClient.h"
#import "BSONIdGenerator.h"

@implementation MeteorClient

#pragma mark Meteor API

- (void) sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters {
    [self.ddp methodWith:[[BSONIdGenerator generate] substringToIndex:15]
                  method:methodName
              parameters:parameters];
}

#pragma mark <ObjectiveDDPDelegate>

- (void)didOpen {
    NSLog(@"================> didOpen");

    // TODO: tell data delgate
    // tell auth delegate:
    [self.authDelegate didConnectToMeteorServer];

    // Send a connect message:
    // TODO: pre1 should be a setting
    [self.ddp connectWithSession:nil version:@"pre1" support:nil];

    // Make nessesary data subscriptions to meteor server
    //NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
    //[self.ddp subscribeWith:uid name:@"things" parameters:nil];
}

- (void)didReceiveMessage:(NSDictionary *)message {
    NSLog(@"================> didReceiveMessage: %@", message);

    NSString *msg = [message objectForKey:@"msg"];

    //
    if (msg && [msg isEqualToString:@"result"]
            && message[@"result"]
            && message[@"result"][@"B"]
            && message[@"result"][@"identity"]
            && message[@"result"][@"salt"]) {

        NSDictionary *response = message[@"result"];
        [self.authDelegate didReceiveLoginChallengeWithResponse:response];

    } else if (msg && [msg isEqualToString:@"result"]
                   && message[@"result"]
                   && message[@"result"][@"id"]
                   && message[@"result"][@"HAMK"]
                   && message[@"result"][@"token"]) {

        NSDictionary *response = message[@"result"];
        [self.authDelegate didReceiveHAMKVerificationWithRespons:response];
    }
}

- (void)didReceiveConnectionError:(NSError *)error {
    NSLog(@"================> didReceiveConnectionError: %@", error);
}

@end
