#import <Foundation/Foundation.h>

@class JFWebSocket;

@interface DependencyProvider : NSObject

+ (DependencyProvider *)sharedProvider;
- (JFWebSocket *)provideJFWebSocketWithURL:(NSURLRequest *)request;

@end
