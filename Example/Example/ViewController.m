#import "ViewController.h"
#import <ObjectiveDDP/ObjectiveDDP.h>

@interface ViewController () <ObjectiveDDPDelegate>
@property (strong, nonatomic) ObjectiveDDP *ddp;
@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    self.ddp = [[ObjectiveDDP alloc] initWithURLString:@"wss://ddptester.meteor.com/websocket" delegate:self];
    
    [self.ddp reconnect];
}

#pragma mark <ObjectiveDDPDelegate>

- (void)didOpen
{
    // implement me
}

@end
