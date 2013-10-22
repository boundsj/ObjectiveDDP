#import "DependencyProvider.h"
#import "MeteorClient.h"
#import "BSONIdGenerator.h"
#import "srp/srp.h"

@interface MeteorClient ()

@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, assign) int retryAttempts;

@end

@implementation MeteorClient

- (id)init {
    self = [super init];
    if (self) {
        self.collections = [NSMutableDictionary dictionary];
        self.subscriptions = [NSMutableDictionary dictionary];
        self.subscriptionsParameters = [NSMutableDictionary dictionary];
        self.methodIds = [NSMutableSet set];
        self.retryAttempts = 0;
    }
    return self;
}

#pragma mark MeteorClient public API

- (void)resetCollections {
    [self.collections removeAllObjects];
}

- (void)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters {
    [self sendWithMethodName:methodName parameters:parameters notifyOnResponse:NO];
}

-(NSString *)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters notifyOnResponse:(BOOL)notify {
    if (!self.websocketReady) {
        return NULL;
    }
    NSString *methodId = [BSONIdGenerator generate];
    if(notify == YES) {
        [self.methodIds addObject:methodId];
    }
    [self.ddp methodWithId:methodId
                    method:methodName
                parameters:parameters];

    return methodId;
}

- (void)addSubscription:(NSString *)subscriptionName {
    [self addSubscription:subscriptionName withParameters:nil];
}

- (void)addSubscription:(NSString *)subscriptionName withParameters:(NSArray *)parameters {
    NSString *uid = [BSONIdGenerator generate];
    [self.subscriptions setObject:uid forKey:subscriptionName];
    if (parameters) {
        [self.subscriptionsParameters setObject:parameters forKey:subscriptionName];
    }
    if (!self.websocketReady) {
        return;
    }
    [self.ddp subscribeWith:uid name:subscriptionName parameters:parameters];
}

-(void)removeSubscription:(NSString *)subscriptionName {
    if (!self.websocketReady) {
        return;
    }
    NSString *uid = [self.subscriptions objectForKey:subscriptionName];
    if (uid) {
        [self.ddp unsubscribeWith:uid];
        // XXX: Should we really remove sub until we hear back from sever?
        [self.subscriptions removeObjectForKey:subscriptionName];
    }
}

static BOOL userIsLoggingIn = NO;

- (void)logonWithUsername:(NSString *)username password:(NSString *)password {
    if (userIsLoggingIn) {
        return;
    }
    NSArray *params = @[@{@"A": [self generateAuthVerificationKeyWithUsername:username password:password],
                          @"user": @{@"email":username}}];
    userIsLoggingIn = YES;
    [self sendWithMethodName:@"beginPasswordExchange" parameters:params];
}

- (void)logout {
    [self sendWithMethodName:@"logout" parameters:nil];
}

#pragma mark <ObjectiveDDPDelegate>

static int LOGON_RETRY_MAX = 5;

- (void)didReceiveMessage:(NSDictionary *)message {
    NSString *msg = [message objectForKey:@"msg"];
    NSString *messageId = message[@"id"];
    
    if ([self.methodIds containsObject:messageId]) {
        if(msg && [msg isEqualToString:@"result"]) {
            NSDictionary *response = message[@"result"];
            NSString *notificationName = [NSString stringWithFormat:@"response_%@", messageId];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                                object:self
                                                              userInfo:response];
            [self.methodIds removeObject:messageId];
        }
    } else if (msg && [msg isEqualToString:@"result"]
               && message[@"result"]
               && [message[@"result"] isKindOfClass:[NSDictionary class]]               
               && message[@"result"][@"B"]
               && message[@"result"][@"identity"]
               && message[@"result"][@"salt"]) {
        NSDictionary *response = message[@"result"];
        [self didReceiveLoginChallengeWithResponse:response];
    } else if(msg && [msg isEqualToString:@"result"]
              && message[@"error"]
              && [message[@"error"][@"error"]integerValue] == 403) {
        userIsLoggingIn = NO;
        if (++self.retryAttempts < LOGON_RETRY_MAX) {
            [self logonWithUsername:self.userName password:self.password];
        } else {
            self.retryAttempts = 0;
            [self.authDelegate authenticationFailed:message[@"error"][@"reason"]];
        }
    } else if (msg && [msg isEqualToString:@"result"]
               && message[@"result"]
               && [message[@"result"] isKindOfClass:[NSDictionary class]]
               && message[@"result"][@"id"]
               && message[@"result"][@"HAMK"]
               && message[@"result"][@"token"]) {
        NSDictionary *response = message[@"result"];
        [self didReceiveHAMKVerificationWithResponse:response];
    } else if (msg && [msg isEqualToString:@"added"]
               && message[@"collection"]) {
        NSDictionary *object = [self _parseObjectAndAddToCollection:message];
        NSString *notificationName = [NSString stringWithFormat:@"%@_added", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:object];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"added" object:self userInfo:object];
    } else if (msg && [msg isEqualToString:@"removed"]
               && message[@"collection"]) {
        [self _parseRemoved:message];
        NSString *notificationName = [NSString stringWithFormat:@"%@_removed", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"removed" object:self];
    } else if (msg && [msg isEqualToString:@"changed"]
               && message[@"collection"]) {
        NSDictionary *object = [self _parseObjectAndUpdateCollection:message];
        NSString *notificationName = [NSString stringWithFormat:@"%@_changed", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:object];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"changed" object:self userInfo:object];
    } else if (msg && [msg isEqualToString:@"connected"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"connected" object:nil];
        if (self.sessionToken) {
            NSArray *params = @[@{@"resume": self.sessionToken}];
            [self sendWithMethodName:@"login"
                          parameters:params];
        }
        [self makeMeteorDataSubscriptions];
    } else if (msg && [msg isEqualToString:@"ready"]) {
        NSArray *subs = message[@"subs"];
        for(NSString *readySubscription in subs) {
            for(NSString *subscriptionName in self.subscriptions) {
                NSString *curSubId = self.subscriptions[subscriptionName];
                if([curSubId isEqualToString:readySubscription]) {
                    NSString *notificationName = [NSString stringWithFormat:@"%@_ready", subscriptionName];
                    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
                    break;
                }
            }
        }
    }
}

