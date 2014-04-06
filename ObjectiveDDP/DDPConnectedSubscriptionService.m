#import "DDPConnectedSubscriptionService.h"

@implementation DDPConnectedSubscriptionService : NSObject 

- (void)makeSubscriptionsWithDDP:(ObjectiveDDP *)ddp subscriptions:(NSDictionary *)subscriptions {
    for (NSString *name in subscriptions.allKeys) {
        NSDictionary *subscription = subscriptions[name];
        NSString *uid = subscription[@"uid"];
        NSArray *params = subscription [@"params"];
        [ddp subscribeWith:uid name:name parameters:params];
    }
}

@end
