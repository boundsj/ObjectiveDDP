#import "MeteorClient.h"
#import "BSONIdGenerator.h"

@implementation MeteorClient

- (id)init
{
    self = [super init];
    if (self) {
        // declare meteor data subscriptions
        // TODO: do this as a dependency to make this class more reusable
        self.subscriptions = @{
                @"things": [NSMutableArray array],
                @"lists": [NSMutableArray array]
        };

        // TODO: subscription version should be set here
    }
    return self;
}

#pragma mark Meteor API

- (void) sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters {
    [self.ddp methodWith:[[BSONIdGenerator generate] substringToIndex:15]
                  method:methodName
              parameters:parameters];
}

#pragma mark <ObjectiveDDPDelegate>

- (void)didOpen {
    NSLog(@"================> didOpen");

    [self.authDelegate didConnectToMeteorServer];

    // TODO: pre1 should be a setting
    [self.ddp connectWithSession:nil version:@"pre1" support:nil];
}

- (void)didReceiveMessage:(NSDictionary *)message {
    NSLog(@"================> didReceiveMessage: %@", message);

    NSString *msg = [message objectForKey:@"msg"];

    // TODO: handle auth login failure with auth delegate call (with meteor server error message)

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
        [self.authDelegate didReceiveHAMKVerificationWithResponse:response];

        // it's now a great time to subscribe to the meteor data subscriptions
        [self makeMeteorDataSubscriptions];

    } else if (msg && [msg isEqualToString:@"added"]
                   && message[@"collection"]) {
        [self _parseAdded:message];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"added" object:self];

    } else if (msg && [msg isEqualToString:@"removed"]
                   && message[@"collection"]) {
        [self _parseRemoved:message];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"added" object:self];
    }
}

- (void)didReceiveConnectionError:(NSError *)error {
    NSLog(@"================> didReceiveConnectionError: %@", error);
}

#pragma mark Meteor Data Managment

- (void)makeMeteorDataSubscriptions {
    for (NSString *key in [self.subscriptions allKeys]) {
        NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
        [self.ddp subscribeWith:uid name:key parameters:nil];
    }
}

- (void)_parseAdded:(NSDictionary *)message {
    NSMutableDictionary *object = [NSMutableDictionary dictionaryWithDictionary:@{@"id": message[@"id"]}];

    for (id key in message[@"fields"]) {
        object[key] = message[@"fields"][key];
    }
    NSMutableArray *subscription = self.subscriptions[message[@"collection"]];
    [subscription addObject:object];
}

- (void)_parseRemoved:(NSDictionary *)message {
    NSString *removedId = [message objectForKey:@"id"];
    int indexOfRemovedObject = 0;

    NSMutableArray *subscription = self.subscriptions[message[@"collection"]];

    for (NSDictionary *object in subscription) {
        if ([object[@"id"] isEqualToString:removedId]) {
            break;
        }
        indexOfRemovedObject++;
    }

    [subscription removeObjectAtIndex:indexOfRemovedObject];
}

@end
