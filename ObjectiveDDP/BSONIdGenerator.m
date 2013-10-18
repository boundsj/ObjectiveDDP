#import "BSONIdGenerator.h"

@implementation BSONIdGenerator

static NSInteger methodCallCount = 1;
+ (NSString *)generate {
  return [NSString stringWithFormat:@"%d", methodCallCount++];
}

@end
