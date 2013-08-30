#import "DependencyProvider.h"

@implementation DependencyProvider (Spec)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

// This will create a linker warning for the Specs target but it is harmless under test

+ (DependencyProvider *)sharedProvider {
    return fakeProvider;
}

#pragma clang diagnostic pop

@end
