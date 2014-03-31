#import "ObjectiveDDP.h"

@protocol DDPAuthDelegate;
@protocol DDPMeteorClientDelegate;

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
    AuthStateLoggedIn
};

typedef void(^MeteorClientMethodCallback)(NSDictionary *response, NSError *error);

@interface MeteorClient : NSObject<ObjectiveDDPDelegate>

// keeping these around so they can be set/overwritten individually if user wants
@property (nonatomic, strong) ObjectiveDDP *ddp;
@property (nonatomic, weak) id<DDPMeteorClientDelegate> delegate;
@property (nonatomic, weak) id<DDPAuthDelegate> authDelegate;

// refactor_XXX: we will no longer be maintaining collections
//               by default
@property (nonatomic, strong, readonly) NSMutableDictionary *collections;

@property (nonatomic, copy, readonly) NSString *userId;


// refactor_XXX: carefully review public exposed state stuff
@property (nonatomic, assign, readonly) BOOL connected;
@property (nonatomic, assign, readonly) AuthState authState;





- (id)initWithConnectionString:(NSString *)connectionString delegate:(id<DDPMeteorClientDelegate>)delegate;
- (void)connect;
- (NSString *)callMethodName:(NSString *)methodName parameters:(NSArray *)parameters responseCallback:(MeteorClientMethodCallback)asyncCallback;
- (void)logonWithUsername:(NSString *)username password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback;
- (void)logonWithUserParameters:(NSDictionary *)userParameters username:(NSString *)username password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback;
- (void)signupWithUsername:(NSString *)username password:(NSString *)password responseCallback:(MeteorClientMethodCallback)responseCallback;
- (void)addSubscription:(NSString *)subscriptionName;
- (void)addSubscription:(NSString *)subscriptionName withParameters:(NSArray *)parameters;
- (void)removeSubscription:(NSString *)subscriptionName;
- (void)logout;
- (void)disconnect;

// Deprecated methods

- (void)logonWithUsername:(NSString *)username password:(NSString *)password __attribute__((deprecated("use logonWithUsername:password:responseCallback: instead")));
- (NSString *)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters notifyOnResponse:(BOOL)notify __attribute__((deprecated("use callMethodName:parameters:responseCallback: instead")));
- (void)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters __attribute__((deprecated("use callMethodName:parameters:responseCallback: instead")));

@end

@protocol DDPAuthDelegate <NSObject>

- (void)authenticationWasSuccessful;
- (void)authenticationFailed:(NSString *)reason;

@end

@protocol DDPMeteorClientDelegate <NSObject>

- (void)meteorClientDidConnectToWebsocket:(MeteorClient *)meteorClient;
- (void)meteorClientDidConnectToServer:(MeteorClient *)meteorClient;

@end
