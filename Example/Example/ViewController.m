#import "ViewController.h"
#import "MeteorClient.h"

@interface ViewController ()
//@property (strong, nonatomic) NSMutableArray *things;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (copy, nonatomic) NSString *userId;
@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
//        self.things = [NSMutableArray array];
    }
    return self;
}

- (IBAction)didTouchAdd:(id)sender {
    AddViewController *addController = [[AddViewController alloc] initWithNibName:@"AddViewController"
                                                                           bundle:nil];
    addController.delegate = self;
    [self presentViewController:addController animated:YES completion:nil];
}

#pragma mark <ObjectiveDDPDelegate>

- (void)didOpen {
    NSLog(@"================> didOpen");

//    // Clear any in memory data from previous subscriptions
//    // (in case app is woken from background and needs to re-subscribe)
//    [self.things removeAllObjects];
//
//    // Send a connect message
//    [self.ddp connectWithSession:nil version:@"pre1" support:nil];
//
//    // Make nessesary data subscriptions to meteor server
//    // TODO: If there is a cached sub id, it would probably be better to use that here
//    //       This would be the case if the app is woken from background
//    NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
//    [self.ddp subscribeWith:uid name:@"things" parameters:nil];
}

- (void)didReceiveMessage:(NSDictionary *)message {
//    NSLog(@"================> didReceiveMessage: %@", message);
//
//    // Meteor sent us something, deal with it
//    [self _parseMessage:message];
}

// TODO: refactor this mess
- (void)_parseMessage:(NSDictionary *)message {
//    NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
//    NSString *msg = [message objectForKey:@"msg"];
//
//    // a thing was added to the things collection
//    if (msg && [msg isEqualToString:@"added"] && [message[@"collection"] isEqualToString:@"things"]) {
//        [self _parseAdded:message];
//
//    // a thing was removed from the things collection
//    } else if (msg && [msg isEqualToString:@"removed"] && [message[@"collection"] isEqualToString:@"things"]) {
//        [self _parseRemoved:message];
//
//    // meteor is not happy with us, note that fact and move on
//    } else if (message[@"error"]) {
//        NSLog(@"================> got error from meteor server, doing nothing, you should check it out");
//    }
}

- (void)_parseRemoved:(NSDictionary *)message {
    NSString *removedId = [message objectForKey:@"id"];
    int indexOfRemovedThing = 0;

    //for (NSDictionary *thing in self.things) {
    for (NSDictionary *thing in self.meteor.subscriptions[@"things"]) {
           if ([thing[@"id"] isEqualToString:removedId]) {
               break;
           }
           indexOfRemovedThing++;
        }
    //[self.things removeObjectAtIndex:indexOfRemovedThing];
    [self.meteor.subscriptions[@"things"] removeObjectAtIndex:indexOfRemovedThing];
    [self.tableview reloadData];
}

//- (void)_parseAdded:(NSDictionary *)message {
//    NSMutableDictionary *thing = [NSMutableDictionary dictionaryWithDictionary:@{@"id": message[@"id"]}];
//    for (id key in message[@"fields"]) {
//            thing[key] = message[@"fields"][key];
//        }
////    [self.things addObject:thing];
//    [self.meteor.subscriptions[@"things"] addObject:thing];
//    [self.tableview reloadData];
//}

- (void)didReceiveConnectionError:(NSError *)error {
    NSLog(@"================> didReceiveConnectionError: %@", error);
}

#pragma mark <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //return self.things.count;
    return [self.meteor.subscriptions[@"things"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"thing";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }

//    NSDictionary *thing = self.things[indexPath.row];
    NSDictionary *thing = self.meteor.subscriptions[@"things"][indexPath.row];
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
//        NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
//        NSDictionary *thing = self.things[indexPath.row];
//
//        // Specifically NOT removing the object locally
//        // we'll get a notification from the meteor server when this has been done
//        // and that'll cause us to update our local cache:
//        //
//        //  [self.things removeObject:thing];
//
//        [self.ddp methodWith:uid
//                      method:@"/things/remove"
//                  parameters:@[@{@"_id": thing[@"id"]}]];
    }
}

- (void)didAddThing:(NSString *)message {
    [self dismissViewControllerAnimated:YES completion:nil];

//    NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
//
//    [self.ddp methodWith:uid
//                  method:@"/things/insert"
//              parameters:@[@{@"_id": uid,
//                           @"msg": message,
//                           @"owner": self.userId}]];
}

#pragma mark <DDPDataDelegate>

- (void)didReceiveUpdate {
    [self.tableview reloadData];
}

@end
