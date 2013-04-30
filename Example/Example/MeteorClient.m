#import "MeteorClient.h"
#import "BSONIdGenerator.h"

@implementation MeteorClient

- (id)init
{
    self = [super init];
    if (self) {
        self.subscriptions = @{@"things": [NSMutableArray array]};
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

        // Make data subscriptions to meteor server
        for (NSString *key in [self.subscriptions allKeys]) {
            NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
            [self.ddp subscribeWith:uid name:key parameters:nil];
        }

    } else if (msg && [msg isEqualToString:@"added"] && [message[@"collection"] isEqualToString:@"things"]) {
        [self _parseAdded:message];
        [self.dataDelegate didReceiveUpdate];

    } else if (msg && [msg isEqualToString:@"removed"] && [message[@"collection"] isEqualToString:@"things"]) {
        [self _parseRemoved:message];
        [self.dataDelegate didReceiveUpdate];
    }
}

- (void)didReceiveConnectionError:(NSError *)error {
    NSLog(@"================> didReceiveConnectionError: %@", error);
}

#pragma mark Meteor Data Managment

- (void)_parseAdded:(NSDictionary *)message {
    NSMutableDictionary *thing = [NSMutableDictionary dictionaryWithDictionary:@{@"id": message[@"id"]}];
    for (id key in message[@"fields"]) {
        thing[key] = message[@"fields"][key];
    }
    [self.subscriptions[@"things"] addObject:thing];
}

- (void)_parseRemoved:(NSDictionary *)message {
    NSString *removedId = [message objectForKey:@"id"];
    int indexOfRemovedThing = 0;

    for (NSDictionary *thing in self.subscriptions[@"things"]) {
        if ([thing[@"id"] isEqualToString:removedId]) {
            break;
        }
        indexOfRemovedThing++;
    }

    [self.subscriptions[@"things"] removeObjectAtIndex:indexOfRemovedThing];
}

@end
