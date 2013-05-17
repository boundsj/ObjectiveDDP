#import <Foundation/Foundation.h>
typedef union {
  char bytes[12];
  int ints[3];
} bson_oid_t;

@interface BSONIdGenerator : NSObject
+ (NSString *) generate;
@end
