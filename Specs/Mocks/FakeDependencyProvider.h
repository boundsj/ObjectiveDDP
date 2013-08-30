#import "DependencyProvider.h"

@class MockSRWebSocket;

@interface FakeDependencyProvider : DependencyProvider

@property (nonatomic, assign) MockSRWebSocket *fakeSRWebSocket;

@end
