#import "MeteorClient.h"

@interface MeteorClient () {
@public // for tests. This header is not exported anyway.
    NSMutableDictionary *_subscriptions;
    NSMutableSet *_methodIds;
    NSMutableDictionary *_responseCallbacks;
    MeteorClientMethodCallback _logonMethodCallback;
    NSString *_userName;
    NSString *_password;
    NSDictionary *_logonParams;
    NSMutableDictionary *_subscriptionsParameters;
    BOOL _disconnecting;
    double _tries;
    double _maxRetryIncrement;
}

// These are public and should be KVO compliant so use accessor instead of direct ivar access
@property (nonatomic, copy, readwrite) NSString *userId;
@property (nonatomic, copy, readwrite) NSString *sessionToken;
@property (nonatomic, assign, readwrite) BOOL connected;
@property (nonatomic, strong, readwrite) NSMutableDictionary *collections;
@property (nonatomic, assign, readwrite) BOOL websocketReady;
@property (nonatomic, assign, readwrite) AuthState authState;

//xxx: temporary methods to corral state vars
- (void)_setAuthStateToLoggingIn;
- (void)_setAuthStateToLoggedIn:(NSString *)userId withToken:()token;
- (void)_setAuthStatetoLoggedOut;
- (NSDictionary *)_buildUserParametersWithUsername:(NSString *)username password:(NSString *)password;
- (NSDictionary *)_buildUserParametersWithEmail:(NSString *)email password:(NSString *)password;
- (NSDictionary *)_buildUserParametersWithUsernameOrEmail:(NSString *)usernameOrEmail password:(NSString *)password;

@end

@interface MeteorClient (Parsing)

- (void)_handleMethodResultMessageWithMessageId:(NSString *)messageId message:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleAddedMessage:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleAddedBeforeMessage:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleMovedBeforeMessage:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleRemovedMessage:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleChangedMessage:(NSDictionary *)message msg:(NSString *)msg;

@end
