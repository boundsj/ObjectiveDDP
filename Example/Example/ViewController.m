#import "ViewController.h"
#import <ObjectiveDDP/ObjectiveDDP.h>

@interface ViewController () <ObjectiveDDPDelegate>

@property (strong, nonatomic) NSMutableArray *things;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UITableView *tableview;

@end

@implementation ViewController

static int uniqueId = 1;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibBundleOrNil bundle:nibBundleOrNil];
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
    NSString *msg = [message objectForKey:@"msg"];
    if (msg && [msg isEqualToString:@"added"] && [message[@"collection"] isEqualToString:@"things"]) {
        [self _parseAdded:message];
    } else if (msg && [msg isEqualToString:@"removed"] && [message[@"collection"] isEqualToString:@"things"]) {
        [self _parseRemoved:message];
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
    NSString *uid = [NSString stringWithFormat:@"%d", uniqueId++];
    [self.ddp methodWith:uid
                  method:@"/things/insert"
              parameters:@[@{@"_id": uid, @"msg": message}]];
}

@end
