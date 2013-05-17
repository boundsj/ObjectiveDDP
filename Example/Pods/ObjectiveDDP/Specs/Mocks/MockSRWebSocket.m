#import "MockSRWebSocket.h"

@implementation MockSRWebSocket

- (void)connectionSuccess {
   [self.delegate webSocketDidOpen:self];
}

- (void)connectionFailure {
    NSError *error = [[NSError alloc] initWithDomain:@"domain"
                                                code:42
                                            userInfo:nil];
    [self.delegate webSocket:self didFailWithError:error];
}

- (void)respondWithJSONString:(NSString *)json {
    [self.delegate webSocket:self didReceiveMessage:json];
}

- (void)open { /* mock no op */ }
- (void)send:(id)data { /* mock no op */ }

@end