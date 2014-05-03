#import "MeteorClient.h"
#import "FakeDependencyProvider.h"
#import "FakeObjectiveDDP.h"
#import "DDPSubscriptionService.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MeteorClientSpec)

describe(@"MeteorClient", ^{
    __block MeteorClient *meteorClient;
    __block FakeObjectiveDDP *fakeDDP;
    __block id<DDPMeteorClientDelegate> meteorClientDelegate;
    __block id<DDPMeteorSubscribing> subscriptionService;
    
    beforeEach(^{
        fakeDDP = [[FakeObjectiveDDP alloc] init];
        fakeProvider.fakeObjectiveDDP = fakeDDP;
        
        meteorClientDelegate = fake_for(@protocol(DDPMeteorClientDelegate));
        // stub optional delegate methods
        meteorClientDelegate stub_method(@selector(meteorClientDidConnectToWebsocket:));
        meteorClientDelegate stub_method(@selector(meteorClientDidConnectToServer:));
        meteorClientDelegate stub_method(@selector(meteorClient:didReceiveWebsocketConnectionError:));
        
        spy_on(fakeProvider);
        spy_on(fakeDDP);
        
        subscriptionService = nice_fake_for(@protocol(DDPMeteorSubscribing));
        fakeProvider.fakeDDPSubscriptionService = subscriptionService;
        
        meteorClient = [[MeteorClient alloc] initWithConnectionString:@"ws://xanadu.com/websocket" delegate:meteorClientDelegate];
    });
    
    it(@"should get a correctly configured ddp instance", ^{
        meteorClient.ddp should be_same_instance_as(fakeDDP);
        meteorClient.ddp.urlString should equal(@"ws://xanadu.com/websocket");
    });
    
    describe(@"connecting to a web socket without a stored session and with subscriptions made previously", ^{
        beforeEach(^{
            [meteorClient addSubscription:@"stuff"];
            [meteorClient connect];
        });
        
        it(@"should use ddp to connect to the meteor server", ^{
            fakeDDP should have_received(@selector(connectWebSocket));
        });
        
        context(@"when the web socket connection attempt is successful", ^{
            beforeEach(^{
                [fakeDDP succeedWebSocket];
            });
            
            it(@"should tell its delegate", ^{
                meteorClientDelegate should have_received(@selector(meteorClientDidConnectToWebsocket:)).with(meteorClient);
            });
            
            it(@"should use ddp to connect to the meteor server", ^{
                fakeDDP should have_received(@selector(connectWithSession:version:support:)).with(nil, @"pre1", nil);
            }); 
            
            context(@"when the connection to the meteor server succeeds", ^{
                beforeEach(^{
                    [fakeDDP succeedMeteorConnect];
                });
                
                it(@"should set the correct the connected state", ^{
                    meteorClient.connected should be_truthy;
                });
                
                it(@"should tell its delegate", ^{
                    meteorClientDelegate should have_received(@selector(meteorClientDidConnectToServer:)).with(meteorClient);
                });
                
                it(@"should tell its subscription service to make subscriptions", ^{
                    subscriptionService should have_received(@selector(makeSubscriptionsWithDDP:subscriptions:)).with(meteorClient.ddp, meteorClient.subscriptions);
                });
                
                xcontext(@"when a different subscription is made", ^{
                });
                
                xcontext(@"when a subscription is removed", ^{
                });
            });
            
            xcontext(@"when the connection to the meteor server fails", ^{
            });
        });
        
        context(@"when the web socket connection attempt fails", ^{
            __block NSError *error;
            
            beforeEach(^{
                error = [NSError errorWithDomain:@"error.com" code:42 userInfo:nil];
                [fakeDDP errorWebSocketWithError:error];
            });
            
            it(@"should set the correct the connected state", ^{
                meteorClient.connected should be_falsy;
            });
            
            it(@"should tell its delegate", ^{
                meteorClientDelegate should have_received(@selector(meteorClient:didReceiveWebsocketConnectionError:)).with(meteorClient, error);
            });
        });
    });
    
    xdescribe(@"connecting to a web socket with a stored session", ^{
    });
});

SPEC_END
