#import "FakeDependencyProvider.h"
#import "MockSRWebSocket.h"

@implementation FakeDependencyProvider

- (SRWebSocket *)provideSRWebSocketWithRequest:(NSURLRequest *)request {
    if (self.fakeSRWebSocket) {
        return self.fakeSRWebSocket;
    }
    
    return [super provideSRWebSocketWithRequest:request];
}

@end
