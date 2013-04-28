#import <ObjectiveDDP/ObjectiveDDP.h>

@protocol DDPDataDelegate;
@protocol DDPAuthDelegate;

@interface MeteorClient : NSObject<ObjectiveDDPDelegate>

@property (strong, nonatomic) ObjectiveDDP *ddp;

// TODO: this should be an array (for multiple views that need to know about data events)
@property (weak, nonatomic) id<DDPDataDelegate> dataDelegate;

@property (weak, nonatomic) id<DDPAuthDelegate> authDelegate;

@end

@protocol DDPAuthDelegate <NSObject>

- (void) didConnectToMeteorServer;

@end