- (void)didOpen {
    self.websocketReady = YES;
    [self resetCollections];
    // TODO: pre1 should be a setting
    [self.ddp connectWithSession:nil version:@"pre1" support:nil];
}

- (void)reconnect {
    if (self.ddp.webSocket.readyState == SR_OPEN) {
        return;
    }
    [self.ddp connectWebSocket];
}

- (void)didReceiveConnectionError:(NSError *)error {
    self.websocketReady = NO;
    [self performSelector:@selector(reconnect)
               withObject:self
               afterDelay:5.0];
}

- (void)didReceiveConnectionClose {
    self.websocketReady = NO; 
    [self performSelector:@selector(reconnect)
               withObject:self
               afterDelay:5.0];
}

#pragma mark Meteor Data Managment

- (void)makeMeteorDataSubscriptions {
    for (NSString *key in [self.subscriptions allKeys]) {
        NSString *uid = [BSONIdGenerator generate];
        [self.subscriptions setObject:uid forKey:key];  
        NSArray *params = self.subscriptionsParameters[key];
        [self.ddp subscribeWith:uid name:key parameters:params];
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

# pragma mark Meteor SRP Wrapper

static SRPUser *srpUser;

- (NSString *)generateAuthVerificationKeyWithUsername:(NSString *)username password:(NSString *)password {
    self.userName = username;
    self.password = password;
    const char *username_str = [username cStringUsingEncoding:NSASCIIStringEncoding];
    const char *password_str = [password cStringUsingEncoding:NSASCIIStringEncoding];
    srpUser = srp_user_new(SRP_SHA256, SRP_NG_1024, username_str, password_str, NULL, NULL);
    srp_user_start_authentication(srpUser);
    return [NSString stringWithCString:srpUser->Astr encoding:NSASCIIStringEncoding];
}

- (void)didReceiveLoginChallengeWithResponse:(NSDictionary *)response {
    NSString *B_string = response[@"B"];
    const char *B = [B_string cStringUsingEncoding:NSASCIIStringEncoding];
    NSString *salt_string = response[@"salt"];
    const char *salt = [salt_string cStringUsingEncoding:NSASCIIStringEncoding];
    NSString *identity_string = response[@"identity"];
    const char *identity = [identity_string cStringUsingEncoding:NSASCIIStringEncoding];
    const char *password_str = [self.password cStringUsingEncoding:NSASCIIStringEncoding];
    const char *Mstr;
    srp_user_process_meteor_challenge(srpUser, password_str, salt, identity, B, &Mstr);
    NSString *M_final = [NSString stringWithCString:Mstr encoding:NSASCIIStringEncoding];
    NSArray *params = @[@{@"srp":@{@"M":M_final}}];
    [self sendWithMethodName:@"login" parameters:params];
}

- (void)didReceiveHAMKVerificationWithResponse:(NSDictionary *)response {
    userIsLoggingIn = NO;
    srp_user_verify_meteor_session(srpUser, [response[@"HAMK"] cStringUsingEncoding:NSASCIIStringEncoding]);
    if (srp_user_is_authenticated) {
        self.sessionToken = response[@"token"];
        self.userId = response[@"id"];
        [self.authDelegate authenticationWasSuccessful];
        srp_user_delete(srpUser);
    }
}

@end
