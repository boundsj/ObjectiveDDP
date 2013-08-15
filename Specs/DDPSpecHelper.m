#import "DDPSpecHelper.h"
#import "FakeDependencyProvider.h"

FakeDependencyProvider *fakeProvider = nil;

@implementation DDPSpecHelper

+ (void)beforeEach {
    fakeProvider = [[FakeDependencyProvider alloc] init];
}

@end
