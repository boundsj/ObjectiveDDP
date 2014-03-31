#import "DependencyProvider.h"

@class FakeSRWebSocket;
@class FakeObjectiveDDP;

@interface FakeDependencyProvider : DependencyProvider

@property (nonatomic, strong) FakeSRWebSocket *fakeSRWebSocket;
@property (nonatomic, strong) FakeObjectiveDDP *fakeObjectiveDDP;
@property (nonatomic, strong) id<DDPMeteorSubscribing> fakeDDPSubscriptionService;

@end
