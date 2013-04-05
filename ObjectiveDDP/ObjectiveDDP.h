#import <Foundation/Foundation.h>

@protocol ObjectiveDDPDelegate;

@interface ObjectiveDDP : NSObject

@property (copy, nonatomic) NSString *urlString;
@property (weak, nonatomic) id <ObjectiveDDPDelegate> delegate;

- (id)initWithURLString:(NSString *)urlString
               delegate:(id <ObjectiveDDPDelegate>)delegate;

- (void)reconnect;

@end

@protocol ObjectiveDDPDelegate

@optional
- (void)didOpen;

@end
