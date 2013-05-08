#import <ObjectiveDDP/ObjectiveDDP.h>

@protocol DDPAuthDelegate;

@interface MeteorClient : NSObject<ObjectiveDDPDelegate>

@property (strong, nonatomic) ObjectiveDDP *ddp;
@property (weak, nonatomic) id<DDPAuthDelegate> authDelegate;
@property (strong, nonatomic) NSMutableDictionary *subscriptions;
@property (strong, nonatomic) NSMutableDictionary *collections;


- (void)sendWithMethodName:(NSString *)methodName parameters:(NSArray *)parameters;

@end

@protocol DDPAuthDelegate <NSObject>

- (void)didConnectToMeteorServer;
- (void)didReceiveLoginChallengeWithResponse:(NSDictionary *)response;
- (void)didReceiveHAMKVerificationWithResponse:(NSDictionary *)response;

@end

