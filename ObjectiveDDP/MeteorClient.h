#import "ObjectiveDDP.h"
#import "srp/srp.h"

@protocol DDPAuthDelegate;

@interface MeteorClient : NSObject<ObjectiveDDPDelegate>

@property (strong, nonatomic) ObjectiveDDP *ddp;
@property (weak, nonatomic) id<DDPAuthDelegate> authDelegate;
@property (strong, nonatomic) NSMutableDictionary *subscriptions;
@property (strong, nonatomic) NSMutableDictionary *subscriptionsParameters;
@property (strong, nonatomic) NSMutableSet *methodIds;
@property (strong, nonatomic) NSMutableDictionary *collections;
@property (copy, nonatomic) NSString *sessionToken;
@property (copy, nonatomic) NSString *userId;
@property (assign, nonatomic) BOOL websocketReady;
@property (assign, nonatomic) BOOL connected;
@property (assign, nonatomic) int retryAttempts;
@property (copy, nonatomic) NSString *password;
@property (copy, nonatomic) NSString *userName;
@property (assign, nonatomic) BOOL userIsLoggingIn;
@property (assign, nonatomic) BOOL usingAuth;
@property (assign, nonatomic) BOOL loggedIn;

// auth
// TODO: break out into sep class
@property (assign, nonatomic) SRPUser *srpUser;

- (NSString *)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters notifyOnResponse:(BOOL)notify;
- (void)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters;
- (void)addSubscription:(NSString *)subscriptionName;
- (void)addSubscription:(NSString *)subscriptionName withParameters:(NSArray *)parameters;
- (void)removeSubscription:(NSString *)subscriptionName;
- (void)resetCollections;
- (void)logonWithUsername:(NSString *)username password:(NSString *)password;
- (void)logout;

// auth
// TODO: break out in to sep class
- (NSString *)generateAuthVerificationKeyWithUsername:(NSString *)username password:(NSString *)password;
- (void)didReceiveLoginChallengeWithResponse:(NSDictionary *)response;
- (void)didReceiveHAMKVerificationWithResponse:(NSDictionary *)response;

@end

@protocol DDPAuthDelegate <NSObject>

- (void)authenticationWasSuccessful;
- (void)authenticationFailed:(NSString *)reason;

@end



