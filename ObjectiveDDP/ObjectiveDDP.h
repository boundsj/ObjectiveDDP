#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@protocol ObjectiveDDPDelegate;

@interface ObjectiveDDP : NSObject <SRWebSocketDelegate>

@property (copy, nonatomic) NSString *urlString;
@property (assign, nonatomic) id <ObjectiveDDPDelegate> delegate;
@property (strong, nonatomic) SRWebSocket *webSocket;

- (id)initWithURLString:(NSString *)urlString
               delegate:(id <ObjectiveDDPDelegate>)delegate;

- (void)connectWebSocket;

- (void)connectWithSession:(NSString *)session
                   version:(NSString *)version
                   support:(NSString *)support;

- (void)subscribeWith:(NSString *)id
                 name:(NSString *)name
           parameters:(NSArray *)parameters;

- (void)unsubscribeWith:(NSString *)id;

- (void)methodWith:(NSString *)id
            method:(NSString *)method
        parameters:(NSArray *)parameters;

@end


@protocol ObjectiveDDPDelegate

- (void)didOpen;
- (void)didReceiveMessage:(NSDictionary *)message;
- (void)didReceiveConnectionError:(NSError *)error;

@end
