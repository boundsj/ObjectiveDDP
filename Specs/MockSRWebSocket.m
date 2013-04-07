#import "MockSRWebSocket.h"

@implementation MockSRWebSocket

- (void)success {
   [self.delegate webSocketDidOpen:self];
}

- (void)failure {
    NSError *error = [[NSError alloc] initWithDomain:@"domain"
                                                code:42
                                            userInfo:nil];
    [self.delegate webSocket:self didFailWithError:error];
}

- (void)open { /* mock no op */ }
- (void)send:(id)data { /* mock no op */ }

@end