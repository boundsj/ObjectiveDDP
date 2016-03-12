#import "MeteorClient+Private.h"
#import "ObjectiveDDP.h"
#import <M13OrderedDictionary/M13OrderedDictionary.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;
using namespace Arguments;

SPEC_BEGIN(MeteorClientSpec)

describe(@"MeteorClient", ^{
    __block MeteorClient *meteorClient;
    __block ObjectiveDDP *ddp;
    __block NSString *bestDDPVersion;

    beforeEach(^{
        bestDDPVersion = @"best_version_ever";
        ddp = nice_fake_for([ObjectiveDDP class]);
        meteorClient = [[[MeteorClient alloc] initWithDDPVersion:bestDDPVersion] autorelease];
        ddp.delegate = meteorClient;
        meteorClient.ddp = ddp;
        meteorClient.authDelegate = nice_fake_for(@protocol(DDPAuthDelegate));
        spy_on(ddp);
    });

    it(@"is correctly initialized", ^{
        meteorClient.websocketReady should_not be_truthy;
        meteorClient.connected should_not be_truthy;
        meteorClient.collections should_not be_nil;
        meteorClient->_subscriptions should_not be_nil;
        meteorClient.authState should equal(AuthStateNoAuth);
        meteorClient.ddpVersion should equal(bestDDPVersion);
    });
    
    describe(@"#disconnect", ^{
        beforeEach(^{
            [meteorClient disconnect];
        });
        
        it(@"tells ddp to disconnect", ^{
            ddp should have_received(@selector(disconnectWebSocket));
        });        
    });
    
//    describe(@"#signupWithEmail:password:fullname:responseCallback:", ^{
//        
//        context(@"when connected", ^{
//            beforeEach(^{
//                meteorClient.connected = YES;
//                [meteorClient signupWithEmail:@"mrt@ateam.com" password:@"password" fullname:@"mr bean" responseCallback:nil];
//            });
//            
//            it(@"sends signup message correctly", ^{
//                NSArray *sentMessages = [(id<CedarDouble>)ddp sent_messages];
//                NSInvocation *invocation = sentMessages[1];
//                NSArray *sentParameters;
//                [invocation getArgument:&sentParameters atIndex:4];
//                ddp should have_received(@selector(methodWithId:method:parameters:)).with(@"1").and_with(@"createUser").and_with(@[@{ @"username": @"",
//                @"email": @"mrt@ateam.com", @"password": @{ @"digest": [meteorClient sha256:@"password"], @"algorithm": @"sha-256" },
//                @"profile": @{ @"fullname": @"mr bean",@"signupToken": @"" } }]);
//            });
//            
//        });
//        
//        afterEach(^{
//            [meteorClient logout];
//            meteorClient.connected = NO;
//        
//        });
//    });
    
//    describe(@"#signupWithUsername:password:fullname:responseCallback:", ^{
//        
//        context(@"with username", ^{
//            beforeEach(^{
//                meteorClient.connected = YES;
//                [meteorClient signupWithUsername:@"fox" password:@"fool" fullname:@"mr fox" responseCallback:nil];
//            });
//            
//            
//            it(@"sends signup message correctly", ^{
//                NSArray *sentMessages = [(id<CedarDouble>)ddp sent_messages];
//                NSInvocation *invocation = sentMessages[1];
//                NSArray *sentParameters;
//                [invocation getArgument:&sentParameters atIndex:4];
////                NSLog(@"%@", [sentParameters debugDescription]);
//                ddp should have_received(@selector(methodWithId:method:parameters:)).with(@"1").and_with(@"createUser").and_with(@[@{ @"username": @"fox",
//                @"email": @"", @"password":@{ @"digest": [meteorClient sha256:@"fool"], @"algorithm": @"sha-256" },
//                @"profile": @{ @"fullname": @"mr fox",@"signupToken": @"" }}]);
//            });
//            
//        });
//    });
    
    describe(@"#logonWithUserParameters:", ^{
        context(@"when connected", ^{
            beforeEach(^{
                meteorClient.connected = YES;
                [meteorClient logonWithUserParameters:@{ @"user": @{ @"email": @"mrt@ateam.com" }, @"password": @{ @"digest": [meteorClient sha256:@"fool"], @"algorithm": @"sha-256" } } responseCallback:nil];
            });
            
            it(@"sends logon message correctly", ^{
                NSArray *sentMessages = [(id<CedarDouble>)ddp sent_messages];
                NSInvocation *invocation = sentMessages[1];
                NSArray *sentParameters;
                [invocation getArgument:&sentParameters atIndex:4];
                ddp should have_received(@selector(methodWithId:method:parameters:)).with(@"1").and_with(@"login").and_with(@[@{ @"user": @{ @"email": @"mrt@ateam.com" }, @"password": @{ @"digest": [meteorClient sha256:@"fool"], @"algorithm": @"sha-256" } }]);
            });
        });
    });
    
    describe(@"#logonWithUsername:password:responseCallback:", ^{
        __block NSDictionary *successResponse = nil;
        __block NSError *errorResponse = nil;
        
        context(@"when connected", ^{
            beforeEach(^{
                meteorClient.connected = YES;
                [meteorClient logonWithUsername:@"fox" password:@"wh4tdo1Say?" responseCallback:^(NSDictionary *response, NSError *error) {
                    successResponse = response;
                    errorResponse = error;
                }];
            });
            
            context(@"when the user is not already logging in", ^{
                it(@"sends logon message correctly", ^{
                    ddp should have_received(@selector(methodWithId:method:parameters:)).with(anything).and_with(@"login").and_with(anything);
                });
                
                context(@"if the user tries to logon before current attempt finishes", ^{
                    beforeEach(^{
                        [(id<CedarDouble>)ddp reset_sent_messages];
                        [meteorClient logonWithUsername:@"fox" password:@"wh4tdo1Say?" responseCallback:^(NSDictionary *response, NSError *error) {
                            successResponse = response;
                            errorResponse = error;
                        }];
                    });
                    
                    it(@"does not allow the second attempt", ^{
                        ddp should_not have_received(@selector(methodWithId:method:parameters:));
                    });
                    
                    it(@"rejects the callback with the correct error", ^{
                        NSString *errorDesc = [NSString stringWithFormat:@"You must wait for the current logon request to finish before sending another."];
                        NSError *expectedError = [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientErrorLogonRejected userInfo:@{NSLocalizedDescriptionKey: errorDesc}];
                        errorResponse should equal(expectedError);
                        successResponse should be_nil;
                    });
                });
              
                context(@"when the logon request succeeds", ^{
                    beforeEach(^{
                        NSDictionary *message = @{@"id": @"blarg"};
                        NSDictionary *logonSuccessfulResponse = @{@"id": @"5", @"msg": @"result", @"result": message};
                        [meteorClient didReceiveMessage:logonSuccessfulResponse];
                    });
                    
                    it(@"calls the response callback correctly", ^{
                        successResponse should_not be_nil;
                        errorResponse should be_nil;
                        meteorClient.userId should equal(@"blarg");
                    });
                });
            
                context(@"when the logon request fails", ^{
                    beforeEach(^{
                        NSDictionary *loginErrorMessage = @{@"error": @403, @"message": @"you suck", @"errorType": @"screwed"};
                        NSDictionary *logonSuccessfulResponse = @{@"id": @"6", @"msg": @"result", @"error": loginErrorMessage};
                        [meteorClient didReceiveMessage:logonSuccessfulResponse];
                    });
                    
//                    it(@"calls the response callback correctly", ^{
//                        NSError *expectedError = [NSError errorWithDomain:@"screwed" code:403 userInfo:@{NSLocalizedDescriptionKey: @"you suck"}];
//                        errorResponse should equal(expectedError);
//                        successResponse should be_nil;
//                    });
                });
            });
        });
        
        context(@"when not connected", ^{
            beforeEach(^{
                meteorClient.connected = NO;
                [meteorClient logonWithUsername:@"fox" password:@"wh4tdo1Say?" responseCallback:^(NSDictionary *response, NSError *error) {
                    successResponse = response;
                    errorResponse = error;
                }];
            });
            
            it(@"does not send", ^{
                ddp should_not have_received(@selector(methodWithId:method:parameters:));
            });
            
            it(@"rejects the callback with the correct error", ^{
                NSString *errorDesc = [NSString stringWithFormat:@"You are not connected"];
                NSError *expectedError = [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientErrorNotConnected userInfo:@{NSLocalizedDescriptionKey: errorDesc}];
                errorResponse should equal(expectedError);
                successResponse should be_nil;
            });
        });
    });
    
    describe(@"#addSubscription:", ^{
        context(@"when connected", ^{
            beforeEach(^{
                meteorClient.connected = YES;
                [meteorClient addSubscription:@"a fancy subscription"];
            });

            it(@"should call ddp subscribe method", ^{
                ddp should have_received("subscribeWith:name:parameters:").with(anything)
                .and_with(@"a fancy subscription")
                .and_with(nil);
            });
        });

        context(@"when not connected", ^{
            beforeEach(^{
                meteorClient.connected = NO;
                [meteorClient addSubscription:@"a fancy subscription"];
            });

            it(@"should not call ddp subscribe method", ^{
                ddp should_not have_received("subscribeWith:name:parameters:");
            });
        });
    });

    describe(@"#removeSubscription:", ^{
        context(@"when not connected", ^{
            beforeEach(^{
                meteorClient.connected = YES;
                [meteorClient->_subscriptions setObject:@"id1"
                                               forKey:@"fancySubscriptionName"];
                [meteorClient->_subscriptions count] should equal(1);
                [meteorClient removeSubscription:@"fancySubscriptionName"];
            });

            it(@"removes subscription correctly", ^{
                ddp should have_received(@selector(unsubscribeWith:));
                [meteorClient->_subscriptions count] should equal(0);
            });
        });

        context(@"when not connected", ^{
            beforeEach(^{
                meteorClient.connected = NO;
                [meteorClient->_subscriptions setObject:@"id1"
                                               forKey:@"fancySubscriptionName"];
                [meteorClient->_subscriptions count] should equal(1);
                [meteorClient removeSubscription:@"fancySubscriptionName"];
            });

            it(@"does not remove subscription", ^{
                ddp should_not have_received(@selector(unsubscribeWith:));
                [meteorClient->_subscriptions count] should equal(1);
            });
        });
    });

    describe(@"#didOpen", ^{
        beforeEach(^{
            spy_on([NSNotificationCenter defaultCenter]);
            M13MutableOrderedDictionary *array = [[[M13MutableOrderedDictionary alloc] init] autorelease];
            meteorClient.collections = [NSMutableDictionary dictionaryWithDictionary:@{@"col1": array}];
            [meteorClient.collections count] should equal(1);
            [meteorClient didOpen];
        });

        it(@"sets the web socket state to ready", ^{
            meteorClient.websocketReady should be_truthy;
            [meteorClient.collections count] should equal(0);
            ddp should have_received(@selector(connectWithSession:version:support:));
        });

        it(@"sends a notification", ^{
            [NSNotificationCenter defaultCenter] should have_received(@selector(postNotificationName:object:))
            .with(MeteorClientDidConnectNotification)
            .and_with(meteorClient);
        });
    });

    describe(@"#didReceiveConnectionClose", ^{
        beforeEach(^{
            meteorClient.websocketReady = YES;
            meteorClient.connected = YES;
        });
        
        context(@"when websocket is not disconnecting", ^{
            beforeEach(^{
                [meteorClient didReceiveConnectionClose];
            });
            
            it(@"resets collections and reconnects web socket", ^{
                meteorClient.websocketReady should_not be_truthy;
                meteorClient.connected should_not be_truthy;
                ddp should have_received(@selector(connectWebSocket));
            });
        });
        
        context(@"when websocket is disconnecting", ^{
            beforeEach(^{
                [meteorClient disconnect];
                [meteorClient didReceiveConnectionClose];
            });
            
            it(@"does not attempt to reconnect", ^{
                ddp should_not have_received(@selector(connectWebSocket));
            });
        });
    });
    
    describe(@"#didReceiveConnectionError", ^{
        __block NSError *rejectError;
        
        beforeEach(^{
            spy_on([NSNotificationCenter defaultCenter]);
            meteorClient.websocketReady = YES;
            meteorClient.connected = YES;
            [meteorClient callMethodName:@"robots" parameters:nil responseCallback:^(NSDictionary *response, NSError *error) {
                rejectError = error;
            }];
            meteorClient->_methodIds.count should equal(1);
            meteorClient->_responseCallbacks.count should equal(1);
        });
        
        context(@"when websocket is not disconnecting", ^{
            beforeEach(^{
                [meteorClient didReceiveConnectionError:nil];
                [meteorClient callMethodName:@"robots" parameters:nil responseCallback:^(NSDictionary *response, NSError *error) {
                    rejectError = error;
                }];
            });
            
            it(@"resets collections and reconnects web socket", ^{
                meteorClient.websocketReady should_not be_truthy;
                meteorClient.connected should_not be_truthy;
                meteorClient->_methodIds.count should equal(0);
                meteorClient->_responseCallbacks.count should equal(0);
                ddp should have_received(@selector(connectWebSocket));
            });
            
            it(@"rejects unresolved callbacks", ^{
                NSError *expectedError = [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientErrorDisconnectedBeforeCallbackComplete userInfo:@{NSLocalizedDescriptionKey: @"You were disconnected"}];
                rejectError should equal(expectedError);
            });
            
            it(@"sends a notification", ^{
                [NSNotificationCenter defaultCenter] should have_received(@selector(postNotificationName:object:))
                .with(MeteorClientDidDisconnectNotification)
                .and_with(meteorClient);
            });
        });
        
        context(@"when the websocket is disconnecting", ^{
            beforeEach(^{
                [meteorClient disconnect];
                [meteorClient didReceiveConnectionError:nil];
            });
            
            it(@"does not attempt to reconnect", ^{
                ddp should_not have_received(@selector(connectWebSocket));
            });
        });
    });

    describe(@"#didReceiveMessage", ^{
        __block NSString *key;
        
        describe(@"RPC async method response", ^{
            __block NSDictionary *returnedResponse;
            __block NSError *returnedError;
            
            beforeEach(^{
                meteorClient.connected = YES;
            });
            
            context(@"when the response is successful", ^{
                beforeEach(^{
                    key = [meteorClient callMethodName:@"robots" parameters:nil responseCallback:^(NSDictionary *response, NSError *error) {
                        returnedResponse = response;
                    }];
                    
                    [meteorClient didReceiveMessage:@{@"msg": @"result",
                                                      @"result": @"rule",
                                                      @"id": key
                                                     }];
                });
                
                it(@"has the correct returned response", ^{
                    returnedResponse[@"result"] should equal(@"rule");
                });
            });
        
            context(@"when the response fails", ^{
                beforeEach(^{
                    key = [meteorClient callMethodName:@"robots" parameters:nil responseCallback:^(NSDictionary *response, NSError *error) {
                        returnedError = error;
                    }];
                    [meteorClient didReceiveMessage:@{@"msg": @"result",
                                                      @"error": @{@"errorType": @"lamesauce", @"error": @500, @"message": @"you suck"},
                                                      @"id": key}];
                });
                
                it(@"has the correct returned response", ^{
                    NSDictionary *errorDic = @{@"errorType": @"lamesauce", @"error": @500, @"message": @"you suck"};
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDic[@"message"]};
                    NSError *expectedError = [NSError errorWithDomain:errorDic[@"errorType"] code:[errorDic[@"error"]integerValue] userInfo:userInfo];
                    
                    returnedError should equal(expectedError);

                });
            });
        });
                    
        context(@"when subscription is ready", ^{
            beforeEach(^{
                [meteorClient->_subscriptions setObject:@"subid" forKey:@"subscriptionName"];
                NSDictionary *readyMessage = @{@"msg": @"ready", @"subs": @[@"subid"]};
                [meteorClient didReceiveMessage:readyMessage];
            });
            
            it(@"processes the message correctly", ^{
                SEL postSel = @selector(postNotificationName:object:);
                [NSNotificationCenter defaultCenter] should have_received(postSel)
                    .with(@"subscriptionName_ready")
                    .and_with(meteorClient);
            });
        });
        

        context(@"when called with an 'added' message", ^{
            beforeEach(^{
                NSDictionary *addedMessage = @{
                    @"msg": @"added",
                    @"id": @"id1",
                    @"collection": @"phrases",
                    @"fields": @{@"text": @"this is ridiculous"}
                };

                [meteorClient didReceiveMessage:addedMessage];
            });

            it(@"processes the message correctly", ^{
                [meteorClient.collections[@"phrases"] count] should equal(1);
                NSDictionary *phrase = meteorClient.collections[@"phrases"][0];
                phrase[@"text"] should equal(@"this is ridiculous");
                SEL postSel = @selector(postNotificationName:object:userInfo:);
                [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"added")
                                                                                  .and_with(meteorClient)
                                                                                  .and_with(phrase);
                [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"phrases_added")
                                                                                  .and_with(meteorClient)
                                                                                  .and_with(phrase);
            });
            
            context(@"when called with a changed message", ^{
                beforeEach(^{
                    NSDictionary *changedMessage = @{
                        @"msg": @"changed",
                        @"id": @"id1",
                        @"collection": @"phrases",
                        @"fields": @{@"text": @"this is really ridiculous"}
                    };

                    [meteorClient didReceiveMessage:changedMessage];
                });

                it(@"processes the message correctly", ^{
                    [meteorClient.collections[@"phrases"] count] should equal(1);
                    NSDictionary *phrase = meteorClient.collections[@"phrases"][0];
                    phrase[@"text"] should equal(@"this is really ridiculous");
                    SEL postSel = @selector(postNotificationName:object:userInfo:);
                    [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"changed")
                                                                                       .and_with(meteorClient)
                                                                                       .and_with(phrase);
                    [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"phrases_changed")
                                                                                       .and_with(meteorClient)
                                                                                       .and_with(phrase);
                });
            });
            
            

            context(@"when called with a removed message", ^{
                beforeEach(^{
                    NSDictionary *removedMessage = @{
                        @"msg": @"removed",
                        @"id": @"id1",
                        @"collection": @"phrases",
                    };

                    [meteorClient didReceiveMessage:removedMessage];
                });

                it(@"processes the message correctly", ^{
                    [meteorClient.collections[@"phrases"] count] should equal(0);
                    SEL postSel = @selector(postNotificationName:object:);
                    SEL postObjSel = @selector(postNotificationName:object:userInfo:);
                    [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"removed")
                                                                                      .and_with(meteorClient);
                    [NSNotificationCenter defaultCenter] should have_received(postObjSel).with(@"phrases_removed")
                                                                                         .and_with(meteorClient)
                                                                                         .and_with(@{@"_id": @"id1"});
                });
            });
        });
        
        context(@"when called with an 'addedBefore' message", ^{
            beforeEach(^{
                NSDictionary *addedMessage = @{
                                               @"msg": @"added",
                                               @"id": @"id0",
                                               @"collection": @"phrases",
                                               @"fields": @{@"text": @"this is ridiculous"}
                                               };
                
                [meteorClient didReceiveMessage:addedMessage];
                
                NSDictionary *addedBeforeMessage = @{
                                               @"msg": @"addedBefore",
                                               @"id": @"id1",
                                               @"collection": @"phrases",
                                               @"fields": @{@"text": @"this is before ridiculous"},
                                               @"before":@"id0"
                                               };
                
                [meteorClient didReceiveMessage:addedBeforeMessage];
            });
            
            it(@"processes the message correctly", ^{
                [meteorClient.collections[@"phrases"] count] should equal(2);
                //check the order
                NSDictionary *phrase = meteorClient.collections[@"phrases"][0];
                phrase[@"text"] should equal(@"this is before ridiculous");
                SEL postSel = @selector(postNotificationName:object:userInfo:);
                [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"addedBefore")
                .and_with(meteorClient)
                .and_with(phrase);
                [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"phrases_addedBefore")
                .and_with(meteorClient)
                .and_with(phrase);
            });
        });
        
        context(@"when called with an 'movedBefore' message", ^{
            beforeEach(^{
                NSDictionary *addedMessage = @{
                                               @"msg": @"added",
                                               @"id": @"id0",
                                               @"collection": @"phrases",
                                               @"fields": @{@"text": @"this is ridiculous"}
                                               };
                
                [meteorClient didReceiveMessage:addedMessage];
                
                NSDictionary *addedNextMessage = @{
                                               @"msg": @"added",
                                               @"id": @"id1",
                                               @"collection": @"phrases",
                                               @"fields": @{@"text": @"this is before ridiculous"}
                                               };
                
                [meteorClient didReceiveMessage:addedNextMessage];
                
                NSDictionary *movedBeforeMessage = @{
                                                     @"msg": @"movedBefore",
                                                     @"id": @"id1",
                                                     @"collection": @"phrases",
                                                     @"before":@"id0"
                                                     };
                
                [meteorClient didReceiveMessage:movedBeforeMessage];
            });
            
            it(@"processes the message correctly", ^{
                [meteorClient.collections[@"phrases"] count] should equal(2);
                //check the order
                NSDictionary *phrase = meteorClient.collections[@"phrases"][0];
                phrase[@"text"] should equal(@"this is before ridiculous");
                SEL postSel = @selector(postNotificationName:object:userInfo:);
                [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"movedBefore")
                .and_with(meteorClient)
                .and_with(phrase);
                [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"phrases_movedBefore")
                .and_with(meteorClient)
                .and_with(phrase);
            });
        });

    });
});

SPEC_END
