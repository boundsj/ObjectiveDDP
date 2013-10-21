#import "DependencyProvider.h"
#import <SocketRocket/SRWebSocket.h>

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

@end
