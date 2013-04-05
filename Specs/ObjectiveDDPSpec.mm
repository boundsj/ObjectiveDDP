#import "ObjectiveDDP.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(ObjectiveDDPSpec)

describe(@"ObjectiveDDP", ^{
    __block ObjectiveDDP *ddp;
    
    describe(@"when the framework is initialized", ^{
        beforeEach(^{
            ddp = [[ObjectiveDDP alloc] initWithURLString:@"websocket" delegate:nil];
        });
        
        it(@"should have the correct url string", ^{
            ddp.urlString should equal(@"websocket");
        });
    });
});

SPEC_END
