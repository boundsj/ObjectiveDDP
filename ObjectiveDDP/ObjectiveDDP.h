#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@protocol ObjectiveDDPDelegate;

@interface ObjectiveDDP : NSObject <SRWebSocketDelegate>

@property (strong, nonatomic) SRWebSocket *_webSocket;
@property (copy, nonatomic) NSString *urlString;
@property (assign, nonatomic) id <ObjectiveDDPDelegate> delegate;

- (id)initWithURLString:(NSString *)urlString
               delegate:(id <ObjectiveDDPDelegate>)delegate;

- (void)reconnect;

@end

@protocol ObjectiveDDPDelegate

@optional
- (void)didOpen;

@end
