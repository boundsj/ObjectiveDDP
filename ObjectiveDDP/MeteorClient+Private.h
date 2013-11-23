#import "MeteorClient.h"

#ifdef __cplusplus
extern "C" {
#endif
#import "srp.h"
#ifdef __cplusplus
}
#endif

@interface MeteorClient ()
{
@public // for tests. This header is not exported anyway.
    NSMutableDictionary *_subscriptions;
    BOOL _websocketReady;
    BOOL _usingAuth;
    NSMutableSet *_methodIds;
    NSMutableDictionary *_responseCallbacks;
    int _retryAttempts;
    NSString *_userName;
    NSString *_password;
    NSMutableDictionary *_subscriptionsParameters;
    NSString *_sessionToken;
    // TODO: break out auth into separate class
    SRPUser *_srpUser;
}
// These are public and should be KVO compliant so use accessor instead of direct ivar access
@property(copy, nonatomic, readwrite) NSString *userId;
@property(assign, nonatomic, readwrite) BOOL connected;
@property(assign, nonatomic, readwrite) BOOL loggedIn;
@property(assign, nonatomic, readwrite) BOOL userIsLoggingIn;
@property(strong, nonatomic, readwrite) NSMutableDictionary *collections;

- (void)didReceiveLoginChallengeWithResponse:(NSDictionary *)response;
- (void)didReceiveHAMKVerificationWithResponse:(NSDictionary *)response;
@end

@interface MeteorClient (Parsing)
- (void)_handleMethodResultMessageWithMessageId:(NSString *)messageId message:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleLoginChallengeResponse:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleLoginError:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleHAMKVerification:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleAddedMessage:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleRemovedMessage:(NSDictionary *)message msg:(NSString *)msg;
- (void)_handleChangedMessage:(NSDictionary *)message msg:(NSString *)msg;
@end
