#import <Foundation/Foundation.h>
#import "ObjectiveDDP.h"
#import "DDPConnectedSubscriptionService.h"

@class SRWebSocket;

@interface DependencyProvider : NSObject

+ (DependencyProvider *)sharedProvider;
- (SRWebSocket *)provideSRWebSocketWithRequest:(NSURLRequest *)request;
- (ObjectiveDDP *)provideObjectiveDDPWithConnectionString:(NSString *)connectionString delegate:(id<ObjectiveDDPDelegate>)delegate;
- (id<DDPMeteorSubscribing>)provideDDPConnectedSubscriptionService;

@end
