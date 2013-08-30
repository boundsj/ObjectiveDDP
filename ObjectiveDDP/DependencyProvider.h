#import <Foundation/Foundation.h>

@class SRWebSocket;

@interface DependencyProvider : NSObject

+ (DependencyProvider *)sharedProvider;
- (SRWebSocket *)provideSRWebSocketWithRequest:(NSURLRequest *)request;

@end
