#import "ObjectiveDDP.h"
#import "SRWebSocket.h"

@interface ObjectiveDDP () <SRWebSocketDelegate>
@property (strong, nonatomic) SRWebSocket *_webSocket;
@end

@implementation ObjectiveDDP

- (id)initWithURLString:(NSString *)urlString
               delegate:(id <ObjectiveDDPDelegate>)delegate
{
    self = [super init];
    
    if (self) {
        self.urlString = urlString;
        self.delegate = delegate;
    }
    
    return self;
}

- (void)reconnect {
    self._webSocket = nil;
    [self._webSocket close];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]];
    self._webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
    self._webSocket.delegate = self;
    NSLog(@"=========> Opening connection");
    [self._webSocket open];
}

#pragma mark <SRWebSocketDelegate>

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"================> did open");
    [self.delegate didOpen];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"================> did recieve message");
}

@end
