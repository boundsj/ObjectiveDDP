#import "DependencyProvider.h"
#import <jetfire/JFWebsocket.h>

@implementation DependencyProvider

static DependencyProvider *sharedProvider = nil;

+ (DependencyProvider *)sharedProvider {
    if (!sharedProvider) {
        sharedProvider = [[DependencyProvider alloc] init];
    }
    return sharedProvider;
}

- (JFWebSocket *)provideJFWebSocketWithURL:(NSURL *)url {
    return [[JFWebSocket alloc] initWithURL:url protocols:@[@"DDP"]];
}

@end
