#import "NSData+DDPHex.h"

@implementation NSData (DDPHex)

- (NSString *)ddp_toHex {
	const char *data = self.bytes;
	size_t length = self.length;
	char *s, *buffer;
	s = buffer = malloc(self.length*2);
	
	static char hex[16] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };
	for (size_t i = 0; i < length; i++) {
		*buffer++ = hex[(data[i] & 0xf0) >> 4];
		*buffer++ = hex[(data[i] & 0x0f)];
	}
	*buffer = 0;
	
	return [[NSString alloc] initWithBytesNoCopy:s length:length*2 encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

@end
