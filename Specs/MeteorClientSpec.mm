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

        spy_on(ddp);
    });

    it(@"is correctly initialized", ^{
        meteorClient.collections should_not be_nil;
        meteorClient.subscriptions should_not be_nil;
        meteorClient.websocketReady should_not be_truthy;
    });

    describe(@"when the web socket opens", ^{
        beforeEach(^{
            [ddp webSocketDidOpen:nil];
        });

        it(@"sets the web socket state to ready", ^{
            meteorClient.websocketReady should be_truthy;
        });
    });

    describe(@"when addSubsciption is called", ^{
        beforeEach(^{
            [meteorClient addSubscription:@"a fancy subscription"];
        });

        it(@"should call ddp subscribe method", ^{
            ddp should have_received("subscribeWith:name:parameters:").with(anything)
                                                                      .and_with(@"a fancy subscription")
                                                                      .and_with(nil);
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
