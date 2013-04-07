#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@interface MockSRWebSocket : SRWebSocket

- (void)success;
- (void)failure;

@property (nonatomic, assign) id <SRWebSocketDelegate> delegate;

@end