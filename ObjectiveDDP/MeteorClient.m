#import "MeteorClient.h"
#import "BSONIdGenerator.h"

@implementation MeteorClient

- (id)init
{
    self = [super init];
    if (self) {
        self.collections = [NSMutableDictionary dictionary];
        self.subscriptions = [NSMutableDictionary dictionary];
        // TODO: subscription version should be set here
    }
    return self;
}

#pragma mark Meteor API

- (void)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters {
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
        NSDictionary *object = [self _parseObjectAndAddToCollection:message];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"added" object:self userInfo:object];

    } else if (msg && [msg isEqualToString:@"removed"]
            && message[@"collection"]) {
        [self _parseRemoved:message];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"removed" object:self userInfo:nil];

    } else if (msg && [msg isEqualToString:@"changed"]
            && message[@"collection"]) {
        NSDictionary *object = [self _parseObjectAndUpdateCollection:message];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"changed" object:self userInfo:object];

    } else if (msg && [msg isEqualToString:@"connected"]) {
        // TODO: This is the default behavior but user should be able to turn this off and do selective subs
        [self makeMeteorDataSubscriptions];
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

- (NSDictionary *)_parseObjectAndUpdateCollection:(NSDictionary *)message {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(_id like %@)", message[@"id"]];
    NSMutableArray *collection = self.collections[message[@"collection"]];
    NSArray *filteredArray = [collection filteredArrayUsingPredicate:pred];

    NSMutableDictionary *object = filteredArray[0];

    for (id key in message[@"fields"]) {
        object[key] = message[@"fields"][key];
    }

    return object;
}

- (NSDictionary *)_parseObjectAndAddToCollection:(NSDictionary *)message {
    NSMutableDictionary *object = [NSMutableDictionary dictionaryWithDictionary:@{@"_id": message[@"id"]}];

    for (id key in message[@"fields"]) {
        object[key] = message[@"fields"][key];
    }

    if (!self.collections[message[@"collection"]]) {
        self.collections[message[@"collection"]] = [NSMutableArray array];
    }

    NSMutableArray *collection = self.collections[message[@"collection"]];

    [collection addObject:object];

    return object;
}

- (void)_parseRemoved:(NSDictionary *)message {
    NSString *removedId = [message objectForKey:@"id"];
    int indexOfRemovedObject = 0;

    NSMutableArray *collection = self.collections[message[@"collection"]];

    for (NSDictionary *object in collection) {
        if ([object[@"_id"] isEqualToString:removedId]) {
            break;
        }
        indexOfRemovedObject++;
    }

    [collection removeObjectAtIndex:indexOfRemovedObject];
}

@end
