#import "DependencyProvider.h"
#import <SocketRocket/SRWebSocket.h>
#import "ObjectiveDDP.h"

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

@end
