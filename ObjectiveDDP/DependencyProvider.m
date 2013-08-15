#import "DependencyProvider.h"

@implementation DependencyProvider

static DependencyProvider *sharedProvider = nil;

+ (DependencyProvider *)sharedProvider {
    if (!sharedProvider) {
        sharedProvider = [[DependencyProvider alloc] init];
    }
    return sharedProvider;
}

@end
