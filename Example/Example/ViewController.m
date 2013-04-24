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
const unsigned char * bytes_B = 0;
const unsigned char * bytes_M = 0;
const unsigned char * bytes_HAMK = 0;

int len_s   = 0;
int len_v   = 0;
int len_B   = 0;
int len_M   = 0;

const char * username = "jesse@rebounds.net";
const char * password = "airport";

const char * auth_username = 0;

SRP_HashAlgorithm alg     = SRP_SHA256;
SRP_NGType        ng_type = SRP_NG_1024;

// TODO: remove this and use BSONIDGenerator
// TODO: Make BSONIDGenerator a pods package, I think
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

    NSArray *params = @[@{@"A": [self generateVerificationKey],
                          @"user": @{@"email":@"jesse@rebounds.net"}}];

    [self.ddp methodWith:uid
                  method:@"beginPasswordExchange"
              parameters:params];
}

- (NSString *)generateVerificationKey {

    const unsigned char * bytes_A = 0;
    int len_A   = 0;
    const char * Astr = 0;

    /* Begin authentication process */
    usr = srp_user_new(alg,
            ng_type,
            username,
            password,
            strlen(password),
            NULL,
            NULL);

    srp_user_start_authentication(usr,
            &auth_username,
            &bytes_A,
            &len_A,
            &Astr);

    self.A_string = [NSString stringWithCString:Astr encoding:NSASCIIStringEncoding];

    return self.A_string;
}

// TODO: remove this when M comes back as char *
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

    // Clear any in memory data from previous subscriptions
    // (in case app is woken from background and needs to re-subscribe)
    [self.things removeAllObjects];

    // Send a connect message
    [self.ddp connectWithSession:nil version:@"pre1" support:nil];

    // Make nessesary data subscriptions to meteor server
    // TODO: If there is a cached sub id, it would probably be better to use that here
    //       This would be the case if the app is woken from background
    NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
    [self.ddp subscribeWith:uid name:@"things" parameters:nil];
}

- (void)didReceiveMessage:(NSDictionary *)message {
    NSLog(@"================> didReceiveMessage: %@", message);

    // Meteor sent us something, deal with it
    [self _parseMessage:message];
}

// TODO: refactor this mess
- (void)_parseMessage:(NSDictionary *)message {
    NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
    NSString *msg = [message objectForKey:@"msg"];

    // a thing was added to the things collection
    if (msg && [msg isEqualToString:@"added"] && [message[@"collection"] isEqualToString:@"things"]) {
        [self _parseAdded:message];

    // a thing was removed from the things collection
    } else if (msg && [msg isEqualToString:@"removed"] && [message[@"collection"] isEqualToString:@"things"]) {
        [self _parseRemoved:message];

    // meteor login challenge
    } else if (msg && [msg isEqualToString:@"result"]
                   && message[@"result"]
                   && message[@"result"][@"identity"]
                   && message[@"result"][@"salt"]) {

        NSString *B_string = message[@"result"][@"B"];
        const  char *B = [B_string cStringUsingEncoding:NSASCIIStringEncoding];

        NSString *salt_string = message[@"result"][@"salt"];
        const  char *salt = [salt_string cStringUsingEncoding:NSASCIIStringEncoding];

        NSString *identity_string = message[@"result"][@"identity"];
        const  char *identity = [identity_string cStringUsingEncoding:NSASCIIStringEncoding];

        // TODO: should not need to do this since srp library stores off Astr in usr struct
        //       after srp refactor to use it's own Astr, remove this AND the saving of it above
        const char *A = [self.A_string cStringUsingEncoding:NSASCIIStringEncoding];

        // TODO: these should be able to be removed, they are not used
        len_s = 0;
        len_B = 0;

        // TODO: only need usr, salt, ident, B (although might want to stick with the pass be reference API tradition for Mstr
        //       instead of returning M_ret...
        const char * M_ret = srp_user_respond_to_meteor_challenge(usr, bytes_B, len_B, bytes_s, len_s, salt, identity, A, B, &bytes_M, &len_M);
        NSString *M_final = [NSString stringWithCString:M_ret encoding:NSASCIIStringEncoding];

        NSArray *params = @[@{@"srp":@{@"M":M_final}}];

        // send login (challenge reponse) to meteor
        [self.ddp methodWith:uid
                      method:@"login"
                  parameters:params];

    // meteor is not happy with us, note that fact and move on
    } else if (message[@"error"]) {
        NSLog(@"================> got error from meteor server, doing nothing, you should check it out");
    }
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
              parameters:@[@{@"_id": uid,
                           @"msg": message,
                           // TODO: owner is hard coded here, should store owner (id) when we get the HAMK response
                           @"owner": @"o2gPnQ4nJ6hmeax6d"}]];
}

@end
