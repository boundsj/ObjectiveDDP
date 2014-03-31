#import "MeteorClient.h"
#import "FakeDependencyProvider.h"
#import "FakeObjectiveDDP.h"
#import "DDPConnectedSubscriptionService.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MeteorClientSpec)

fdescribe(@"MeteorClient", ^{
    __block MeteorClient *meteorClient;
    __block FakeObjectiveDDP *fakeDDP;
    __block id<DDPMeteorClientDelegate> meteorClientDelegate;
    __block id<DDPMeteorSubscribing> subscriptionService;
    
    beforeEach(^{
        fakeDDP = [[FakeObjectiveDDP alloc] init];
        fakeProvider.fakeObjectiveDDP = fakeDDP;
        
        subscriptionService = nice_fake_for(@protocol(DDPMeteorSubscribing));
        fakeProvider.fakeDDPSubscriptionService = subscriptionService;

        meteorClientDelegate = nice_fake_for(@protocol(DDPMeteorClientDelegate));
        spy_on(fakeProvider);
        spy_on(fakeDDP);
        
        meteorClient = [[MeteorClient alloc] initWithConnectionString:@"ws://xanadu.com/websocket" delegate:meteorClientDelegate];
    });
    
    it(@"should use the dependency provider to create a ddp instance", ^{
        fakeProvider should have_received(@selector(provideObjectiveDDPWithConnectionString:delegate:)).with(@"ws://xanadu.com/websocket", meteorClient);
    });
    
    describe(@"connecting to a web socket without a stored session", ^{
        subjectAction(^{
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
                
                it(@"should update the connected state", ^{
                    meteorClient.connected should be_truthy;
                });
                
                it(@"should tell its delegate", ^{
                    meteorClientDelegate should have_received(@selector(meteorClientDidConnectToServer:)).with(meteorClient);
                });
                
                it(@"should tell its subscription service", ^{
                    subscriptionService should have_received(@selector(makeSubscriptions));
                });
            });
            
            xcontext(@"when the connection to the meteor server fails", ^{
            });
        });
        
        xcontext(@"when the web socket connection attempt fails", ^{
        });
    });
    
    xdescribe(@"connecting to a web socket with a stored session", ^{
    });
});

SPEC_END
