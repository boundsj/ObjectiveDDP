#import "MeteorClient.h"

@implementation MeteorClient

- (void)didOpen {
    NSLog(@"================> didOpen");

    // TODO:
    // tell data delegate(s) that a connection was opened
    [self.authDelegate didConnectToMeteorServer];

    // Send a connect message:
    // TODO: pre1 should be a setting
    [self.ddp connectWithSession:nil version:@"pre1" support:nil];

    // Make nessesary data subscriptions to meteor server
    //NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
    //[self.ddp subscribeWith:uid name:@"things" parameters:nil];
}

- (void)didReceiveMessage:(NSDictionary *)message {

}

- (void)didReceiveConnectionError:(NSError *)error {

}

@end
