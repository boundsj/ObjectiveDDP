@implementation NSObject (Spec)

- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay {
    [self performSelectorOnMainThread:aSelector withObject:self waitUntilDone:YES];
}

@end
