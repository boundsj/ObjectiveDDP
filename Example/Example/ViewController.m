#import "ViewController.h"
#import <ObjectiveDDP/BSONIdGenerator.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (copy, nonatomic) NSString *listName;

@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
               meteor:(MeteorClient *)meteor
             listName:(NSString *) listName {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.meteor = meteor;
        self.listName = listName;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.title = self.listName;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc ] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                target:self
                                                                                action:@selector(didTouchAdd:)];
    [self.navigationItem setRightBarButtonItem:addButton];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveUpdate:)
                                                 name:@"added"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveUpdate:)
                                                 name:@"removed"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveUpdate:(NSNotification *)notification {
    [self.tableview reloadData];
}

- (NSArray *)computedList {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(listName like %@)", self.listName];
    return [self.meteor.collections[@"things"] filteredArrayUsingPredicate:pred];
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
    return [self.computedList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"thing";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }

    NSDictionary *thing = self.computedList[indexPath.row];
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
        NSDictionary *thing = self.computedList[indexPath.row];

        // Specifically NOT removing the object locally
        // we'll get a notification from the meteor server when this has been done
        // and that'll cause us to update our local cache:
        //
        //  [self.things removeObject:thing];

        // Could implement meteor style "latency compensation" by removing here
        // and syncing subscription to server later

        [self.meteor sendWithMethodName:@"/things/remove"
                             parameters:@[@{@"_id": thing[@"_id"]}]];
    }
}

- (void)didAddThing:(NSString *)message {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *uid = [[BSONIdGenerator generate] substringToIndex:15];
    [self.meteor sendWithMethodName:@"/things/insert"
                         parameters:@[@{@"_id": uid,
                                      @"msg": message,
                                      @"owner": self.userId,
                                      @"listName": self.listName}]];
}

@end
