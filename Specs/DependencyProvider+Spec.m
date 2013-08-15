#import "DependencyProvider.h"
#import "DDPSpecHelper.h"

@implementation DependencyProvider (Spec)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (DependencyProvider *)sharedProvider {
    return fakeProvider;
}

#pragma clang diagnostic pop

@end
