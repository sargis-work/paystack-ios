//
//  PSTCKAPIClient.m
//  PaystackExample
//

#import "TargetConditionals.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#endif

#import "PSTCKAPIClient.h"
#import "PSTCKFormEncoder.h"
#import "PSTCKCard.h"
#import "PSTCKToken.h"
#import "PaystackError.h"
#import "PSTCKAPIResponseDecodable.h"
#import "PSTCKAPIPostRequest.h"

#if __has_include("Fabric.h")
#import "Fabric+FABKits.h"
#import "FABKitProtocol.h"
#endif

#ifdef PSTCK_STATIC_LIBRARY_BUILD
#import "PSTCKCategoryLoader.h"
#endif

#define FAUXPAS_IGNORED_IN_METHOD(...)

static NSString *const apiURLBase = @"standard.paystack.co/bosco";
static NSString *const tokenEndpoint = @"createmobiletoken";
static NSString *const paystackAPIVersion = @"2016-02-12";
static NSString *PSTCKDefaultPublishableKey;

@implementation Paystack

+ (void)setDefaultPublishableKey:(NSString *)publishableKey {
    PSTCKDefaultPublishableKey = publishableKey;
}

+ (NSString *)defaultPublishableKey {
    return PSTCKDefaultPublishableKey;
}

@end

#if __has_include("Fabric.h")
@interface PSTCKAPIClient ()<NSURLSessionDelegate, FABKit>
#else
@interface PSTCKAPIClient()<NSURLSessionDelegate>
#endif
@property (nonatomic, readwrite) NSURL *apiURL;
@property (nonatomic, readwrite) NSURLSession *urlSession;
@end

@implementation PSTCKAPIClient

#ifdef PSTCK_STATIC_LIBRARY_BUILD
+ (void)initialize {
    [PSTCKCategoryLoader loadCategories];
}
#endif

+ (instancetype)sharedClient {
    static id sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedClient = [[self alloc] init]; });
    return sharedClient;
}

- (instancetype)init {
    return [self initWithPublishableKey:[Paystack defaultPublishableKey]];
}

- (instancetype)initWithPublishableKey:(NSString *)publishableKey {
    self = [super init];
    if (self) {
        [self.class validateKey:publishableKey];
        _apiURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", apiURLBase]];
        _publishableKey = [publishableKey copy];
        _operationQueue = [NSOperationQueue mainQueue];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSString *auth = [@"Bearer " stringByAppendingString:self.publishableKey];
        config.HTTPAdditionalHeaders = @{
                                         @"X-Paystack-User-Agent": [self.class paystackUserAgentDetails],
                                         @"Paystack-Version": paystackAPIVersion,
                                         @"Authorization": auth,
                                         };
        _urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_operationQueue];
    }
    return self;
}



- (void)setOperationQueue:(NSOperationQueue *)operationQueue {
    NSCAssert(operationQueue, @"Operation queue cannot be nil.");
    _operationQueue = operationQueue;
}

- (void)createTokenWithData:(NSData *)data completion:(PSTCKTokenCompletionBlock)completion {
    NSCAssert(data != nil, @"'data' is required to create a token");
    NSCAssert(completion != nil, @"'completion' is required to use the token that is created");
    [PSTCKAPIPostRequest<PSTCKToken *> startWithAPIClient:self
                                             endpoint:tokenEndpoint
                                             postData:data
                                           serializer:[PSTCKToken new]
                                           completion:completion];
}

#pragma mark - private helpers

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
+ (void)validateKey:(NSString *)publishableKey {
    NSCAssert(publishableKey != nil && ![publishableKey isEqualToString:@""],
              @"You must use a valid publishable key to create a token.");
    BOOL secretKey = [publishableKey hasPrefix:@"sk_"];
    NSCAssert(!secretKey,
              @"You are using a secret key to create a token, instead of the publishable one.");
#ifndef DEBUG
    if ([publishableKey.lowercaseString hasPrefix:@"pk_test"]) {
        FAUXPAS_IGNORED_IN_METHOD(NSLogUsed);
        NSLog(@"⚠️ Warning! You're building your app in a non-debug configuration, but appear to be using your Paystack test key. Make sure not to submit to "
              @"the App Store with your test keys!⚠️");
    }
#endif
}
#pragma clang diagnostic pop

