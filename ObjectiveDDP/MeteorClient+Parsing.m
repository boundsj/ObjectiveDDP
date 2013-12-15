#import "MeteorClient+Private.h"
#import "srp.h"

@implementation MeteorClient (Parsing)

- (void)_handleMethodResultMessageWithMessageId:(NSString *)messageId message:(NSDictionary *)message msg:(NSString *)msg {
    if ([_methodIds containsObject:messageId]) {
        if([msg isEqualToString:@"result"]) {
            MeteorClientMethodCallback callback = _responseCallbacks[messageId];
            id response;
            if(message[@"error"]) {
                NSDictionary *errorDesc = message[@"error"];
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDesc};
                NSError *responseError = [NSError errorWithDomain:errorDesc[@"errorType"] code:[errorDesc[@"error"] integerValue] userInfo:userInfo];
                if (callback)
                    callback(nil, responseError);
                response = responseError;
            } else {
                if (callback) {
                    callback(message, nil);
                }
            }
            NSString *notificationName = [NSString stringWithFormat:@"response_%@", messageId];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:response];
            [_responseCallbacks removeObjectForKey:messageId];
            [_methodIds removeObject:messageId];
        }
    }
}

- (void)_handleLoginChallengeResponse:(NSDictionary *)message msg:(NSString *)msg {
    if ([msg isEqualToString:@"result"]
        && message[@"result"]
        && [message[@"result"] isKindOfClass:[NSDictionary class]]
        && message[@"result"][@"B"]
        && message[@"result"][@"identity"]
        && message[@"result"][@"salt"]) {
        [self didReceiveLoginChallengeWithResponse:message[@"result"]];
    }
}

static int LOGON_RETRY_MAX = 5;

- (void)_handleLoginError:(NSDictionary *)message msg:(NSString *)msg {
    if([msg isEqualToString:@"result"]
       && message[@"error"]
       && [message[@"error"][@"error"] integerValue] == 403
       && self.authState != AuthStateLoggedOut) {
        [self _setAuthStatetoLoggedOut];
        if (++_retryAttempts < LOGON_RETRY_MAX && self.connected) {
            [self logonWithUserParameters:_logonParams username:_userName password:_password responseCallback:_logonMethodCallback];
        } else {
            _retryAttempts = 0;
            NSString *errorDesc = [NSString stringWithFormat:@"Logon failed with error %@", @403];
            NSError *logonError = [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientErrorLogonRejected userInfo:@{NSLocalizedDescriptionKey: errorDesc}];
            if (_logonMethodCallback) {
                _logonMethodCallback(nil, logonError);
                _logonMethodCallback = nil;
            }
            [self.authDelegate authenticationFailed:message[@"error"][@"reason"]];
        }
    }
}

- (void)_handleHAMKVerification:(NSDictionary *)message msg:(NSString *)msg {
    if (msg && [msg isEqualToString:@"result"]
        && message[@"result"]
        && [message[@"result"] isKindOfClass:[NSDictionary class]]
        && message[@"result"][@"id"]
        && message[@"result"][@"HAMK"]
        && message[@"result"][@"token"]) {
        NSDictionary *response = message[@"result"];
        [self didReceiveHAMKVerificationWithResponse:response];
    }
}

- (void)_handleAddedMessage:(NSDictionary *)message msg:(NSString *)msg {
    if (msg && [msg isEqualToString:@"added"]
        && message[@"collection"]) {
        NSDictionary *object = [self _parseObjectAndAddToCollection:message];
        NSString *notificationName = [NSString stringWithFormat:@"%@_added", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:object];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"added" object:self userInfo:object];
    }
}

- (NSDictionary *)_parseObjectAndAddToCollection:(NSDictionary *)message {
    NSMutableDictionary *object = [NSMutableDictionary dictionaryWithDictionary:@{@"_id": message[@"id"]}];
    for (id key in message[@"fields"]) {
        object[key] = message[@"fields"][key];
    }
    if (!self.collections[message[@"collection"]]) {
        self.collections[message[@"collection"]] = [NSMutableArray array];
    }
    NSMutableArray *collection = self.collections[message[@"collection"]];
    [collection addObject:object];
    return object;
}

- (void)_handleRemovedMessage:(NSDictionary *)message msg:(NSString *)msg {
    if (msg && [msg isEqualToString:@"removed"]
        && message[@"collection"]) {
        [self _parseRemoved:message];
        NSString *notificationName = [NSString stringWithFormat:@"%@_removed", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:@{@"_id": message[@"id"]}];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"removed" object:self];
    }
}

- (void)_parseRemoved:(NSDictionary *)message {
    NSString *removedId = [message objectForKey:@"id"];
    int indexOfRemovedObject = 0;
    
    NSMutableArray *collection = self.collections[message[@"collection"]];
    
    for (NSDictionary *object in collection) {
        if ([object[@"_id"] isEqualToString:removedId]) {
            break;
        }
        indexOfRemovedObject++;
    }
    
    [collection removeObjectAtIndex:indexOfRemovedObject];
}

- (void)_handleChangedMessage:(NSDictionary *)message msg:(NSString *)msg {
    if (msg && [msg isEqualToString:@"changed"]
        && message[@"collection"]) {
        NSDictionary *object = [self _parseObjectAndUpdateCollection:message];
        NSString *notificationName = [NSString stringWithFormat:@"%@_changed", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:object];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"changed" object:self userInfo:object];
    }
}

- (NSDictionary *)_parseObjectAndUpdateCollection:(NSDictionary *)message {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(_id like %@)", message[@"id"]];
    NSMutableArray *collection = self.collections[message[@"collection"]];
    NSArray *filteredArray = [collection filteredArrayUsingPredicate:pred];
    NSMutableDictionary *object = filteredArray[0];
    for (id key in message[@"fields"]) {
        object[key] = message[@"fields"][key];
    }
    return object;
}

#pragma mark - SRP Auth Parsing

- (void)didReceiveLoginChallengeWithResponse:(NSDictionary *)response {
    NSString *B_string = response[@"B"];
    const char *B = [B_string cStringUsingEncoding:NSASCIIStringEncoding];
    NSString *salt_string = response[@"salt"];
    const char *salt = [salt_string cStringUsingEncoding:NSASCIIStringEncoding];
    NSString *identity_string = response[@"identity"];
    const char *identity = [identity_string cStringUsingEncoding:NSASCIIStringEncoding];
    const char *password_str = [_password cStringUsingEncoding:NSASCIIStringEncoding];
    const char *Mstr;
    srp_user_process_meteor_challenge(_srpUser, password_str, salt, identity, B, &Mstr);
    NSString *M_final = [NSString stringWithCString:Mstr encoding:NSASCIIStringEncoding];
    NSArray *params = @[@{@"srp":@{@"M":M_final}}];
    [self callMethodName:@"login" parameters:params responseCallback:nil];
}

- (void)didReceiveHAMKVerificationWithResponse:(NSDictionary *)response {
    srp_user_verify_meteor_session(_srpUser, [response[@"HAMK"] cStringUsingEncoding:NSASCIIStringEncoding]);
    if (srp_user_is_authenticated) {
        _sessionToken = response[@"token"];
        self.userId = response[@"id"];
        [self.authDelegate authenticationWasSuccessful];
        srp_user_delete(_srpUser);
        [self _setAuthStateToLoggedIn];
        if (_logonMethodCallback) {
            _logonMethodCallback(@{@"logon": @"success"}, nil);
            _logonMethodCallback = nil;
        }
    }
}

@end
