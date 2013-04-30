#import "ViewController.h"
#import "BSONIdGenerator.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UITableView *tableview;

@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

#pragma mark UI Actions

- (IBAction)didTouchAdd:(id)sender {
    AddViewController *addController = [[AddViewController alloc] initWithNibName:@"AddViewController"
                                                                           bundle:nil];
    addController.delegate = self;
    [self presentViewController:addController animated:YES completion:nil];
}

#pragma mark <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.meteor.subscriptions[@"things"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"thing";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }

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
        NSDictionary *thing = self.meteor.subscriptions[@"things"][indexPath.row];

        // Specifically NOT removing the object locally
        // we'll get a notification from the meteor server when this has been done
        // and that'll cause us to update our local cache:
        //
        //  [self.things removeObject:thing];

        // Could implement meteor style "latency compensation" by removing here
        // and syncing subscription to server later

        [self.meteor sendWithMethodName:@"/things/remove"
                             parameters:@[@{@"_id": thing[@"id"]}]];
    }
}

- (void)didAddThing:(NSString *)message {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
    [self.meteor sendWithMethodName:@"/things/insert"
                         parameters:@[@{@"_id": uid,
                                      @"msg": message,
                                      @"owner": self.userId}]];
}

#pragma mark <DDPDataDelegate>

- (void)didReceiveUpdate {
    [self.tableview reloadData];
}

@end
