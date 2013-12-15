#import "MeteorClient.h"

// declare C linkage in case of C++ (tests)
#ifdef __cplusplus
extern "C" {
#endif
#import "srp.h"
#ifdef __cplusplus
}
#endif

@interface MeteorClient () {
@public // for tests. This header is not exported anyway.
    NSMutableDictionary *_subscriptions;
    NSMutableSet *_methodIds;
    NSMutableDictionary *_responseCallbacks;
    MeteorClientMethodCallback _logonMethodCallback;
    int _retryAttempts;
    NSString *_userName;
    NSString *_password;
    NSDictionary *_logonParams;
    NSMutableDictionary *_subscriptionsParameters;
    NSString *_sessionToken;
    SRPUser *_srpUser;
    BOOL _disconnecting;
}

// These are public and should be KVO compliant so use accessor instead of direct ivar access
@property (nonatomic, copy, readwrite) NSString *userId;
@property (nonatomic, assign, readwrite) BOOL connected;
@property (nonatomic, strong, readwrite) NSMutableDictionary *collections;
@property (nonatomic, assign, readwrite) BOOL websocketReady;
@property (nonatomic, assign, readwrite) AuthState authState;

//xxx: temporary methods to corral state vars
- (void)_setAuthStateToLoggingIn;
- (void)_setAuthStateToLoggedIn;
- (void)_setAuthStatetoLoggedOut;

@end

@interface MeteorClient (Parsing)

- (void)_handleMethodResultMessageWithMessageId:(NSString *)messageId message:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleLoginChallengeResponse:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleLoginError:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleHAMKVerification:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleAddedMessage:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleRemovedMessage:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleChangedMessage:(NSDictionary *)message msg:(NSString *)msg;

# pragma mark - SRP Auth Parsing
- (void)didReceiveLoginChallengeWithResponse:(NSDictionary *)response;
- (void)didReceiveHAMKVerificationWithResponse:(NSDictionary *)response;

@end
