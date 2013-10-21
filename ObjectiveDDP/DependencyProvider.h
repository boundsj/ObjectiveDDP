#import <Foundation/Foundation.h>
#import "srp/srp.h"

@class SRWebSocket;

@interface DependencyProvider : NSObject

+ (DependencyProvider *)sharedProvider;
- (SRWebSocket *)provideSRWebSocketWithRequest:(NSURLRequest *)request;

@end
