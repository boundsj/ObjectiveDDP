#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@interface MockSRWebSocket : SRWebSocket

- (void)connectionSuccess;
- (void)connectionFailure;
- (void)respondWithJSONString:(NSString *)json;

@property (nonatomic, assign) id <SRWebSocketDelegate> delegate;

@end