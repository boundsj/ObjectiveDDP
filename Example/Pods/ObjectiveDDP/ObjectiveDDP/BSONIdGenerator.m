#import "BSONIdGenerator.h"
#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access

@implementation BSONIdGenerator
static int _incr = 0;

/*!
 * @discussion Generates a BSON Object Id. Code sampled from
 *   https://github.com/mongodb/mongo-c-driver/blob/master/src/bson.c and the BSON Object Id specification
 *   http://www.mongodb.org/display/DOCS/Object+IDs
 */
+ (NSString *) generate {
  int i = _incr++;
  bson_oid_t *oid = malloc(sizeof(bson_oid_t));
  time_t t = time(NULL);

  // Grab the PID
  int pid = [NSProcessInfo processInfo].processIdentifier;

  // Get a device identifier. The specification usually has this as the MAC address
  // or hostname but we already have a unique device identifier.
  //
  // NOTE THAT UDID IS DEPRECATED. YOU SHOULD USE SOME OTHER IDENTIFIER HERE SUCH AS OPENUDID OR MAC ADDRESS.
  //NSString *identifier = [[UIDevice currentDevice] uniqueIdentifier];
  CFUUIDRef uuid = CFUUIDCreate(NULL);
  NSString *identifier  = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
  CFRelease(uuid);

  // MD5 hash the device identifier
  NSString *md5HashOfIdentifier = [self md5HashFromString:identifier];
  const char *cIdentifier = [md5HashOfIdentifier cStringUsingEncoding:NSUTF8StringEncoding];

  // Copy bytes over to our object id. Specification taken from http://www.mongodb.org/display/DOCS/Object+IDs
  bson_swap_endian_len(&oid->bytes[0], &t, 4);
  bson_swap_endian_len(&oid->bytes[4], &cIdentifier, 3);
  bson_swap_endian_len(&oid->bytes[7], &pid, 2);
  bson_swap_endian_len(&oid->bytes[9], &i, 3);
  NSString *str = [self bson_oid_to_string:oid];

  free(oid);

  return str;
}

/*!
 * @discussion Given an NSString, returns the MD5 hash of it. Taken from
 *   http://stackoverflow.com/questions/1524604/md5-algorithm-in-objective-c
 * @param source The source string
 * @return MD5 hash as a string
 */
+ (NSString *) md5HashFromString:(NSString *)source {
  const char *cStr = [source UTF8String];
  unsigned char result[16];
  CC_MD5(cStr, strlen(cStr), result);
  return [NSString stringWithFormat:
      @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
      result[0], result[1], result[2], result[3],
      result[4], result[5], result[6], result[7],
      result[8], result[9], result[10], result[11],
      result[12], result[13], result[14], result[15]
  ];
}

/*!
 * @discussion Converts a bson_oid_t to an NSString. Mostly taken from
 *   https://github.com/mongodb/mongo-c-driver/blob/master/src/bson.c
 * @param oid The bson_oid_t to convert
 * @return Autoreleased NSString of 24 hex characters
 */
+ (NSString *) bson_oid_to_string:(bson_oid_t *)oid {
  char *str = malloc(sizeof(char) * 25);
  static const char hex[16] = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'};
  int i;
  for ( i=0; i<12; i++ ) {
    str[2*i]     = hex[( oid->bytes[i] & 0xf0 ) >> 4];
    str[2*i + 1] = hex[ oid->bytes[i] & 0x0f      ];
  }
  str[24] = '\0';
  NSString *string = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
  free(str);
  return string;
}

/*!
 * @discussion The ARM architecture is little Endian while Intel Macs are big Endian,
 *   so we need to swap endianness if we're compiling on a big Endian architecture.
 * @param outp The destination pointer
 * @param inp The source pointer
 * @param len The length to copy
 */
void bson_swap_endian_len(void *outp, const void *inp, int len) {
  const char *in = (const char *)inp;
  char *out = (char *)outp;
  for (int i = 0; i < len; i ++) {
    #if __DARWIN_BIG_ENDIAN
    out[i] = in[len - 1 - i];
    #elif __DARWIN_LITTLE_ENDIAN
    out[i] = in[i];
    #endif
  }
}
@end
