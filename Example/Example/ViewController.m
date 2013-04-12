#import "ViewController.h"
#import <ObjectiveDDP/ObjectiveDDP.h>

@interface ViewController () <ObjectiveDDPDelegate>
@property (strong, nonatomic) ObjectiveDDP *ddp;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@end

@implementation ViewController

static int uniqueId = 1;

- (void)viewWillAppear:(BOOL)animated
{
    self.ddp = [[ObjectiveDDP alloc] initWithURLString:@"ws://localhost:3000/websocket"
                                              delegate:self];
    [self.ddp connectWebSocket];
}

- (void)viewDidAppear:(BOOL)animated {

    NSString *uid = [NSString stringWithFormat:@"%d", uniqueId++];
    [self.ddp subscribeWith:uid name:@"things" parameters:nil];
}

- (IBAction)didTouchSend:(id)sender {
    NSString *uid = [NSString stringWithFormat:@"%d", uniqueId++];

    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];

    [self.ddp methodWith:uid
                  method:@"/things/insert"
              parameters:@[@{@"_id": uid, @"msg": dateString}]];
}

#pragma mark <ObjectiveDDPDelegate>

- (void)didOpen {
    NSLog(@"================> didOpen");
    [self.ddp connectWithSession:nil version:@"pre1" support:nil];
}

- (void)didReceiveMessage:(NSDictionary *)message {
    NSLog(@"================> didReceiveMessage: %@", message);
}

- (void)didReceiveConnectionError:(NSError *)error {
    NSLog(@"================> didReceiveConnectionError: %@", error);
}

@end
