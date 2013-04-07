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

            describe(@"when the websocket open fails", ^{
                beforeEach(^{
                    [fakeSRWebSocket failure];
                });

                it(@"should notify its delegate", ^{
                    fakeDelegate should have_received("didReceiveConnectionError:");
                });
            });
        });

        describe(@"when connect is called with no session or support", ^{
            beforeEach(^{
                [ddp reconnect];
                [ddp connectWithSession:nil
                                version:@"smersion"
                                support:nil];
            });

            it(@"should call the web socket with correct JSON", ^{
                NSString *expected = @"{\"msg\":\"connect\",\"version\":\"smersion\"}";
                fakeSRWebSocket should have_received("send:").with(expected);
            });

            xdescribe(@"when the call is successful", ^{
                true should equal(false);
            });

            xdescribe(@"when the call is not successful", ^{
            });
        });
    });
});

SPEC_END
