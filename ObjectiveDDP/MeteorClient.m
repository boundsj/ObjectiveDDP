#import "DependencyProvider.h"
#import "MeteorClient.h"
#import "DependencyProvider.h"
#import "MeteorClient+Private.h"
#import "BSONIdGenerator.h"
#import "NSData+DDPHex.h"
#import "DDPConnectedSubscriptionService.h"

NSString * const MeteorClientDidDisconnectNotification = @"boundsj.objectiveddp.disconnected";
NSString * const MeteorClientTransportErrorDomain = @"boundsj.objectiveddp.transport";

@interface MeteorClient ()

@property (nonatomic, strong) id<DDPMeteorSubscribing> subscriptionService;
@property (nonatomic, strong, readwrite) NSMutableArray *subscriptions;

@end

@implementation MeteorClient

- (id)init {
    self = [super init];
    if (self) {
        _collections = [NSMutableDictionary dictionary];
        _subscriptions = [NSMutableArray array];
        _methodIds = [NSMutableSet set];
        _retryAttempts = 0;
        _responseCallbacks = [NSMutableDictionary dictionary];
        _subscriptionService = [[DependencyProvider sharedProvider] provideDDPConnectedSubscriptionService];
    }
    return self;
}

- (id)initWithConnectionString:(NSString *)connectionString delegate:(id<DDPMeteorClientDelegate>)delegate {
    self = [self init];
    if (self) {
        _ddp = [[DependencyProvider sharedProvider] provideObjectiveDDPWithConnectionString:connectionString delegate:self];
        _delegate = delegate;
    }
    return self;
}

#pragma mark MeteorClient Public

- (void)connect {
    [self.ddp connectWebSocket];
}

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
    NSMutableDictionary *subscription = [@{@"name": subscriptionName, @"uid": uid} mutableCopy];
    if (parameters) {
        subscription[@"params"] = parameters;
    }
    [self.subscriptions addObject:[subscription copy]];
    
    if (![self okToSend]) {
        return;
    }
    
    [self.ddp subscribeWith:uid name:subscriptionName parameters:parameters];
}

- (void)removeSubscription:(NSString *)subscriptionName {
    if (![self okToSend]) { return; }
    
    NSDictionary *subscription = [[self.subscriptions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", subscriptionName]] lastObject];
    
    NSString *uid = subscription[@"uid"];
    
    if (uid) {
        [self.ddp unsubscribeWith:uid];
        [self.subscriptions removeObject:subscription];
    }
}

static NSString *randomId(int length) {
	static NSArray *characters;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		characters = [NSMutableArray new];
		for(char c = 'A'; c < 'Z'; c++)
			[(NSMutableArray*)characters addObject:[[NSString alloc] initWithBytes:&c length:1 encoding:NSUTF8StringEncoding]];
		for(char c = 'a'; c < 'z'; c++)
			[(NSMutableArray*)characters addObject:[[NSString alloc] initWithBytes:&c length:1 encoding:NSUTF8StringEncoding]];
		for(char c = '0'; c < '9'; c++)
			[(NSMutableArray*)characters addObject:[[NSString alloc] initWithBytes:&c length:1 encoding:NSUTF8StringEncoding]];
	});
	NSMutableString *salt = [NSMutableString new];
	for(int i = 0; i < length; i++)
		[salt appendString:characters[arc4random_uniform(characters.count)]];
	return salt;
}

- (void)signupWithUsername:(NSString *)username password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback {
    if ([self _rejectIfNotConnected:responseCallback]) {
        return;
    }
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    const unsigned char *bytes_s, *bytes_v;
    int len_s, len_v;
    NSString *identity = randomId(16);
    NSString *salt = randomId(16);
    bytes_s = (void *)[salt UTF8String];
    len_s = strlen([salt UTF8String]);
    srp_create_salted_verification_key(SRP_SHA256, SRP_NG_1024, [identity UTF8String], passwordData.bytes, passwordData.length, &bytes_s, &len_s, &bytes_v, &len_v, NULL, NULL, true);
    NSString *verifier = [[NSData dataWithBytesNoCopy:(void*)bytes_v length:len_v freeWhenDone:YES] ddp_toHex];
    NSArray *parameters = @[@{@"email": username,
                                 @"srp": @{@"identity": identity,
                                           @"salt": salt,
                                           @"verifier": verifier}}];
    [self callMethodName:@"createUser" parameters:parameters responseCallback:^(NSDictionary *response, NSError *error) {
        if (error) {
            responseCallback(nil, error);
            return;
        }
        [self logonWithUsername:username password:password responseCallback:responseCallback];
    }];
}