#pragma mark Utility methods -

+ (NSString *)paystackUserAgentDetails {
    NSMutableDictionary *details = [@{
        @"lang": @"objective-c",
        @"bindings_version": PSTCKSDKVersion,
    } mutableCopy];
#if TARGET_OS_IPHONE
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version) {
        details[@"os_version"] = version;
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine);
    if (deviceType) {
        details[@"type"] = deviceType;
    }
    NSString *model = [UIDevice currentDevice].localizedModel;
    if (model) {
        details[@"model"] = model;
    }
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        NSString *vendorIdentifier = [[[UIDevice currentDevice] performSelector:@selector(identifierForVendor)] performSelector:@selector(UUIDString)];
        if (vendorIdentifier) {
            details[@"vendor_identifier"] = vendorIdentifier;
        }
    }
#endif
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[details copy] options:0 error:NULL] encoding:NSUTF8StringEncoding];
}

#pragma mark Fabric
#if __has_include("Fabric.h")

+ (NSString *)bundleIdentifier {
    return @"com.paystack.paystack-ios";
}

+ (NSString *)kitDisplayVersion {
    return PSTCKSDKVersion;
}

+ (void)initializeIfNeeded {
    Class fabric = NSClassFromString(@"Fabric");
    if (fabric) {
        // The app must be using Fabric, as it exists at runtime. We fetch our default publishable key from Fabric.
        NSDictionary *fabricConfiguration = [fabric configurationDictionaryForKitClass:[PSTCKAPIClient class]];
        NSString *publishableKey = fabricConfiguration[@"publishable"];
        if (!publishableKey) {
            NSLog(@"Configuration dictionary returned by Fabric was nil, or doesn't have publishableKey. Can't initialize Paystack.");
            return;
        }
        [self validateKey:publishableKey];
        [Paystack setDefaultPublishableKey:publishableKey];
    } else {
        NSCAssert(fabric, @"initializeIfNeeded method called from a project that doesn't have Fabric.");
    }
}

#endif

@end

#pragma mark - Credit Cards
@implementation PSTCKAPIClient (CreditCards)

- (void)createTokenWithCard:(PSTCKCard *)card completion:(PSTCKTokenCompletionBlock)completion {
//    NSData *data = [PSTCKFormEncoder formEncodedDataForObject:card];
       NSData *data = [PSTCKFormEncoder formEncryptedDataForCard:card];

    [self createTokenWithData:data completion:completion];
}

@end

@implementation Paystack (Deprecated)

+ (id)alloc {
    NSCAssert(NO, @"'Paystack' is a static class and cannot be instantiated.");
    return nil;
}

+ (void)createTokenWithCard:(PSTCKCard *)card
             publishableKey:(NSString *)publishableKey
             operationQueue:(NSOperationQueue *)queue
                 completion:(PSTCKCompletionBlock)handler {
    NSCAssert(card != nil, @"'card' is required to create a token");
    PSTCKAPIClient *client = [[PSTCKAPIClient alloc] initWithPublishableKey:publishableKey];
    client.operationQueue = queue;
    [client createTokenWithCard:card completion:handler];
}

#pragma mark Shorthand methods -

+ (void)createTokenWithCard:(PSTCKCard *)card completion:(PSTCKCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] completion:handler];
}

+ (void)createTokenWithCard:(PSTCKCard *)card publishableKey:(NSString *)publishableKey completion:(PSTCKCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

+ (void)createTokenWithCard:(PSTCKCard *)card operationQueue:(NSOperationQueue *)queue completion:(PSTCKCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] operationQueue:queue completion:handler];
}


@end
