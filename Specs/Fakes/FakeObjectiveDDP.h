#import "ObjectiveDDP.h"

@interface FakeObjectiveDDP : ObjectiveDDP

- (void)succeedWebSocket;
- (void)errorWebSocketWithError:(NSError *)error;
- (void)succeedMeteorConnect;

@end
