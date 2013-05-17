#import <UIKit/UIKit.h>

@protocol AddViewControllerDelegate;

@interface AddViewController : UIViewController

@property (assign, nonatomic) id <AddViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;

@end

@protocol AddViewControllerDelegate
- (void)didAddThing:(NSString *)message;
@end
