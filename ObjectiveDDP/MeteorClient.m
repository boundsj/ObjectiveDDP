#import <CommonCrypto/CommonDigest.h>
#import "DependencyProvider.h"
#import "MeteorClient.h"
#import "MeteorClient+Private.h"
#import "BSONIdGenerator.h"

NSString * const MeteorClientConnectionReadyNotification = @"bounsj.objectiveddp.ready";
NSString * const MeteorClientDidConnectNotification = @"boundsj.objectiveddp.connected";
NSString * const MeteorClientDidDisconnectNotification = @"boundsj.objectiveddp.disconnected";
NSString * const MeteorClientTransportErrorDomain = @"boundsj.objectiveddp.transport";

double const MeteorClientRetryIncreaseBy = 1;
double const MeteorClientMaxRetryIncrease = 6;

@interface MeteorClient ()

@property (nonatomic, copy, readwrite) NSString *ddpVersion;

@end

@implementation MeteorClient

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithDDPVersion:(NSString *)ddpVersion {
    self = [super init];
    if (self) {
        _collections = [NSMutableDictionary dictionary];
        _subscriptions = [NSMutableDictionary dictionary];
        _subscriptionsParameters = [NSMutableDictionary dictionary];
        _methodIds = [NSMutableSet set];
        _responseCallbacks = [NSMutableDictionary dictionary];
        _ddpVersion = ddpVersion;
        _maxRetryIncrement = MeteorClientMaxRetryIncrease;
        _tries = MeteorClientRetryIncreaseBy;
        if ([ddpVersion isEqualToString:@"1"]) {
            _supportedVersions = @[@"1", @"pre2"];
        } else {
            _supportedVersions = @[@"pre2", @"pre1"];
        }
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
    if (![self okToSend]) {
        return nil;
    }
    return [self _send:notify parameters:parameters methodName:methodName];
}

- (NSString *)callMethodName:(NSString *)methodName parameters:(NSArray *)parameters responseCallback:(MeteorClientMethodCallback)responseCallback {
    if ([self _rejectIfNotConnected:responseCallback]) {
        return nil;
    };
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

- (void)removeSubscription:(NSString *)subscriptionName {
    if (![self okToSend]) {
        return;
    }
    NSString *uid = [_subscriptions objectForKey:subscriptionName];
    if (uid) {
        [self.ddp unsubscribeWith:uid];
        [_subscriptions removeObjectForKey:subscriptionName];
    }
}

- (BOOL)okToSend {
    if (!self.connected) {
        return NO;
    }
    return YES;
}

- (void) logonWithSessionToken:(NSString *) sessionToken {
    self.sessionToken = sessionToken;
    [self.ddp methodWithId:[BSONIdGenerator generate]
                    method:@"login"
                parameters:@[@{@"resume": self.sessionToken}]];
    
}

- (void)logonWithUsername:(NSString *)username password:(NSString *)password {
    [self logonWithUserParameters:[self _buildUserParametersWithUsername:username password:password] responseCallback:nil];
}

- (void)logonWithUsername:(NSString *)username password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback {
    [self logonWithUserParameters:[self _buildUserParametersWithUsername:username password:password] responseCallback:responseCallback];
}

- (void)logonWithEmail:(NSString *)email password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback {
    [self logonWithUserParameters:[self _buildUserParametersWithEmail:email password:password] responseCallback:responseCallback];
}

- (void)logonWithUsernameOrEmail:(NSString *)usernameOrEmail password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback {
    [self logonWithUserParameters:[self _buildUserParametersWithUsernameOrEmail:usernameOrEmail password:password] responseCallback:responseCallback];
}

- (void)logonWithUserParameters:(NSDictionary *)userParameters responseCallback:(MeteorClientMethodCallback)responseCallback {
    if (self.authState == AuthStateLoggingIn) {
        NSString *errorDesc = [NSString stringWithFormat:@"You must wait for the current logon request to finish before sending another."];
        NSError *logonError = [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientErrorLogonRejected userInfo:@{NSLocalizedDescriptionKey: errorDesc}];
        if (responseCallback) {
            responseCallback(nil, logonError);
        }
        return;
    }
    [self _setAuthStateToLoggingIn];
    
    if ([self _rejectIfNotConnected:responseCallback]) {
        return;
    }
    
    NSMutableDictionary *mutableUserParameters = [userParameters mutableCopy];
    
    [self callMethodName:@"login" parameters:@[mutableUserParameters] responseCallback:^(NSDictionary *response, NSError *error) {
        if (error) {
            [self _setAuthStatetoLoggedOut];
        } else {
            [self _setAuthStateToLoggedIn:response[@"result"][@"id"] withToken:response[@"result"][@"token"]];
        }
        responseCallback(response, error);
    }];
    
    _logonParams = userParameters;
    _logonMethodCallback = responseCallback;
}

- (void)signupWithUsernameAndEmail:(NSString *)username email:(NSString *)email password:(NSString *)password fullname:(NSString *)fullname responseCallback:(MeteorClientMethodCallback)responseCallback {
    [self signupWithUserParameters:[self _buildUserParametersSignup:username email:email password:password fullname:fullname] responseCallback:responseCallback];
}

- (void)signupWithUsername:(NSString *)username password:(NSString *)password fullname:(NSString *)fullname responseCallback:(MeteorClientMethodCallback)responseCallback {
    [self signupWithUserParameters:[self _buildUserParametersSignup:username email:@"" password:password fullname:fullname] responseCallback:responseCallback];
}

- (void)signupWithEmail:(NSString *)email password:(NSString *)password fullname:(NSString *)fullname responseCallback:(MeteorClientMethodCallback)responseCallback {
    [self signupWithUserParameters:[self _buildUserParametersSignup:@"" email:email password:password fullname:fullname] responseCallback:responseCallback];
}

- (void)signupWithUserParameters:userParameters responseCallback:(MeteorClientMethodCallback) responseCallback {
	if (self.authState == AuthStateLoggingIn) {
        NSString *errorDesc = [NSString stringWithFormat:@"You must wait for the current signup request to finish before sending another."];
        NSError *logonError = [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientErrorLogonRejected userInfo:@{NSLocalizedDescriptionKey: errorDesc}];
        if (responseCallback) {
            responseCallback(nil, logonError);
        }
        return;
    }
    [self _setAuthStateToLoggingIn];
    
	
    NSMutableDictionary *mutableUserParameters = [userParameters mutableCopy];
    
    [self callMethodName:@"createUser" parameters:@[mutableUserParameters] responseCallback:^(NSDictionary *response, NSError *error) {
        if (error) {
            [self _setAuthStatetoLoggedOut];
        } else {
            [self _setAuthStateToLoggedIn:response[@"result"][@"id"] withToken:response[@"result"][@"token"]];
        }
        responseCallback(response, error);
    }];
}


// move this to string category
- (NSString *)sha256:(NSString *)clear {
    const char *s = [clear cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [NSData dataWithBytes:s length:strlen(s)];
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH] = {0};
    CC_SHA256(keyData.bytes, (unsigned int)keyData.length, digest);
    NSData *digestData = [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    NSString *hash = [digestData description];
    
    // refactor this
    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    return hash;
}

- (void)logout {
    [self.ddp methodWithId:[BSONIdGenerator generate]
                    method:@"logout"
                parameters:nil];
    [self _setAuthStatetoLoggedOut];
}

- (void)disconnect {
    _disconnecting = YES;
    [self.ddp disconnectWebSocket];
}

- (void)reconnect {
    if (self.ddp.webSocket.readyState == SR_OPEN) {
        return;
    }
    [self.ddp connectWebSocket];
}

- (void)ping {
    if (!self.connected) {
        return;
    }
    [self.ddp ping:[BSONIdGenerator generate]];
}

#pragma mark <ObjectiveDDPDelegate>

- (void)didReceiveMessage:(NSDictionary *)message {
    NSString *msg = [message objectForKey:@"msg"];
    
    if (!msg) return;
    
    NSString *messageId = message[@"id"];
    
    [self _handleMethodResultMessageWithMessageId:messageId message:message msg:msg];
    [self _handleAddedMessage:message msg:msg];
    [self _handleAddedBeforeMessage:message msg:msg];
    [self _handleMovedBeforeMessage:message msg:msg];
    [self _handleRemovedMessage:message msg:msg];
    [self _handleChangedMessage:message msg:msg];

    if ([msg isEqualToString:@"ping"]) {
        [self.ddp pong:messageId];
    }
    
    if ([msg isEqualToString:@"connected"]) {
        self.connected = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:MeteorClientConnectionReadyNotification object:self];
        if (self.sessionToken) {
            [self logonWithSessionToken:self.sessionToken];
        }
        [self _makeMeteorDataSubscriptions];
    }
    
    if ([msg isEqualToString:@"ready"]) {
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
    
    else if ([msg isEqualToString:@"updated"]) {
        NSArray *methods = message[@"methods"];
        for(NSString *updateMethod in methods) {
            for(NSString *methodId in _methodIds) {
                if([methodId isEqualToString:updateMethod]) {
                    NSString *notificationName = [NSString stringWithFormat:@"%@_update", methodId];
                    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
                    break;
                }
            }
        }
    }
    
    else if ([msg isEqualToString:@"addedBefore"]) {
        
    }
    
    else if ([msg isEqualToString:@"movedBefore"]) {
        
    }
    
    else if ([msg isEqualToString:@"nosub"]) {
        
    }
    
    else if ([msg isEqualToString:@"error"]) {
        
    }
}

- (void)didOpen {
    self.websocketReady = YES;
    [self _resetBackoff];
    [self resetCollections];
    [self.ddp connectWithSession:nil version:self.ddpVersion support:self.supportedVersions];
    [[NSNotificationCenter defaultCenter] postNotificationName:MeteorClientDidConnectNotification object:self];
}

- (void)didReceiveConnectionError:(NSError *)error {
    [self _handleConnectionError];
}

- (void)didReceiveConnectionClose {
    [self _handleConnectionError];
}

#pragma mark - Internal

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

- (void)_resetBackoff {
    _tries = 1;
}

- (void)_handleConnectionError {
    self.websocketReady = NO;
    self.connected = NO;
    [self _invalidateUnresolvedMethods];
    [[NSNotificationCenter defaultCenter] postNotificationName:MeteorClientDidDisconnectNotification object:self];
    if (_disconnecting) {
        _disconnecting = NO;
        return;
    }
//
    double timeInterval = 5.0 * _tries;
    
    if (_tries != _maxRetryIncrement) {
        _tries++;
    }
    [self performSelector:@selector(reconnect) withObject:self afterDelay:timeInterval];
}

- (void)_invalidateUnresolvedMethods {
    for (NSString *methodId in _methodIds) {
        MeteorClientMethodCallback callback = _responseCallbacks[methodId];
        callback(nil, [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientErrorDisconnectedBeforeCallbackComplete userInfo:@{NSLocalizedDescriptionKey: @"You were disconnected"}]);
    }
    [_methodIds removeAllObjects];
    [_responseCallbacks removeAllObjects];
}

- (void)_makeMeteorDataSubscriptions {
    for (NSString *key in [_subscriptions allKeys]) {
        NSString *uid = [BSONIdGenerator generate];
        [_subscriptions setObject:uid forKey:key];
        NSArray *params = _subscriptionsParameters[key];
        [self.ddp subscribeWith:uid name:key parameters:params];
    }
}

- (BOOL)_rejectIfNotConnected:(MeteorClientMethodCallback)responseCallback {
    if (![self okToSend]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"You are not connected"};
        NSError *notConnectedError = [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientErrorNotConnected userInfo:userInfo];
        if (responseCallback) {
            responseCallback(nil, notConnectedError);
        }
        return YES;
    }
    return NO;
}

- (void)_setAuthStateToLoggingIn {
    self.authState = AuthStateLoggingIn;
}

- (void)_setAuthStateToLoggedIn:(NSString *)userId withToken:()token {
    self.authState = AuthStateLoggedIn;
    self.userId = userId;
    self.sessionToken = token;
}

- (void)_setAuthStatetoLoggedOut {
    _logonParams = nil;
    self.authState = AuthStateLoggedOut;
    self.userId = nil;
}

- (NSDictionary *)_buildUserParametersSignup:(NSString *)username email:(NSString *)email password:(NSString *)password fullname:(NSString *) fullname
{
    return @{ @"username": username,@"email": email,
              @"password": @{ @"digest": [self sha256:password], @"algorithm": @"sha-256" },
              @"profile": @{ @"fullname": fullname,
                             @"signupToken": @""
                             } };
}

- (NSDictionary *)_buildUserParametersWithUsername:(NSString *)username password:(NSString *)password
{
    return @{ @"user": @{ @"username": username }, @"password": @{ @"digest": [self sha256:password], @"algorithm": @"sha-256" } };
}

- (NSDictionary *)_buildUserParametersWithEmail:(NSString *)email password:(NSString *)password
{
    return @{ @"user": @{ @"email": email }, @"password": @{ @"digest": [self sha256:password], @"algorithm": @"sha-256" } };
}

- (NSDictionary *)_buildUserParametersWithUsernameOrEmail:(NSString *)usernameOrEmail password:(NSString *)password
{
    if ([usernameOrEmail rangeOfString:@"@"].location == NSNotFound) {
        return [self _buildUserParametersWithUsername:usernameOrEmail password:password];
    } else {
        return [self _buildUserParametersWithEmail:usernameOrEmail password:password];
    }
}

@end
