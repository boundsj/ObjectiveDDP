#import "ObjectiveDDP.h"
#import "DependencyProvider.h"

@implementation ObjectiveDDP

- (id)initWithURLString:(NSString *)urlString
               delegate:(id <ObjectiveDDPDelegate>)delegate {
    self = [super init];
    if (self) {
        self.urlString = urlString;
        self.delegate = delegate;
    }
    return self;
}

#pragma mark - Public API

// connect to the underlying websocket
- (void)connectWebSocket {
    [self _closeConnection];
    [self _setupWebSocket];
    [self.webSocket open];
}

// disconnect from the websocket
- (void)disconnectWebSocket {
    [self _closeConnection];
}

//ping (client -> server):
//  id: string (the id for the ping)
- (void)ping:(NSString *)id {
    NSDictionary *fields = @{@"msg": @"ping"};
    if (id)
        fields = @{@"msg": @"ping", @"id": id};
    NSString *json = [self _buildJSONWithFields:fields parameters:nil];
    [self.webSocket send:json];
}

//pong (client -> server):
//  id: string (the id send with the ping)
- (void)pong:(NSString *)id {
    NSDictionary *fields = @{@"msg": @"pong"};
    if (id)
        fields = @{@"msg": @"pong", @"id": id};
    
    NSString *json = [self _buildJSONWithFields:fields parameters:nil];
    [self.webSocket send:json];
}

//connect (client -> server)
//  session: string (if trying to connectWebSocket to an existing DDP session)
//  version: string (the proposed protocol version)
//  support: array of strings (protocol versions supported by the client, in order of preference)
- (void)connectWithSession:(NSString *)session version:(NSString *)version support:(NSArray *)support {
    NSDictionary *fields = @{@"msg": @"connect", @"version": version, @"support": support};
    NSString *json = [self _buildJSONWithFields:fields parameters:nil];
    [self.webSocket send:json];
}

//sub (client -> server):
//  id: string (an arbitrary client-determined identifier for this subscription)
//  name: string (the name of the subscription)
//  params: optional array of EJSON items (parameters to the subscription)
- (void)subscribeWith:(NSString *)id name:(NSString *)name parameters:(NSArray *)parameters {
    NSDictionary *fields = @{@"msg": @"sub", @"name": name, @"id": id};
    NSString *json = [self _buildJSONWithFields:fields parameters:parameters];
    [self.webSocket send:json];
}

//unsub (client -> server):
//  id: string (an arbitrary client-determined identifier for this subscription)
- (void)unsubscribeWith:(NSString *)id {
    NSDictionary *fields = @{@"msg": @"unsub", @"id": id};
    NSString *json = [self _buildJSONWithFields:fields parameters:nil];
    [self.webSocket send:json];
}

//method (client -> server):
//  method: string (method name)
//  params: optional array of EJSON items (parameters to the method)
//  id: string (an arbitrary client-determined identifier for this method call)
- (void)methodWithId:(NSString *)id method:(NSString *)method parameters:(NSArray *)parameters {
    NSDictionary *fields = @{@"msg": @"method", @"method": method, @"id": id};
    NSString *json = [self _buildJSONWithFields:fields parameters:parameters];
    [self.webSocket send:json];
}

#pragma mark - Internal 

- (NSString *)_buildJSONWithFields:(NSDictionary *)fields parameters:(NSArray *)parameters {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:fields];
    if (parameters)
        [dict setObject:parameters forKey:@"params"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)_setupWebSocket {
    NSURL *url = [NSURL URLWithString:self.urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    self.webSocket = [[DependencyProvider sharedProvider] provideSRWebSocketWithRequest:request];
    self.webSocket.delegate = self;
}

- (void)_closeConnection {
    [self.webSocket close];
    self.webSocket = nil;
}

#pragma mark - <SRWebSocketDelegate>

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    [self.delegate didOpen];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self.delegate didReceiveConnectionError:error];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [self.delegate didReceiveConnectionClose];
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
