#import "MeteorClient+Private.h"
#import "ObjectiveDDP.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;
using namespace Arguments;

SPEC_BEGIN(MeteorClientSpec)

describe(@"MeteorClient", ^{
    __block MeteorClient *meteorClient;
    __block ObjectiveDDP *ddp;

    beforeEach(^{
        ddp = nice_fake_for([ObjectiveDDP class]);
        meteorClient = [[[MeteorClient alloc] init] autorelease];
        ddp.delegate = meteorClient;
        meteorClient.ddp = ddp;
        meteorClient.authDelegate = nice_fake_for(@protocol(DDPAuthDelegate));
        spy_on(ddp);
    });

    it(@"is correctly initialized", ^{
        meteorClient->_websocketReady should_not be_truthy;
        meteorClient.connected should_not be_truthy;
        meteorClient->_usingAuth should_not be_truthy;
        meteorClient.loggedIn should_not be_truthy;
        meteorClient.collections should_not be_nil;
        meteorClient->_subscriptions should_not be_nil;
    });
    
    describe(@"#logonWithUserName:password:", ^{
        context(@"when connected", ^{
            beforeEach(^{
                meteorClient.connected = YES;
                [meteorClient logonWithUsername:@"JesseJames"
                                       password:@"shot3mUp!"];
            });
            
            it(@"sends logon message correctly", ^{
                // XXX: add custom matcher that can query the params
                //      to see what user/pass was sent
                ddp should have_received(@selector(methodWithId:method:parameters:))
                .with(anything)
                .and_with(@"beginPasswordExchange")
                .and_with(anything);
            });
            
            describe(@"#logout", ^{
                beforeEach(^{
                    [meteorClient logout];
                });
                
                it(@"sends the logout message correctly", ^{
                    ddp should have_received(@selector(methodWithId:method:parameters:))
                    .with(anything)
                    .and_with(@"logout")
                    .and_with(anything);
                });
            });
        });
        
        context(@"when not connected", ^{
            beforeEach(^{
                meteorClient.connected = NO;
                [meteorClient logonWithUsername:@"JesseJames"
                                       password:@"shot3mUp!"];
            });
            
            it(@"does not send login message", ^{
                ddp should_not have_received(@selector(methodWithId:method:parameters:));
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

    describe(@"#sendMethodWithName:parameters:notifyOnResponse", ^{
        __block NSString *methodId;

        context(@"when connected", ^{
            beforeEach(^{
                meteorClient.connected = YES;
                [meteorClient->_methodIds count] should equal(0);
                methodId = [meteorClient sendWithMethodName:@"awesomeMethod"
                                                 parameters:@[]
                                           notifyOnResponse:YES];
            });

            it(@"stores a method id", ^{
                [meteorClient->_methodIds count] should equal(1);
                [meteorClient->_methodIds allObjects][0] should equal(methodId);
            });

            it(@"sends method command correctly", ^{
                ddp should have_received(@selector(methodWithId:method:parameters:))
                .with(methodId)
                .and_with(@"awesomeMethod")
                .and_with(@[]);
            });
        });

        context(@"when not connected", ^{
            beforeEach(^{
                meteorClient.connected = NO;
                [meteorClient->_methodIds count] should equal(0);
                methodId = [meteorClient sendWithMethodName:@"awesomeMethod" parameters:@[] notifyOnResponse:YES];
            });

            it(@"does not store a method id", ^{
                [meteorClient->_methodIds count] should equal(0);
            });

            it(@"does not send method command", ^{
                ddp should_not have_received(@selector(methodWithId:method:parameters:));
            });
        });
    });

    describe(@"#didOpen", ^{
        beforeEach(^{
            spy_on([NSNotificationCenter defaultCenter]);
            NSArray *array = [[[NSArray alloc] init] autorelease];
            meteorClient.collections = [NSMutableDictionary dictionaryWithDictionary:@{@"col1": array}];
            [meteorClient.collections count] should equal(1);
            [meteorClient didOpen];
        });

        it(@"sets the web socket state to ready", ^{
            meteorClient->_websocketReady should be_truthy;
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
            meteorClient->_websocketReady = YES;
            meteorClient.connected = YES;
            [meteorClient didReceiveConnectionClose];
        });

        it(@"resets collections and reconnects web socket", ^{
            meteorClient->_websocketReady should_not be_truthy;
            meteorClient.connected should_not be_truthy;
            ddp should have_received(@selector(connectWebSocket));
        });
    });
    
    describe(@"#didReceiveConnectionError", ^{
        __block NSError *rejectError;
        
        beforeEach(^{
            spy_on([NSNotificationCenter defaultCenter]);
            meteorClient->_websocketReady = YES;
            meteorClient.connected = YES;
            [meteorClient callMethodName:@"robots" parameters:nil responseCallback:^(NSDictionary *response, NSError *error) {
                rejectError = error;
            }];
            meteorClient->_methodIds.count should equal(1);
            meteorClient->_responseCallbacks.count should equal(1);
            [meteorClient didReceiveConnectionError:nil];
        });
        
        it(@"resets collections and reconnects web socket", ^{
            meteorClient->_websocketReady should_not be_truthy;
            meteorClient.connected should_not be_truthy;
            meteorClient->_methodIds.count should equal(0);
            meteorClient->_responseCallbacks.count should equal(0);
            ddp should have_received(@selector(connectWebSocket));
        });
        
        it(@"rejects unresolved callbacks", ^{
            NSError *expectedError = [NSError errorWithDomain:MeteorClientTransportErrorDomain code:MeteorClientNotConnectedError userInfo:@{NSLocalizedDescriptionKey: @"You were disconnected"}];
            rejectError should equal(expectedError);
        });

        it(@"sends a notification", ^{
            [NSNotificationCenter defaultCenter] should have_received(@selector(postNotificationName:object:))
            .with(MeteorClientDidDisconnectNotification)
            .and_with(meteorClient);
        });
    });

    describe(@"#didReceiveMessage", ^{
        __block NSString *key;
        
        describe(@"async method API", ^{
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
                    returnedResponse should equal(@"rule");
                });
            });
        
            context(@"when the response fails", ^{
                beforeEach(^{
                    key = [meteorClient callMethodName:@"robots" parameters:nil responseCallback:^(NSDictionary *response, NSError *error) {
                        returnedError = error;
                    }];
                    [meteorClient didReceiveMessage:@{@"msg": @"result",
                                                      @"error": @{@"errorType": @"lamesauce", @"error": @500},
                                                      @"id": key
                                                      }];
                });
                
                it(@"has the correct returned response", ^{
                    NSDictionary *errorDic = @{@"errorType": @"lamesauce", @"error": @500};
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDic};
                    NSError *expectedError = [NSError errorWithDomain:errorDic[@"errorType"] code:[errorDic[@"error"]integerValue] userInfo:userInfo];
                    
                    returnedError should equal(expectedError);

                });
            });
        });
        
        context(@"when called with a login challenge response", ^{
            beforeEach(^{
                meteorClient->_srpUser = (SRPUser *)malloc(sizeof(SRPUser));
                meteorClient->_srpUser->Astr = [@"astringy" cStringUsingEncoding:NSASCIIStringEncoding];
                
                meteorClient.connected = YES;
                meteorClient->_password = @"ardv4rkz";
                NSDictionary *challengeMessage = @{@"msg": @"result",
                                                   @"result": @{@"B": @"bee",
                                                                @"identity": @"ident",
                                                                @"salt": @"pepper"}};
                [meteorClient didReceiveMessage:challengeMessage];
            });
            
            it(@"processes the message correclty", ^{
                ddp should have_received(@selector(methodWithId:method:parameters:))
                    .with(anything)
                    .and_with(@"login")
                    .and_with(anything);
            });
        });
        
        context(@"when called with an HAMK verification response", ^{
            beforeEach(^{
                meteorClient->_password = @"w0nky";
                meteorClient->_srpUser = srp_user_new(SRP_SHA256, SRP_NG_1024, "dummy", "dummy", NULL, NULL);
                meteorClient->_srpUser->HAMK = [@"hamk4u" cStringUsingEncoding:NSASCIIStringEncoding];
                NSDictionary *verificationeMessage = @{@"msg": @"result",
                                                       @"result": @{@"id": @"id123",
                                                                    @"HAMK": @"hamk4u",
                                                                    @"token": @"smokin"}};
                [meteorClient didReceiveMessage:verificationeMessage];
            });
            
            it(@"processes the message correctly", ^{
                meteorClient->_sessionToken should equal(@"smokin");
            });
        });

        context(@"when called with an authentication error message", ^{
            __block NSDictionary *authErrorMessage;
            
            beforeEach(^{
                authErrorMessage = @{
                                     @"msg": @"result",
                                     @"error": @{@"error": @403,
                                                 @"reason":
                                                 @"are you kidding me?"}};
            });
            
            context(@"before max rejects occurs and connected", ^{
                beforeEach(^{
                    meteorClient->_retryAttempts = 0;
                    meteorClient->_userName = @"mknightsham";
                    meteorClient->_password = @"iS33de4dp33pz";
                });
                
                context(@"when connected", ^{
                    beforeEach(^{
                        meteorClient.connected = YES;
                        [meteorClient didReceiveMessage:authErrorMessage];
                    });
                    
                    it(@"processes the message correctly", ^{
                        meteorClient.authDelegate should_not have_received(@selector(authenticationFailed:));
                        ddp should have_received(@selector(methodWithId:method:parameters:))
                            .with(anything)
                            .and_with(@"beginPasswordExchange")
                            .and_with(anything);
                    });
                });
                
                context(@"when not connected", ^{
                    beforeEach(^{
                        meteorClient.connected = NO;
                        [meteorClient didReceiveMessage:authErrorMessage];
                    });
                    
                    it(@"processes the message correctly", ^{
                        meteorClient->_retryAttempts should equal(0);
                        meteorClient.authDelegate should have_received(@selector(authenticationFailed:)).with(@"are you kidding me?");
                    });
                });
            });
            
            context(@"after max rejects occurs", ^{
                beforeEach(^{
                    meteorClient->_retryAttempts = 5;
                    [meteorClient didReceiveMessage:authErrorMessage];
                });
                
                it(@"processes the message correctly", ^{
                    meteorClient->_retryAttempts should equal(0);
                    meteorClient.authDelegate should have_received(@selector(authenticationFailed:)).with(@"are you kidding me?");
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
    });
});

SPEC_END
