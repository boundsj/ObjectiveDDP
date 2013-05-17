#import "ObjectiveDDP.h"
#import "MockObjectiveDDPDelegate.h"
#import "MockSRWebSocket.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(ObjectiveDDPSpec)

describe(@"ObjectiveDDP", ^{
    __block ObjectiveDDP *ddp;
    __block MockSRWebSocket *fakeSRWebSocket;
    __block MockObjectiveDDPDelegate<CedarDouble> *fakeDDPDelegate;

    describe(@"when the framework is initialized", ^{
        beforeEach(^{
            fakeSRWebSocket = [[MockSRWebSocket alloc] init];
            fakeDDPDelegate = nice_fake_for(@protocol(ObjectiveDDPDelegate));

            spy_on(fakeSRWebSocket);
            spy_on(fakeDDPDelegate);

            ddp = [[ObjectiveDDP alloc] initWithURLString:@"websocket"
                                                 delegate:fakeDDPDelegate];
            fakeSRWebSocket.delegate = ddp;

            ddp.getSocket = ^SRWebSocket *(NSURLRequest *request) {
                return fakeSRWebSocket;
            };
        });
        
        it(@"should have the correct url string", ^{
            ddp.urlString should equal(@"websocket");
        });

        describe(@"when connectWebSocket is called ", ^{
            beforeEach(^{
                [ddp connectWebSocket];
            });

            it(@"should open the websocket", ^{
                fakeSRWebSocket should have_received("open");
            });

            describe(@"when the websocket is opened successfully", ^{
                beforeEach(^{
                    [fakeSRWebSocket connectionSuccess];
                });

                it(@"should notify its delegate", ^{
                    fakeDDPDelegate should have_received("didOpen");
                });
            });

            describe(@"when the websocket open fails", ^{
                beforeEach(^{
                    [fakeSRWebSocket connectionFailure];
                });

                it(@"should notify its delegate", ^{
                    fakeDDPDelegate should have_received("didReceiveConnectionError:");
                });
            });
        });

        describe(@"when connect is called with no session or support", ^{

            beforeEach(^{
                [ddp connectWebSocket];
                [fakeSRWebSocket connectionSuccess];
                [ddp connectWithSession:nil
                                version:@"smersion"
                                support:nil];
            });

            it(@"should call the web socket with correct JSON", ^{
                NSString *expected = @"{\"msg\":\"connect\",\"version\":\"smersion\"}";
                fakeSRWebSocket should have_received("send:").with(expected);
            });

            describe(@"when the websocket is opened successfully", ^{
                beforeEach(^{
                    [fakeSRWebSocket connectionSuccess];
                });

                it(@"should notify its delegate", ^{
                    fakeDDPDelegate should have_received("didOpen");
                });
            });

            describe(@"when the call is successful", ^{
                beforeEach(^{
                    [fakeSRWebSocket respondWithJSONString:@"{\"msg\":\"connected\",\"session\":\"SERVER-GEN-SESSION-ID-VAL\"}"];
                });

                it(@"it should notify its delegate", ^{
                    NSDictionary *expected = @{@"msg": @"connected", @"session":@"SERVER-GEN-SESSION-ID-VAL"};
                    fakeDDPDelegate should have_received("didReceiveMessage:").with(expected);
                });
            });

            describe(@"when the call is not successful", ^{
                beforeEach(^{
                    [fakeSRWebSocket respondWithJSONString:@"{\"msg\":\"failed\",\"version\":\"smersion2\"}"];
                });

                it(@"should notify its delegate", ^{
                    NSDictionary *expected = @{@"msg": @"failed", @"version":@"smersion2"};
                    fakeDDPDelegate should have_received("didReceiveMessage:").with(expected);
                });
            });
        });

        describe(@"when subscribe is called with nil parameters", ^{
            beforeEach(^{
                [ddp connectWebSocket];
                [fakeSRWebSocket connectionSuccess];
                [ddp subscribeWith:@"id1"
                              name:@"publishedCollection"
                        parameters:nil];
            });

            it(@"should call the websocket correctly", ^{
                NSString *expected = @"{\"msg\":\"sub\",\"name\":\"publishedCollection\",\"id\":\"id1\"}";
                fakeSRWebSocket should have_received("send:").with(expected);
            });
        });

        describe(@"when method is called", ^{
            beforeEach(^{
                [ddp connectWebSocket];
                [fakeSRWebSocket connectionSuccess];
                NSArray *params = @[@{@"_id": @"abc", @"msg": @"ohai"}];
                [ddp methodWith:@"id" method:@"/do/something" parameters:params];
            });

            it(@"should call the websocket correctly", ^{
                NSString *expected = @"{\"method\":\"\\/do\\/something\",\"id\":\"id\",\"params\":[{\"_id\":\"abc\",\"msg\":\"ohai\"}],\"msg\":\"method\"}";
                fakeSRWebSocket should have_received("send:").with(expected);
            });
        });
    });
});

SPEC_END
