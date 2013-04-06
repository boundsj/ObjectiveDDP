#import "MockSRWebSocket.h"

@implementation MockSRWebSocket

- (void)success {
   [self.delegate webSocketDidOpen:self];
}

- (void)open {

}

@end