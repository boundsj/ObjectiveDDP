#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@protocol ObjectiveDDPDelegate;

@interface ObjectiveDDP : NSObject <SRWebSocketDelegate>

@property (copy, nonatomic) NSString *urlString;
@property (assign, nonatomic) id <ObjectiveDDPDelegate> delegate;
@property (strong, nonatomic) SRWebSocket *webSocket;

// This is exposed (in the absense of a DI framework) to allow
// for injection of a different (i.e. mock) SRWebSocket object
// if desired - it's required because the impl creates a new
// SRWebSocket object for every connectWebSocket call so storing a
// function that handles it allows us to create whatever kind
// of SRWebSocket we want (concretely, either a new one or a mock)
@property (copy, nonatomic) SRWebSocket * (^getSocket)(NSURLRequest *);

- (id)initWithURLString:(NSString *)urlString
               delegate:(id <ObjectiveDDPDelegate>)delegate;

- (void)connectWebSocket;

- (void)connectWithSession:(NSString *)session
                   version:(NSString *)version
                   support:(NSString *)support;

- (void)subscribeWith:(NSString *)id
                 name:(NSString *)name
           parameters:(NSArray *)parameters;

- (void)methodWith:(NSString *)id
            method:(NSString *)method
        parameters:(NSArray *)parameters;

@end


@protocol ObjectiveDDPDelegate

- (void)didOpen;
- (void)didReceiveMessage:(NSDictionary *)message;
- (void)didReceiveConnectionError:(NSError *)error;

@end
