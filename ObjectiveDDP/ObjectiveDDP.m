#import "ObjectiveDDP.h"

@implementation ObjectiveDDP

- (id)initWithURLString:(NSString *)urlString
               delegate:(id <ObjectiveDDPDelegate>)delegate
{
    self = [super init];
    
    if (self) {
        self.urlString = urlString;
        self.delegate = delegate;
        
        ////
        // until something like blindside is used, for now just
        // utilizing blocks to allow for poor man's dependancy
        // injection (i.e. this can be overriden by a test framework
        // to return a mock SRWebSocket object.
        ////
        self.getSocket = ^SRWebSocket *(NSURLRequest *request) {
            return [[SRWebSocket alloc] initWithURLRequest:request];
        };
    }
    
    return self;
}

- (void)reconnect
{
    [self _closeConnection];
    [self _setupWebSocket];
    
    [self.webSocket open];
}

- (void)_setupWebSocket {
    NSURL *url = [NSURL URLWithString:self.urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    self.webSocket = self.getSocket(request);
    self.webSocket.delegate = self;
}

- (void)_closeConnection {
    [self.webSocket close];
    self.webSocket = nil;
}

#pragma mark <SRWebSocketDelegate>

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    [self.delegate didOpen];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"================> did recieve message");
}

@end
