#import "MeteorClient.h"
#import "ObjectiveDDP.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;
using namespace Arguments;

SPEC_BEGIN(MeteorClientSpec)

describe(@"MeteorClient", ^{
    __block MeteorClient *meteorClient;
    __block ObjectiveDDP *ddp;

    beforeEach(^{
        ddp = [[[ObjectiveDDP alloc] init] autorelease];
        meteorClient = [[[MeteorClient alloc] init] autorelease];
        ddp.delegate = meteorClient;
        meteorClient.ddp = ddp;
        meteorClient.authDelegate = nice_fake_for(@protocol(DDPAuthDelegate));
        spy_on(ddp);
    });

    it(@"is correctly initialized", ^{
        meteorClient.collections should_not be_nil;
        meteorClient.subscriptions should_not be_nil;
        meteorClient.websocketReady should_not be_truthy;
    });

    context(@"webSocketDidOpen", ^{
        beforeEach(^{
            [ddp webSocketDidOpen:nil];
        });

        it(@"sets the web socket state to ready", ^{
            meteorClient.websocketReady should be_truthy;
        });
    });

    context(@"addSubscription", ^{
        beforeEach(^{
            [meteorClient addSubscription:@"a fancy subscription"];
        });

        it(@"should call ddp subscribe method", ^{
            ddp should have_received("subscribeWith:name:parameters:").with(anything)
                                                                      .and_with(@"a fancy subscription")
                                                                      .and_with(nil);
        });
    });

    context(@"unsubscribeWith", ^{
        beforeEach(^{
            [meteorClient.subscriptions setObject:@"id1"
                                           forKey:@"fancySubscriptionName"];
            [meteorClient.subscriptions count] should equal(1);
            [meteorClient removeSubscription:@"fancySubscriptionName"];
        });

        it(@"removes subscription correctly", ^{
            ddp should have_received(@selector(unsubscribeWith:));
            [meteorClient.subscriptions count] should equal(0);
        });
    });

    describe(@"didReceiveMessage", ^{
        context(@"when called with an authentication error message", ^{
            beforeEach(^{
                NSDictionary *authErrorMessage = @{
                    @"msg": @"result",
                    @"error": @{@"error": @403, @"reason": @"are you kidding me?"}
                };
                [meteorClient didReceiveMessage:authErrorMessage];
            });

            it(@"processes the message correctly", ^{
                meteorClient.authDelegate should have_received(@selector(authenticationFailed:)).with(@"are you kidding me?");
            });
        });

        context(@"when called with an 'added' message", ^{
            beforeEach(^{
                spy_on([NSNotificationCenter defaultCenter]);

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
                    [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"removed")
                                                                                      .and_with(meteorClient);
                    [NSNotificationCenter defaultCenter] should have_received(postSel).with(@"phrases_removed")
                                                                                      .and_with(meteorClient);
                });
            });
        });
    });
});

describe(@"MeteorClient SRP Auth", ^{
    __block MeteorClient *meteorClient;

    beforeEach(^{
        meteorClient = [[MeteorClient alloc] init];
    });

    describe(@"-generateAuthVerificationKeyWithUsername:password", ^{
        __block NSString *authKey;

        beforeEach(^{
            authKey = [meteorClient generateAuthVerificationKeyWithUsername:@"joeuser" password:@"secretsauce"];
        });

        it(@"computes the key correctly", ^{
            authKey should_not be_nil;
        });
    });
});

SPEC_END
