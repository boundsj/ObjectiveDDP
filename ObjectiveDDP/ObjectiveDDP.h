#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@protocol ObjectiveDDPDelegate;

@interface ObjectiveDDP : NSObject <SRWebSocketDelegate>

@property (copy, nonatomic) NSString *urlString;
@property (assign, nonatomic) id <ObjectiveDDPDelegate> delegate;
@property (strong, nonatomic) SRWebSocket *webSocket;

// This is exposed (in the absense of a DI framework) to allow
// for injection of a different (i.e. mock) SRWebSocket object
// if desired
@property (copy, nonatomic) SRWebSocket * (^getSocket)(NSURLRequest *);

- (id)initWithURLString:(NSString *)urlString
               delegate:(id <ObjectiveDDPDelegate>)delegate;

- (void)reconnect;
- (void)connectWithSession:(NSString *)session
                   version:(NSString *)version
                   support:(NSString *)support;

@end


@protocol ObjectiveDDPDelegate

- (void)didOpen;
- (void)didReceiveConnectionError:(NSError *)error;

@end
