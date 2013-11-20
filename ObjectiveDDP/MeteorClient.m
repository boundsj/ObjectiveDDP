#import "DependencyProvider.h"
#import "MeteorClient.h"
#import "BSONIdGenerator.h"
#import "srp.h"

NSString * const MeteorClientDidConnectNotification = @"boundsj.objectiveddp.connected";
NSString * const MeteorClientDidDisconnectNotification = @"boundsj.objectiveddp.disconnected";
NSString * const MeteorClientTransportErrorDomain = @"boundsj.objectiveddp.transport";

NSInteger const MeteorClientNotConnectedError = 1;
NSInteger const MeteorClientDisconnectedError = 2;

@interface MeteorClient (Parsing)

- (void)_handleMethodResultMessageWithMessageId:(NSString *)messageId message:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleLoginChallengeResponse:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleLoginError:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleHAMKVerification:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleAddedMessage:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleRemovedMessage:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleChangedMessage:(NSDictionary *)message msg:(NSString *)msg;

@end

@interface MeteorClient ()

@property (strong, nonatomic, readwrite) NSMutableDictionary *deferreds;

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
        self.deferreds = [NSMutableDictionary dictionary];
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

- (NSString *)_send:(BOOL)notify parameters:(NSArray *)parameters methodName:(NSString *)methodName {
    NSString *methodId = [BSONIdGenerator generate];
    if(notify == YES) {
        [self.methodIds addObject:methodId];
    }
    [self.ddp methodWithId:methodId
                    method:methodName
                parameters:parameters];
    return methodId;
}

-(NSString *)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters notifyOnResponse:(BOOL)notify {
    if (![self okToSend]) {
        return nil;
    }
    return [self _send:notify parameters:parameters methodName:methodName];
}

- (NSString *)callMethodName:(NSString *)methodName parameters:(NSArray *)parameters asyncCallback:(asyncCallback)asyncCallback {
    if (![self okToSend]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"You are not connected"};
        NSError *notConnectedError = [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientNotConnectedError userInfo:userInfo];
        asyncCallback(nil, notConnectedError);
        return nil;
    }
    NSString *methodId = [self _send:YES parameters:parameters methodName:methodName];
    if (asyncCallback) {
        [self.deferreds setObject:[asyncCallback copy] forKey:methodId];
    }
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
    if (![self okToSend]) {
        return;
    }
    [self.ddp subscribeWith:uid name:subscriptionName parameters:parameters];
}

-(void)removeSubscription:(NSString *)subscriptionName {
    if (![self okToSend]) {
        return;
    }
    NSString *uid = [self.subscriptions objectForKey:subscriptionName];
    if (uid) {
        [self.ddp unsubscribeWith:uid];
        // XXX: Should we really remove sub until we hear back from sever?
        [self.subscriptions removeObjectForKey:subscriptionName];
    }
}

- (BOOL)okToSend {
    if (!self.connected || (self.usingAuth && !self.loggedIn)) {
        return NO;
    }
    return YES;
}

- (void)logonWithUsername:(NSString *)username password:(NSString *)password {
    if (self.userIsLoggingIn) return;
    NSArray *params = @[@{@"A": [self generateAuthVerificationKeyWithUsername:username password:password],
                          @"user": @{@"email":username}}];
    self.usingAuth = NO;
    self.loggedIn = NO;
    self.userIsLoggingIn = YES;
    [self sendWithMethodName:@"beginPasswordExchange" parameters:params];
}

- (void)logout {
    [self.ddp methodWithId:[BSONIdGenerator generate]
                    method:@"logout"
                parameters:nil];
    self.loggedIn = NO;
}

#pragma mark <ObjectiveDDPDelegate>

