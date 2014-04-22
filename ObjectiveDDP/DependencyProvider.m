#import "DependencyProvider.h"
#import "SRWebSocket.h"
#import "ObjectiveDDP.h"
#import "DDPConnectedSubscriptionService.h"

@implementation DependencyProvider

static DependencyProvider *sharedProvider = nil;

+ (DependencyProvider *)sharedProvider {
    if (!sharedProvider) {
        sharedProvider = [[DependencyProvider alloc] init];
    }
    return sharedProvider;
}

- (SRWebSocket *)provideSRWebSocketWithRequest:(NSURLRequest *)request {
    return [[SRWebSocket alloc] initWithURLRequest:request];
}

- (ObjectiveDDP *)provideObjectiveDDPWithConnectionString:(NSString *)connectionString delegate:(id<ObjectiveDDPDelegate>)delegate {
    return [[ObjectiveDDP alloc] initWithURLString:connectionString delegate:delegate];
}

- (id<DDPMeteorSubscribing>)provideDDPConnectedSubscriptionService {
    return [[DDPConnectedSubscriptionService alloc] init];
}

@end
