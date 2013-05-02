#import "ListViewController.h"
#import "ViewController.h"

@interface ListViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) NSMutableArray *lists;

@end

@implementation ListViewController

// TODO: Add list deletion

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
               meteor:(MeteorClient *)meteor {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.meteor = meteor;
        self.lists = self.meteor.subscriptions[@"lists"];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.title = @"My Lists";
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveUpdate)
                                                 name:@"added"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveUpdate {
    [self.tableview reloadData];
}

#pragma mark <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.lists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"list";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }

    NSDictionary *list = self.lists[indexPath.row];
    cell.textLabel.text = list[@"name"];

    return cell;
}

#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *list = self.lists[indexPath.row];
    ViewController *controller = [[ViewController alloc] initWithNibName:@"ViewController"
                                                                  bundle:nil
                                                                  meteor:self.meteor
                                                                listName:list[@"name"]];
    controller.userId = self.userId;
    [self.navigationController pushViewController:controller animated:YES];
}

@end
