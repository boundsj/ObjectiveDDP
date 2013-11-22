#import "DependencyProvider.h"
#import "MeteorClient.h"
#import "MeteorClient+Private.h"
#import "BSONIdGenerator.h"
#import "srp.h"

NSString * const MeteorClientDidConnectNotification = @"boundsj.objectiveddp.connected";
NSString * const MeteorClientDidDisconnectNotification = @"boundsj.objectiveddp.disconnected";
NSString * const MeteorClientTransportErrorDomain = @"boundsj.objectiveddp.transport";


@implementation MeteorClient

- (id)init {
    self = [super init];
    if (self) {
        _collections = [NSMutableDictionary dictionary];
        _subscriptions = [NSMutableDictionary dictionary];
        _subscriptionsParameters = [NSMutableDictionary dictionary];
        _methodIds = [NSMutableSet set];
        _retryAttempts = 0;
        _responseCallbacks = [NSMutableDictionary dictionary];
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
        [_methodIds addObject:methodId];
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

- (NSString *)callMethodName:(NSString *)methodName parameters:(NSArray *)parameters responseCallback:(MeteorClientMethodCallback)responseCallback {
    if (![self okToSend]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"You are not connected"};
        NSError *notConnectedError = [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientNotConnectedError userInfo:userInfo];
        responseCallback(nil, notConnectedError);
        return nil;
    }
    NSString *methodId = [self _send:YES parameters:parameters methodName:methodName];
    if (responseCallback) {
        _responseCallbacks[methodId] = [responseCallback copy];
    }
    return methodId;
}

- (void)addSubscription:(NSString *)subscriptionName {
    [self addSubscription:subscriptionName withParameters:nil];
}

- (void)addSubscription:(NSString *)subscriptionName withParameters:(NSArray *)parameters {
    NSString *uid = [BSONIdGenerator generate];
    [_subscriptions setObject:uid forKey:subscriptionName];
    if (parameters) {
        [_subscriptionsParameters setObject:parameters forKey:subscriptionName];
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
    NSString *uid = [_subscriptions objectForKey:subscriptionName];
    if (uid) {
        [self.ddp unsubscribeWith:uid];
        // XXX: Should we really remove sub until we hear back from sever?
        [_subscriptions removeObjectForKey:subscriptionName];
    }
}

- (BOOL)okToSend {
    if (!self.connected || (_usingAuth && !_loggedIn)) {
        return NO;
    }
    return YES;
}

- (void)logonWithUsername:(NSString *)username password:(NSString *)password {
    if (self.userIsLoggingIn) return;
    NSArray *params = @[@{@"A": [self generateAuthVerificationKeyWithUsername:username password:password],
                          @"user": @{@"email":username}}];
    _usingAuth = NO;
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
        if (_sessionToken) {
            [self.ddp methodWithId:[BSONIdGenerator generate]
                            method:@"login"
                        parameters:@[@{@"resume": _sessionToken}]];
        }
        [self _makeMeteorDataSubscriptions];
    }
    
    if (msg && [msg isEqualToString:@"ready"]) {
        NSArray *subs = message[@"subs"];
        for(NSString *readySubscription in subs) {
            for(NSString *subscriptionName in _subscriptions) {
                NSString *curSubId = _subscriptions[subscriptionName];
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
    _websocketReady = YES;
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
    _websocketReady = NO;
    self.connected = NO;
    [self _invalidateUnresolvedMethods];
    [self performSelector:@selector(_reconnect)
               withObject:self
               afterDelay:5.0];
    [[NSNotificationCenter defaultCenter] postNotificationName:MeteorClientDidDisconnectNotification object:self];
}

- (void)_invalidateUnresolvedMethods {
    for (NSString *methodId in _methodIds) {
        MeteorClientMethodCallback callback = _responseCallbacks[methodId];
        callback(nil, [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientNotConnectedError userInfo:@{NSLocalizedDescriptionKey: @"You were disconnected"}]);
    }
    [_methodIds removeAllObjects];
    [_responseCallbacks removeAllObjects];
}

- (void)_reconnect {
    if (self.ddp.webSocket.readyState == SR_OPEN) {
        return;
    }
    [self.ddp connectWebSocket];
}

#pragma mark Meteor Data Managment

- (void)_makeMeteorDataSubscriptions {
    for (NSString *key in [_subscriptions allKeys]) {
        NSString *uid = [BSONIdGenerator generate];
        [_subscriptions setObject:uid forKey:key];
        NSArray *params = _subscriptionsParameters[key];
        [self.ddp subscribeWith:uid name:key parameters:params];
    }
}

# pragma mark Meteor SRP Wrapper

- (NSString *)generateAuthVerificationKeyWithUsername:(NSString *)username password:(NSString *)password {
    _userName = username;
    _password = password;
    const char *username_str = [username cStringUsingEncoding:NSASCIIStringEncoding];
    const char *password_str = [password cStringUsingEncoding:NSASCIIStringEncoding];
    _srpUser = srp_user_new(SRP_SHA256, SRP_NG_1024, username_str, password_str, NULL, NULL);
    srp_user_start_authentication(_srpUser);
    return [NSString stringWithCString:_srpUser->Astr encoding:NSASCIIStringEncoding];
}

- (void)didReceiveLoginChallengeWithResponse:(NSDictionary *)response {
    NSString *B_string = response[@"B"];
    const char *B = [B_string cStringUsingEncoding:NSASCIIStringEncoding];
    NSString *salt_string = response[@"salt"];
    const char *salt = [salt_string cStringUsingEncoding:NSASCIIStringEncoding];
    NSString *identity_string = response[@"identity"];
    const char *identity = [identity_string cStringUsingEncoding:NSASCIIStringEncoding];
    const char *password_str = [_password cStringUsingEncoding:NSASCIIStringEncoding];
    const char *Mstr;
    srp_user_process_meteor_challenge(_srpUser, password_str, salt, identity, B, &Mstr);
    NSString *M_final = [NSString stringWithCString:Mstr encoding:NSASCIIStringEncoding];
    NSArray *params = @[@{@"srp":@{@"M":M_final}}];
    [self sendWithMethodName:@"login" parameters:params];
}

- (void)didReceiveHAMKVerificationWithResponse:(NSDictionary *)response {
    srp_user_verify_meteor_session(_srpUser, [response[@"HAMK"] cStringUsingEncoding:NSASCIIStringEncoding]);
    if (srp_user_is_authenticated) {
        _sessionToken = response[@"token"];
        self.userId = response[@"id"];
        [self.authDelegate authenticationWasSuccessful];
        srp_user_delete(_srpUser);
        self.userIsLoggingIn = NO;
        _usingAuth = YES;
        self.loggedIn = YES;
    }
}

@end
