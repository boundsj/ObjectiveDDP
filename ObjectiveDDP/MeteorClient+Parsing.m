#import "MeteorClient+Private.h"

@implementation MeteorClient (Parsing)

- (void)_handleMethodResultMessageWithMessageId:(NSString *)messageId message:(NSDictionary *)message msg:(NSString *)msg {
    if ([_methodIds containsObject:messageId]) {
        if([msg isEqualToString:@"result"]) {
            MeteorClientMethodCallback callback = _responseCallbacks[messageId];
            id response;
            if(message[@"error"]) {
                NSDictionary *errorDesc = message[@"error"];
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDesc[@"message"]};
                NSError *responseError = [NSError errorWithDomain:errorDesc[@"errorType"] code:[errorDesc[@"error"] integerValue] userInfo:userInfo];
                if (callback) {
                    callback(nil, responseError);
                }
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

@end
