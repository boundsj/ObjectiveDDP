#import "ObjectiveDDP.h"

@protocol DDPAuthDelegate;

extern NSString * const MeteorClientDidConnectNotification;
extern NSString * const MeteorClientDidDisconnectNotification;

/** Errors due to transport (connection) problems will have this domain. For errors being reported
    from the backend, they will have the "errorType" key as their error domain. */
extern NSString * const MeteorClientTransportErrorDomain;

NS_ENUM(NSUInteger, MeteorClientError) {
    /** Can't perform request because client isn't connected. */
    MeteorClientErrorNotConnected,
    /** Request failed because websocket got disconnected before response arrived. */
    MeteorClientErrorDisconnectedBeforeCallbackComplete
};

typedef void(^MeteorClientMethodCallback)(NSDictionary *response, NSError *error);

@interface MeteorClient : NSObject<ObjectiveDDPDelegate>

@property (nonatomic, strong) ObjectiveDDP *ddp;
@property (nonatomic, weak) id<DDPAuthDelegate> authDelegate;
@property (nonatomic, strong, readonly) NSMutableDictionary *collections;
@property (nonatomic, copy, readonly) NSString *userId;
@property (nonatomic, assign, readonly) BOOL connected;
@property (nonatomic, assign, readonly) BOOL userIsLoggingIn;
@property (nonatomic, assign, readonly) BOOL loggedIn;
@property (nonatomic, assign, readonly) BOOL websocketReady;

#pragma mark Request/response

/** Send a request with the given methodName and parameters.
    @param notify Whether to send a "response_%d" NSNotification when response comes back
*/
- (NSString *)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters notifyOnResponse:(BOOL)notify;

/** Like sendWithMethodName:parameters:notifyOnResponse:YES but also calls your provided
    callback when the response comes back. */
- (NSString *)callMethodName:(NSString *)methodName parameters:(NSArray *)parameters responseCallback:(MeteorClientMethodCallback)asyncCallback;

/** Fire-and-forget. Forwards to sendWithMethodName:parameters:notifyOnResponse:NO. */
- (void)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters;

#pragma mark Collections and subscriptions

- (void)addSubscription:(NSString *)subscriptionName;
- (void)addSubscription:(NSString *)subscriptionName withParameters:(NSArray *)parameters;
- (void)removeSubscription:(NSString *)subscriptionName;

#pragma mark Login

- (void)logonWithUsername:(NSString *)username password:(NSString *)password;
- (void)logout;

@end

@protocol DDPAuthDelegate <NSObject>

- (void)authenticationWasSuccessful;
- (void)authenticationFailed:(NSString *)reason;

@end

