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
        ddp = [[ObjectiveDDP alloc] init];
        meteorClient = [[MeteorClient alloc] init];
        meteorClient.ddp = ddp;

        spy_on(ddp);
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

SPEC_END
