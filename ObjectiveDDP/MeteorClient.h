#import "ObjectiveDDP.h"

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
@property (nonatomic, assign) int retryAttempts;

- (NSString *)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters notifyOnResponse:(BOOL)notify;
- (void)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters;
- (void)addSubscription:(NSString *)subscriptionName;
- (void)addSubscription:(NSString *)subscriptionName withParameters:(NSArray *)parameters;
- (void)removeSubscription:(NSString *)subscriptionName;
- (void)resetCollections;
- (void)logonWithUsername:(NSString *)username password:(NSString *)password;
- (void)logout;

@end

@protocol DDPAuthDelegate <NSObject>

- (void)authenticationWasSuccessful;
- (void)authenticationFailed:(NSString *)reason;

@end

