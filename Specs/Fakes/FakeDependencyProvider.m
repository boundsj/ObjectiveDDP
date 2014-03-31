#import "FakeDependencyProvider.h"
#import "FakeSRWebSocket.h"
#import "FakeObjectiveDDP.h"

@implementation FakeDependencyProvider

- (SRWebSocket *)provideSRWebSocketWithRequest:(NSURLRequest *)request {
    if (self.fakeSRWebSocket) {
        return self.fakeSRWebSocket;
    }
    
    return [super provideSRWebSocketWithRequest:request];
}

- (ObjectiveDDP *)provideObjectiveDDPWithConnectionString:(NSString *)connectionString delegate:(id<ObjectiveDDPDelegate>)delegate {
    
    if (self.fakeObjectiveDDP) {
        self.fakeObjectiveDDP.urlString = connectionString;
        self.fakeObjectiveDDP.delegate = delegate;
        return self.fakeObjectiveDDP;
    }

    return [super provideObjectiveDDPWithConnectionString:connectionString delegate:delegate];
}

@end
