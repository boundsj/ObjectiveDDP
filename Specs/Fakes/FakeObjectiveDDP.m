#import "FakeObjectiveDDP.h"

@implementation FakeObjectiveDDP

- (void)succeedWebSocket {
    [self.delegate didOpen];
}

- (void)succeedMeteorConnect {
    NSDictionary *connectedMessage = @{@"msg": @"connected"};
    [self.delegate didReceiveMessage:connectedMessage];
}

@end
