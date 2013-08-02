#import "ObjectiveDDP.h"

@protocol DDPAuthDelegate;

@interface MeteorClient : NSObject<ObjectiveDDPDelegate>

@property (strong, nonatomic) ObjectiveDDP *ddp;
@property (weak, nonatomic) id<DDPAuthDelegate> authDelegate;
@property (strong, nonatomic) NSMutableDictionary *subscriptions;
@property (strong, nonatomic) NSMutableDictionary *collections;
@property (copy, nonatomic) NSString *sessionToken;
@property (copy, nonatomic) NSString *userId;
@property (assign, nonatomic) BOOL websocketReady;

- (void)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters;
- (void)addSubscription:(NSString *)subscriptionName;
- (void)resetCollections;
- (void)logonWithUsername:(NSString *)username password:(NSString *)password;

// TODO: These methods are only temporarily public, should be impl detail of MeteorClient
- (NSString *)generateAuthVerificationKeyWithUsername:(NSString *)username password:(NSString *)password;
//- (void)processMeteorChallenge

@end

@protocol DDPAuthDelegate <NSObject>

- (void)authenticationWasSuccessful;
- (void)authenticationFailed;

@end

