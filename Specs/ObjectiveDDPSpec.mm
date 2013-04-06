#import "ObjectiveDDP.h"
#import "MockObjectiveDDPDelegate.h"
#import "MockSRWebSocket.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(ObjectiveDDPSpec)

describe(@"ObjectiveDDP", ^{
    __block ObjectiveDDP *ddp;
    __block MockSRWebSocket *fakeSRWebSocket;
    __block MockObjectiveDDPDelegate<CedarDouble> *fakeDelegate;

    describe(@"when the framework is initialized", ^{
        beforeEach(^{
            fakeSRWebSocket = [[MockSRWebSocket alloc] init];
            fakeDelegate = nice_fake_for(@protocol(ObjectiveDDPDelegate));

            spy_on(fakeSRWebSocket);
            spy_on(fakeDelegate);

            ddp = [[ObjectiveDDP alloc] initWithURLString:@"websocket"
                                                 delegate:fakeDelegate];
            fakeSRWebSocket.delegate = ddp;

            ddp.getSocket = ^SRWebSocket *(NSURLRequest *request) {
                return fakeSRWebSocket;
            };
        });
        
        it(@"should have the correct url string", ^{
            ddp.urlString should equal(@"websocket");
        });

        describe(@"when reconnect is called ", ^{
            beforeEach(^{
                [ddp reconnect];
            });

            it(@"should open the websocket", ^{
                fakeSRWebSocket should have_received("open");
            });

            describe(@"when the websocket is opened successfully", ^{
                beforeEach(^{
                    [fakeSRWebSocket success];
                });

                it(@"should notify its delegate", ^{
                    fakeDelegate should have_received("didOpen");
                });
            });
        });
    });
});

SPEC_END