- (void)didReceiveMessage:(NSDictionary *)message {
    NSString *msg = [message objectForKey:@"msg"];
    if (!msg) return;
    NSString *messageId = message[@"id"];
    
    [self _handleMethodResultMessageWithMessageId:messageId message:message msg:msg];
    [self _handleLoginChallengeResponse:message msg:msg];
    [self _handleLoginError:message msg:msg];    
    [self _handleHAMKVerification:message msg:msg];
    [self _handleAddedMessage:message msg:msg];
    [self _handleRemovedMessage:message msg:msg];
    [self _handleChangedMessage:message msg:msg];
    
    if (msg && [msg isEqualToString:@"connected"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"connected" object:nil];
        self.connected = YES;
        if (self.sessionToken) {
            [self.ddp methodWithId:[BSONIdGenerator generate]
                            method:@"login"
                        parameters:@[@{@"resume": self.sessionToken}]];
        }
        [self _makeMeteorDataSubscriptions];
    }
    
    if (msg && [msg isEqualToString:@"ready"]) {
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
    [[NSNotificationCenter defaultCenter] postNotificationName:MeteorClientDidConnectNotification object:self];
}

- (void)didReceiveConnectionError:(NSError *)error {
    [self _handleConnectionError];
}

- (void)didReceiveConnectionClose {
    [self _handleConnectionError];
}

- (void)_handleConnectionError {
    self.websocketReady = NO;
    self.connected = NO;
    [self _invalidateUnresolvedMethods];
    [self performSelector:@selector(_reconnect)
               withObject:self
               afterDelay:5.0];
    [[NSNotificationCenter defaultCenter] postNotificationName:MeteorClientDidDisconnectNotification object:self];
}

- (void)_invalidateUnresolvedMethods {
    for (NSString *methodId in self.methodIds) {
        asyncCallback callback = self.deferreds[methodId];
        callback(nil, [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientNotConnectedError userInfo:@{NSLocalizedDescriptionKey: @"You were disconnected"}]);
    }
    [self.methodIds removeAllObjects];
    [self.deferreds removeAllObjects];
}

- (void)_reconnect {
    if (self.ddp.webSocket.readyState == SR_OPEN) {
        return;
    }
    [self.ddp connectWebSocket];
}

#pragma mark Meteor Data Managment

- (void)_makeMeteorDataSubscriptions {
    for (NSString *key in [self.subscriptions allKeys]) {
        NSString *uid = [BSONIdGenerator generate];
        [self.subscriptions setObject:uid forKey:key];  
        NSArray *params = self.subscriptionsParameters[key];
        [self.ddp subscribeWith:uid name:key parameters:params];
    }
}

# pragma mark Meteor SRP Wrapper

- (NSString *)generateAuthVerificationKeyWithUsername:(NSString *)username password:(NSString *)password {
    self.userName = username;
    self.password = password;
    const char *username_str = [username cStringUsingEncoding:NSASCIIStringEncoding];
    const char *password_str = [password cStringUsingEncoding:NSASCIIStringEncoding];
    self.srpUser = srp_user_new(SRP_SHA256, SRP_NG_1024, username_str, password_str, NULL, NULL);
    srp_user_start_authentication(self.srpUser);
    return [NSString stringWithCString:self.srpUser->Astr encoding:NSASCIIStringEncoding];
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
    srp_user_process_meteor_challenge(self.srpUser, password_str, salt, identity, B, &Mstr);
    NSString *M_final = [NSString stringWithCString:Mstr encoding:NSASCIIStringEncoding];
    NSArray *params = @[@{@"srp":@{@"M":M_final}}];
    [self sendWithMethodName:@"login" parameters:params];
}

- (void)didReceiveHAMKVerificationWithResponse:(NSDictionary *)response {
    srp_user_verify_meteor_session(self.srpUser, [response[@"HAMK"] cStringUsingEncoding:NSASCIIStringEncoding]);
    if (srp_user_is_authenticated) {
        self.sessionToken = response[@"token"];
        self.userId = response[@"id"];
        [self.authDelegate authenticationWasSuccessful];
        srp_user_delete(self.srpUser);
        self.userIsLoggingIn = NO;
        self.usingAuth = YES;
        self.loggedIn = YES;
    }
}

@end