- (void)logonWithUsername:(NSString *)username password:(NSString *)password {
    [self logonWithUserParameters:_logonParams username:username password:password responseCallback:nil];
}

- (void)logonWithUsername:(NSString *)username password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback {
    [self logonWithUserParameters:_logonParams username:username password:password responseCallback:responseCallback];
}

- (void)logonWithUserParameters:(NSDictionary *)userParameters username:(NSString *)username password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback {
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
    
    if (!userParameters) {
        userParameters = @{@"user": @{@"email": username}};
    }
   
    NSMutableDictionary *mutableUserParameters = [userParameters mutableCopy];
    mutableUserParameters[@"A"] = [self generateAuthVerificationKeyWithUsername:username password:password];
    
    [self _setAuthStateToLoggingIn];
    
    [self callMethodName:@"beginPasswordExchange" parameters:@[mutableUserParameters] responseCallback:nil];
    _logonParams = userParameters;
    _logonMethodCallback = responseCallback;
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

#pragma mark <ObjectiveDDPDelegate>

- (void)didReceiveMessage:(NSDictionary *)message {
    NSLog(@"================> %@", message);
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
        self.connected = YES;
        
        if ([self.delegate respondsToSelector:@selector(meteorClientDidConnectToServer:)]) {
            [self.delegate meteorClientDidConnectToServer:self];
        }
        
        [self.subscriptionService makeSubscriptionsWithDDP:self.ddp subscriptions:self.subscriptions];
        
        
        // refactor_XXX: session & login mgmt should be sep object
        if (_sessionToken) {
            [self.ddp methodWithId:[BSONIdGenerator generate]
                            method:@"login"
                        parameters:@[@{@"resume": _sessionToken}]];
        }    
    }
    
    if (msg && [msg isEqualToString:@"ready"]) {
        NSArray *subs = message[@"subs"];
        for(NSString *readySubscription in subs) {
            for(NSDictionary *subscription in self.subscriptions) {
                NSString *curSubId = subscription[@"uid"];
                NSString *subscriptionName = subscription[@"name"];
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
    // refactor_XXX: remove explicit collection management in meteor client
    [self resetCollections];
    
    if ([self.delegate respondsToSelector:@selector(meteorClientDidConnectToWebsocket:)]) {
        [self.delegate meteorClientDidConnectToWebsocket:self];
    }
    [self.ddp connectWithSession:nil version:@"pre1" support:nil];
}

- (void)didReceiveConnectionError:(NSError *)error {
    [self _handleConnectionError];
    if ([self.delegate respondsToSelector:@selector(meteorClient:didReceiveWebsocketConnectionError:)]) {
        [self.delegate meteorClient:self didReceiveWebsocketConnectionError:error];
    }
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

- (void)_handleConnectionError {    
    self.connected = NO;
    [self _invalidateUnresolvedMethods];
    [[NSNotificationCenter defaultCenter] postNotificationName:MeteorClientDidDisconnectNotification object:self];
    if (_disconnecting) {
        _disconnecting = NO;
        return;
    }
    [self performSelector:@selector(_reconnect) withObject:self afterDelay:5.0];
}

- (void)_invalidateUnresolvedMethods {
    for (NSString *methodId in _methodIds) {
        MeteorClientMethodCallback callback = _responseCallbacks[methodId];
        callback(nil, [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientErrorDisconnectedBeforeCallbackComplete userInfo:@{NSLocalizedDescriptionKey: @"You were disconnected"}]);
    }
    [_methodIds removeAllObjects];
    [_responseCallbacks removeAllObjects];
}

- (BOOL)okToSend {
    if (!self.connected) {
        return NO;
    }
    return YES;
}

- (void)_reconnect {
    if (self.ddp.webSocket.readyState == SR_OPEN) {
        return;
    }
    [self.ddp connectWebSocket];
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

- (void)_setAuthStateToLoggedIn {
    self.authState = AuthStateLoggedIn;
}

- (void)_setAuthStatetoLoggedOut {
    _logonParams = nil;
    self.authState = AuthStateNoAuth;
}

# pragma mark - SRP Auth Internal

- (NSString *)generateAuthVerificationKeyWithUsername:(NSString *)username password:(NSString *)password {
    _userName = username;
    _password = password;
    const char *username_str = [username cStringUsingEncoding:NSASCIIStringEncoding];
    const char *password_str = [password cStringUsingEncoding:NSASCIIStringEncoding];
    _srpUser = srp_user_new(SRP_SHA256, SRP_NG_1024, username_str, password_str, NULL, NULL);
    srp_user_start_authentication(_srpUser);
    return [NSString stringWithCString:_srpUser->Astr encoding:NSASCIIStringEncoding];
}

@end
