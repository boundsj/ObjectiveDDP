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

// connect to the underlying websocket
- (void)connectWebSocket {
    [self _closeConnection];
    [self.webSocket open];
}

//connect (client -> server)
//  session: string (if trying to connectWebSocket to an existing DDP session)
//  version: string (the proposed protocol version)
//  support: array of strings (protocol versions supported by the client, in order of preference)
- (void)connectWithSession:(NSString *)session
                   version:(NSString *)version
                   support:(NSString *)support {
    NSDictionary *fields = @{@"msg": @"connect", @"version": version};
    NSString *json = [self _buildJSONWithFields:fields parameters:nil];

    [self.webSocket send:json];
}

//sub (client -> server):
//  id: string (an arbitrary client-determined identifier for this subscription)
//  name: string (the name of the subscription)
//  params: optional array of EJSON items (parameters to the subscription)
- (void)subscribeWith:(NSString *)id
                 name:(NSString *)name
           parameters:(NSArray *)parameters {
    NSDictionary *fields = @{@"msg": @"sub", @"name": name, @"id": id};
    NSString *json = [self _buildJSONWithFields:fields parameters:parameters];

    [self.webSocket send:json];
}

//method (client -> server):
//  method: string (method name)
//  params: optional array of EJSON items (parameters to the method)
//  id: string (an arbitrary client-determined identifier for this method call)
- (void)methodWith:(NSString *)id
              method:(NSString *)method
        parameters:(NSArray *)parameters {
    NSDictionary *fields = @{@"msg": @"method", @"method": method, @"id": id};
    NSString *json = [self _buildJSONWithFields:fields parameters:parameters];

    [self.webSocket send:json];
}

#pragma mark private utilities

- (NSString *)_buildJSONWithFields:(NSDictionary *)fields
                        parameters:(NSArray *)parameters {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:fields];
    if (parameters) {
        [dict setObject:parameters forKey:@"params"];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:kNilOptions
                                                     error:nil];

    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
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

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self.delegate didReceiveConnectionError:error];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    // TODO: write test case for parse error (handle)
    NSData *data = [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                               options:kNilOptions
                                                                 error:nil];
    [self.delegate didReceiveMessage:dictionary];
}

@end
