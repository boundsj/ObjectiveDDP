#import "ObjectiveDDP.h"

@protocol DDPAuthDelegate;

extern NSString * const MeteorClientConnectionReadyNotification;
extern NSString * const MeteorClientDidConnectNotification;
extern NSString * const MeteorClientDidDisconnectNotification;

/** Errors due to transport (connection) problems will have this domain. For errors being reported
    from the backend, they will have the "errorType" key as their error domain. */
extern NSString * const MeteorClientTransportErrorDomain;

// xxx:
NS_ENUM(NSUInteger, MeteorClientError) {
    MeteorClientErrorNotConnected,
    MeteorClientErrorDisconnectedBeforeCallbackComplete,
    MeteorClientErrorLogonRejected
};

typedef NS_ENUM(NSUInteger, AuthState) {
    AuthStateNoAuth,
    AuthStateLoggingIn,
    AuthStateLoggedIn,
    /* implies using auth but not currently authorized */
    AuthStateLoggedOut
};

typedef void(^MeteorClientMethodCallback)(NSDictionary *response, NSError *error);

@interface MeteorClient : NSObject<ObjectiveDDPDelegate>

@property (nonatomic, strong) ObjectiveDDP *ddp;
@property (nonatomic, weak) id<DDPAuthDelegate> authDelegate;
@property (nonatomic, strong, readonly) NSMutableDictionary *collections;
@property (nonatomic, copy, readonly) NSString *userId;
@property (nonatomic, copy, readonly) NSString *sessionToken;
@property (nonatomic, assign, readonly) BOOL websocketReady;
@property (nonatomic, assign, readonly) BOOL connected;
@property (nonatomic, assign, readonly) AuthState authState;
@property (nonatomic, copy, readonly) NSString *ddpVersion;
@property (nonatomic, strong ,readonly) NSArray *supportedVersions;

// In flux; use "pre1" for meteor versions up to v0.8.0.1
//          use "pre2" for meteor versions v0.8.1.1 and above (until they change it again)
//          use "1" for meteor versions v0.8.9 and above
- (id)initWithDDPVersion:(NSString *)ddpVersion;

#pragma mark - Methods

- (void) logonWithSessionToken:(NSString *) sessionToken;
- (NSString *)callMethodName:(NSString *)methodName parameters:(NSArray *)parameters responseCallback:(MeteorClientMethodCallback)asyncCallback;
- (void)logonWithUsername:(NSString *)username password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback;
- (void)logonWithEmail:(NSString *)email password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback;
- (void)logonWithUsernameOrEmail:(NSString *)usernameOrEmail password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback;
- (void)logonWithUserParameters:(NSDictionary *)userParameters responseCallback:(MeteorClientMethodCallback)responseCallback;

- (void)signupWithUsernameAndEmail:(NSString *)username email:(NSString *)email password:(NSString *)password fullname:(NSString *)fullname responseCallback:(MeteorClientMethodCallback)responseCallback;
- (void)signupWithUsername:(NSString *)username password:(NSString *)password fullname:(NSString *)fullname responseCallback:(MeteorClientMethodCallback)responseCallback;
- (void)signupWithEmail:(NSString *)email password:(NSString *)password fullname:(NSString *)fullname responseCallback:(MeteorClientMethodCallback)responseCallback;
- (void)signupWithUserParameters:userParameters responseCallback:(MeteorClientMethodCallback) responseCallback;
- (void)addSubscription:(NSString *)subscriptionName;
- (void)addSubscription:(NSString *)subscriptionName withParameters:(NSArray *)parameters;
- (void)removeSubscription:(NSString *)subscriptionName;
- (void)logout;
- (void)disconnect;
- (void)reconnect;
- (void)ping;

// Deprecated methods

- (void)logonWithUsername:(NSString *)username password:(NSString *)password __attribute__((deprecated("use logonWithUsername:password:responseCallback: instead")));
- (NSString *)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters notifyOnResponse:(BOOL)notify __attribute__((deprecated("use callMethodName:parameters:responseCallback: instead")));
- (void)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters __attribute__((deprecated("use callMethodName:parameters:responseCallback: instead")));

@end

#pragma mark - <DDPAuthDelegate>

@protocol DDPAuthDelegate <NSObject>

- (void)authenticationWasSuccessful;
- (void)authenticationFailed:(NSString *)reason;

@end
