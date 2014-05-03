#import "DDPConnectedSubscriptionService.h"

@implementation DDPConnectedSubscriptionService : NSObject 

- (void)makeSubscriptionsWithDDP:(ObjectiveDDP *)ddp subscriptions:(NSArray *)subscriptions {
    for (NSDictionary *subscription in subscriptions) {
        NSString *name = subscription[@"name"];
        NSString *uid = subscription[@"uid"];
        NSArray *params = subscription[@"params"];
        [ddp subscribeWith:uid name:name parameters:params];
    }
}

@end
