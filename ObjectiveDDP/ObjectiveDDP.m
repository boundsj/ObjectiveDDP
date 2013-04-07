#import "ObjectiveDDP.h"

@implementation ObjectiveDDP

- (id)initWithURLString:(NSString *)urlString
               delegate:(id <ObjectiveDDPDelegate>)delegate {
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

#pragma mark Public API

//connect (client -> server)
//  session: string (if trying to reconnect to an existing DDP session)
//  version: string (the proposed protocol version)
//  support: array of strings (protocol versions supported by the client, in order of preference)
- (void)connectWithSession:(NSString *)session
                   version:(NSString *)version
                   support:(NSString *)support {
    NSMutableDictionary *fields= [self _buildFields:version];
    NSString *json= [self _buildJSON:fields];
    [self.webSocket send:json];
}

// connect to the underlying websocket
- (void)reconnect {
    [self _closeConnection];
    [self.webSocket open];
}

#pragma mark private utilities

- (NSString *)_buildJSON:(NSMutableDictionary *)fields {
    NSData *data = [NSJSONSerialization dataWithJSONObject:fields
                                                   options:nil
                                                     error:nil];
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}

- (NSMutableDictionary *)_buildFields:(NSString *)version {
    NSMutableDictionary *fields = [NSMutableDictionary dictionary];
    [fields setObject:@"connect" forKey:@"msg"];
    [fields setObject:version forKey:@"version"];
    return fields;
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
    [self _setupWebSocket];
}

#pragma mark <SRWebSocketDelegate>

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    [self.delegate didOpen];
}

- (void)webSocket:(SRWebSocket *)webSocket
 didFailWithError:(NSError *)error {
    [self.delegate didReceiveConnectionError:error];

}

- (void)webSocket:(SRWebSocket *)webSocket
didReceiveMessage:(id)message {
    NSLog(@"================> did recieve message");
}

@end
