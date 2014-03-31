#import "MeteorClient.h"
#import "FakeDependencyProvider.h"
#import "FakeObjectiveDDP.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MeteorClientSpec)

fdescribe(@"MeteorClient", ^{
    __block MeteorClient *meteorClient;
    __block FakeObjectiveDDP *fakeDDP;
    __block id<MeteorClientDelegate> meteorClientDelegate;
    
    beforeEach(^{
        spy_on(fakeProvider);
        fakeDDP = [[FakeObjectiveDDP alloc] init];
        spy_on(fakeDDP);
        fakeProvider.fakeObjectiveDDP = fakeDDP;
        meteorClientDelegate = nice_fake_for(@protocol(MeteorClientDelegate));
        
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
                meteorClientDelegate should have_received(@selector(didConnectToWebsocket));
            });
            
            it(@"should use ddp to connect", ^{
                fakeDDP should have_received(@selector(connectWithSession:version:support:)).with(nil, @"pre1", nil);
            });
        });
    });
});

SPEC_END
