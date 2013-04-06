#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@interface MockSRWebSocket : SRWebSocket

- (void)success;

@property (nonatomic, assign) id <SRWebSocketDelegate> delegate;

@end