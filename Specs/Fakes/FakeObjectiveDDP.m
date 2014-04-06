#import "FakeObjectiveDDP.h"

@implementation FakeObjectiveDDP

- (void)succeedWebSocket {
    [self.delegate didOpen];
}

- (void)succeedMeteorConnect {
    NSDictionary *connectedMessage = @{@"msg": @"connected"};
    [self.delegate didReceiveMessage:connectedMessage];
}

- (void)connectWithSession:(NSString *)session version:(NSString *)version support:(NSString *)support {
    
}

@end
