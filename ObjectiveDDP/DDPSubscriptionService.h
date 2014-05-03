#import <Foundation/Foundation.h>
#import "ObjectiveDDP.h"

@protocol DDPMeteorSubscribing <NSObject>

- (void)makeSubscriptionsWithDDP:(ObjectiveDDP *)ddp subscriptions:(NSArray *)subscriptions;

@end