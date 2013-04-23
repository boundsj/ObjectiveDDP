#import "ViewController.h"
#import "BSONIdGenerator.h"
#import "srp.h"
#import "bn.h"

@interface ViewController ()

@property (strong, nonatomic) NSMutableArray *things;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UITableView *tableview;

@end

@implementation ViewController

struct SRPVerifier * ver;
struct SRPUser     * usr;

const unsigned char * bytes_s = 0;
const unsigned char * bytes_v = 0;
const unsigned char * bytes_A = 0;
const unsigned char * bytes_B = 0;
const unsigned char * bytes_M = 0;
const unsigned char * bytes_HAMK = 0;

int len_s   = 0;
int len_v   = 0;
int len_A   = 0;
int len_B   = 0;
int len_M   = 0;

const char * username = "jesse@rebounds.net";
const char * password = "airport";


const char * auth_username = 0;

SRP_HashAlgorithm alg     = SRP_SHA256;
SRP_NGType        ng_type = SRP_NG_1024;


static int uniqueId = 1;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.things = [NSMutableArray array];
    }
    return self;
}

- (IBAction)didTouchAdd:(id)sender {
    AddViewController *addController = [[AddViewController alloc] initWithNibName:@"AddViewController"
                                                                           bundle:nil];
    addController.delegate = self;
    [self presentViewController:addController animated:YES completion:nil];
}

- (IBAction)didTouchLoginButton:(id)sender {
    NSLog(@"login");
    NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];

    NSArray *params = @[@{@"A": [self get_verification_key], @"user": @{@"email":@"jesse@rebounds.net"}}];
    //NSArray *params = @[@{@"A": @"e770dcfbdf6c94cf4a912f3a3b51929cd0040510aaaa3863476c727e6fe44402a7b00ae8ae094a2bedce635895bba6a7147dffec8ed9414bb521c839c4aa92209f6af62ca49af75230427d4a8ce748c9a475575cf471cded74bc4ac613e264a9713564021dace95d1baae2dde41cfeb80052ab69403b6d0cb5bcdcb4096fe689", @"user": @{@"email":@"jesse@rebounds.net"}}];
    [self.ddp methodWith:uid
                  method:@"beginPasswordExchange"
              parameters:params];
}

- (NSString *)get_verification_key {
    /* Begin authentication process */
    usr =  srp_user_new( alg, ng_type, username,
            (const unsigned char *)password,
            strlen(password), NULL, NULL );

    srp_user_start_authentication( usr, &auth_username, &bytes_A, &len_A );

    NSData *data = [NSData dataWithBytes:bytes_A length:len_A];
    self.A_string =  [self _getHexByteStringWithData: data];
    NSLog(@"========. A ==> %@", self.A_string);
    return [self _getHexByteStringWithData: data];
}

- (NSString *)_getHexByteStringWithData:(NSData *)data {
    NSUInteger dataLength = [data length];
    NSMutableString *string = [NSMutableString stringWithCapacity:dataLength*2];
    const unsigned char *dataBytes = [data bytes];
    for (NSInteger idx = 0; idx < dataLength; ++idx) {
        [string appendFormat:@"%02x", dataBytes[idx]];
    }
    return string;
}

#pragma mark <ObjectiveDDPDelegate>

- (void)didOpen {
    NSLog(@"================> didOpen");
    [self.things removeAllObjects];


    [self.ddp connectWithSession:nil version:@"pre1" support:nil];

    NSString *uid = [NSString stringWithFormat:@"%d", uniqueId++];
    [self.ddp subscribeWith:uid name:@"things" parameters:nil];
}

- (void)didReceiveMessage:(NSDictionary *)message {
    NSLog(@"================> didReceiveMessage: %@", message);
    [self _parseMessage:message];
}

