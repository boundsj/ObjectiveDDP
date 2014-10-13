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
    if ([msg isEqualToString:@"added"]
        && message[@"collection"]) {
        NSDictionary *object = [self _parseObjectAndAddToCollection:message];
        NSString *notificationName = [NSString stringWithFormat:@"%@_added", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:object];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"added" object:self userInfo:object];
    }
}

- (void)_handleAddedBeforeMessage:(NSDictionary *)message msg:(NSString *)msg {
    if ([msg isEqualToString:@"addedBefore"]
        && message[@"collection"]) {
        NSDictionary *object = [self _parseObjectAndAddToCollection:message beforeId:[message valueForKey:@"before"]];
        NSString *notificationName = [NSString stringWithFormat:@"%@_addedBefore", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:object];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addedBefore" object:self userInfo:object];
    }
}

- (void)_handleMovedBeforeMessage:(NSDictionary *)message msg:(NSString *)msg {
    
    if ([msg isEqualToString:@"movedBefore"]
        && message[@"collection"]) {
        NSDictionary *object = [self _parseMovedBefore:message];
        NSString *notificationName = [NSString stringWithFormat:@"%@_movedBefore", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:object];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"movedBefore" object:self userInfo:object];
    }
}




- (NSDictionary *)_parseMovedBefore:(NSDictionary *)message {
    
    NSMutableDictionary *object = [NSMutableDictionary dictionaryWithDictionary:@{@"_id": message[@"id"]}];
    
    M13MutableOrderedDictionary *collection = self.collections[message[@"collection"]];
    
    NSString * beforeDocumentId = [message valueForKey:@"before"];
    
    //if document doesn't exist, add it to end
    if (!beforeDocumentId) {
        [collection addObject:object pairedWithKey:message[@"id"]];
    }
    //move document to before index
    else{

        NSUInteger currentIndex = [collection indexOfKey:message[@"id"]];
        NSUInteger moveToIndex = [collection indexOfKey:beforeDocumentId];

        if (currentIndex != NSNotFound && moveToIndex != NSNotFound) {
            
            //remove object from its current place
            object = [collection objectForKey:message[@"id"]];
            [collection removeObjectForKey:message[@"id"]];
            
            //insert object at before index
            [collection insertObject:object pairedWithKey:message[@"id"] atIndex:moveToIndex];
        }
    }
    return object;
}


- (NSUInteger)_indexForDocumentId:(NSString*)documentId inCollection:(NSMutableArray*)collection {
    
    //get index of document to insert before
    NSUInteger documentIndex = [collection indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj valueForKey:@"_id"] isEqualToString:documentId]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    if (documentIndex != NSNotFound) {
        NSLog(@"The title of category at index %lu is %@", (unsigned long)documentIndex, [[collection objectAtIndex:documentIndex] valueForKey:@"_id"]);
    }
    else {
        NSLog(@"Not found");
    }
    
    return documentIndex;
}



- (NSDictionary *)_parseObjectAndAddToCollection:(NSDictionary *)message {
    NSMutableDictionary *object = [NSMutableDictionary dictionaryWithDictionary:@{@"_id": message[@"id"]}];
    for (id key in message[@"fields"]) {
        object[key] = message[@"fields"][key];
    }
    if (!self.collections[message[@"collection"]]) {
        self.collections[message[@"collection"]] = [M13MutableOrderedDictionary new];
    }
    M13MutableOrderedDictionary *collection = self.collections[message[@"collection"]];
    [collection addObject:object pairedWithKey:message[@"id"]];
    return object;
}



- (NSDictionary *)_parseObjectAndAddToCollection:(NSDictionary *)message beforeId:(NSString*)documentId {
    NSMutableDictionary *object = [NSMutableDictionary dictionaryWithDictionary:@{@"_id": message[@"id"]}];
    for (id key in message[@"fields"]) {
        object[key] = message[@"fields"][key];
    }

    M13MutableOrderedDictionary *collection = self.collections[message[@"collection"]];
    
    //if documentId, insert at beforeId index
    if (documentId) {
        NSUInteger documentIndex = [collection indexOfKey:documentId]; // _indexForDocumentId:documentId inCollection:collection];
        if (documentIndex != NSNotFound) {
            [collection insertObject:object pairedWithKey:message[@"id"] atIndex:documentIndex];
        }
    }
    //if no documentId, insert at end
    else{
        [collection addObject:object pairedWithKey:message[@"id"]];
    }
    return object;
}



- (void)_handleRemovedMessage:(NSDictionary *)message msg:(NSString *)msg {
    if ([msg isEqualToString:@"removed"]
        && message[@"collection"]) {
        [self _parseRemoved:message];
        NSString *notificationName = [NSString stringWithFormat:@"%@_removed", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:@{@"_id": message[@"id"]}];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"removed" object:self];
    }
}



- (void)_parseRemoved:(NSDictionary *)message {
    M13MutableOrderedDictionary *collection = self.collections[message[@"collection"]];
    [collection removeObjectForKey:message[@"id"]];
}



- (void)_handleChangedMessage:(NSDictionary *)message msg:(NSString *)msg {
    if ([msg isEqualToString:@"changed"]
        && message[@"collection"]) {
        NSDictionary *object = [self _parseObjectAndUpdateCollection:message];
        NSString *notificationName = [NSString stringWithFormat:@"%@_changed", message[@"collection"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:object];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"changed" object:self userInfo:object];
    }
}



- (NSDictionary *)_parseObjectAndUpdateCollection:(NSDictionary *)message {
    M13MutableOrderedDictionary *collection = self.collections[message[@"collection"]];
    NSMutableDictionary *object = [collection objectForKey:message[@"id"]];
    for (id key in message[@"fields"]) {
        object[key] = message[@"fields"][key];
    }
    for (id key in message[@"cleared"]) {
        [object removeObjectForKey:key];
    }
    return object;
}

@end
