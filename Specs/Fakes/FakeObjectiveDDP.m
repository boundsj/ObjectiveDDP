#import "FakeObjectiveDDP.h"

@implementation FakeObjectiveDDP

- (void)succeedWebSocket {
    [self.delegate didOpen];
}

@end