- (void)_parseMessage:(NSDictionary *)message {
    NSString *uid = [NSString stringWithFormat:@"%d", uniqueId++];

    NSString *msg = [message objectForKey:@"msg"];
    if (msg && [msg isEqualToString:@"added"] && [message[@"collection"] isEqualToString:@"things"]) {
        [self _parseAdded:message];
    } else if (msg && [msg isEqualToString:@"removed"] && [message[@"collection"] isEqualToString:@"things"]) {
        [self _parseRemoved:message];
    } else if (msg && [msg isEqualToString:@"result"] && message[@"result"] && message[@"result"][@"salt"]) {
        if (message[@"error"]) {
            NSLog(@"================> got error, stopping");
            return;
        }

        NSString *B_string = message[@"result"][@"B"];
        const  char *B = [B_string cStringUsingEncoding:NSASCIIStringEncoding];
        //NSMutableData *BBytes = [self processHexString:B];

        NSString *salt_string = message[@"result"][@"salt"];
        const  char *salt = [salt_string cStringUsingEncoding:NSASCIIStringEncoding];

        NSString *identity_string = message[@"result"][@"identity"];
        const  char *identity = [identity_string cStringUsingEncoding:NSASCIIStringEncoding];

        const char *A = [self.A_string cStringUsingEncoding:NSASCIIStringEncoding];
        NSLog(@"=====> %@", self.A_string);

//        bytes_s = (unsigned char *) [saltBytes bytes];
//        const unsigned char *dataBytesSalt = [saltBytes bytes];

//        bytes_B = (unsigned char *) [BBytes bytes];
//        const unsigned char *dataBytesB = [BBytes bytes];

        //int len_s = [saltBytes length];
        len_s = 0;
        //int len_B = [BBytes length];
        len_B = 0;

        const char * M_ret = srp_user_respond_to_meteor_challenge(usr, bytes_B, len_B, bytes_s, len_s, salt, identity, A, B, &bytes_M, &len_M);
        
        NSString *M_final = [NSString stringWithCString:M_ret encoding:NSASCIIStringEncoding];

        NSData *data = [NSData dataWithBytes:bytes_M length:len_M];
        NSString *M = [self _getHexByteStringWithData: data];
        NSLog(@"============= M ==>: %@", M_final);

        //NSArray *params = @[@{@"srp":@{@"M":@"a0b8b63f136c3691b729e8b985128d53f29634ac93af24d2265587c5b2a5cba4"}}];
        NSArray *params = @[@{@"srp":@{@"M":M_final}}];
        [self.ddp methodWith:uid
                      method:@"login"
                  parameters:params];
    }
    
    // still not correct
    // idea: capture send salt, ident, A, B and run through meteor code manually to compare M values
}

- (NSMutableData *)processHexString:(NSString *)salt {
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= salt.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [salt substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

- (void)_parseRemoved:(NSDictionary *)message {
    NSString *removedId = [message objectForKey:@"id"];
    int indexOfRemovedThing = 0;
    for (NSDictionary *thing in self.things) {
           if ([thing[@"id"] isEqualToString:removedId]) {
               break;
           }
           indexOfRemovedThing++;
        }
    [self.things removeObjectAtIndex:indexOfRemovedThing];
    [self.tableview reloadData];
}

- (void)_parseAdded:(NSDictionary *)message {
    NSMutableDictionary *thing = [NSMutableDictionary dictionaryWithDictionary:@{@"id": message[@"id"]}];
    for (id key in message[@"fields"]) {
            thing[key] = message[@"fields"][key];
        }
    [self.things addObject:thing];
    [self.tableview reloadData];
}

- (void)didReceiveConnectionError:(NSError *)error {
    NSLog(@"================> didReceiveConnectionError: %@", error);
}

#pragma mark <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.things.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"thing";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }

    NSDictionary *thing = self.things[indexPath.row];
    cell.textLabel.text = thing[@"msg"];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView
        canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView
        commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
        forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *uid = [NSString stringWithFormat:@"%d", uniqueId++];
        NSDictionary *thing = self.things[indexPath.row];

        // Specifically NOT removing the object locally
        // we'll get a notification from the meteor server when this has been done
        // and that'll cause us to update our local cache:
        //
        //  [self.things removeObject:thing];

        [self.ddp methodWith:uid
                      method:@"/things/remove"
                  parameters:@[@{@"_id": thing[@"id"]}]];
    }
}

- (void)didAddThing:(NSString *)message {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
    [self.ddp methodWith:uid
                  method:@"/things/insert"
              parameters:@[@{@"_id": uid, @"msg": message}]];
}

@end
