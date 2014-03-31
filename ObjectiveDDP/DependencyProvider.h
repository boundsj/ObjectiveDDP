#import <Foundation/Foundation.h>
#import "ObjectiveDDP.h"

@class SRWebSocket;

@interface DependencyProvider : NSObject

+ (DependencyProvider *)sharedProvider;
- (SRWebSocket *)provideSRWebSocketWithRequest:(NSURLRequest *)request;
- (ObjectiveDDP *)provideObjectiveDDPWithConnectionString:(NSString *)connectionString delegate:(id<ObjectiveDDPDelegate>)delegate;

@end
