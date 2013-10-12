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

- (SRPUser *)provideSRPUserWithUserName:(NSString *)userName password:(NSString *)password {
    const char *username_str = [userName cStringUsingEncoding:NSASCIIStringEncoding];
    const char *password_str = [password cStringUsingEncoding:NSASCIIStringEncoding];
    return srp_user_new(SRP_SHA256, SRP_NG_1024, username_str, password_str, strlen(password_str), NULL, NULL);
}

@end
