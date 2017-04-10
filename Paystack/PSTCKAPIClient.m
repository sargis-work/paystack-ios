//
//  PSTCKAPIClient.m
//  PaystackExample
//

#import "TargetConditionals.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <UIKit/UIViewController.h>
#import <sys/utsname.h>
#endif

#import "PSTCKAPIClient.h"
#import "PSTCKFormEncoder.h"
#import "PSTCKCard.h"
#import "PSTCKRSA.h"
#import "PSTCKCardValidator.h"
#import "PSTCKToken.h"
#import "PSTCKTransaction.h"
#import "PSTCKValidationParams.h"
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

static NSString *const apiURLBase = @"standard.paystack.co";
static NSString *const chargeEndpoint = @"charge/mobile_charge";
static NSString *const validateEndpoint = @"charge/validate";
static NSString *const requeryEndpoint = @"charge/requery/";
static NSString *const paystackAPIVersion = @"2017-04-09";
static NSString *PSTCKDefaultPublicKey;
static Boolean PROCESSING = false;
static int INVALID_DATA_SENT_RETRIES=0;

@implementation Paystack

+ (id)alloc {
    NSCAssert(NO, @"'Paystack' is a static class and cannot be instantiated.");
    return nil;
}

+ (void)setDefaultPublicKey:(NSString *)publicKey {
    PSTCKDefaultPublicKey = publicKey;
}

+ (NSString *)defaultPublicKey {
    return PSTCKDefaultPublicKey;
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
    return [self initWithPublicKey:[Paystack defaultPublicKey]];
}

- (instancetype)initWithPublicKey:(NSString *)publicKey {
    self = [super init];
    if (self) {
        [self.class validateKey:publicKey];
        _apiURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", apiURLBase]];
        _publicKey = [publicKey copy];
        _operationQueue = [NSOperationQueue mainQueue];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSString *auth = [@"Bearer " stringByAppendingString:self.publicKey];
        config.HTTPAdditionalHeaders = @{
                                         @"X-Paystack-User-Agent": [self.class paystackUserAgentDetails],
                                         @"Paystack-Version": paystackAPIVersion,
                                         @"Authorization": auth,
                                         @"X-Paystack-Build":PSTCKSDKBuild,
                                         };
        _urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_operationQueue];
    }
    return self;
}



- (void)setOperationQueue:(NSOperationQueue *)operationQueue {
    NSCAssert(operationQueue, @"Operation queue cannot be nil.");
    _operationQueue = operationQueue;
}

#pragma mark - private helpers

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
+ (void)validateKey:(NSString *)publicKey {
    NSCAssert(publicKey != nil && ![publicKey isEqualToString:@""],
              @"You must use a valid public key to create a token.");
    BOOL secretKey = [publicKey hasPrefix:@"sk_"];
    NSCAssert(!secretKey,
              @"You are using a secret key to create a token, instead of the public one.");
#ifndef DEBUG
    if ([publicKey.lowercaseString hasPrefix:@"pk_test"]) {
        FAUXPAS_IGNORED_IN_METHOD(NSLogUsed);
        NSLog(@"⚠️ Warning! You're building your app in a non-debug configuration, but appear to be using your Paystack test key. Make sure not to submit to "
              @"the App Store with your test keys!⚠️");
    }
#endif
}
#pragma clang diagnostic pop

#pragma mark Utility methods -

+ (NSString *)device_id {
    return [@"iossdk_" stringByAppendingString:[[[UIDevice currentDevice] identifierForVendor] UUIDString]];
}

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
        // The app must be using Fabric, as it exists at runtime. We fetch our default public key from Fabric.
        NSDictionary *fabricConfiguration = [fabric configurationDictionaryForKitClass:[PSTCKAPIClient class]];
        NSString *publicKey = fabricConfiguration[@"public"];
        if (!publicKey) {
            NSLog(@"Configuration dictionary returned by Fabric was nil, or doesn't have publicKey. Can't initialize Paystack.");
            return;
        }
        [self validateKey:publicKey];
        [Paystack setDefaultPublicKey:publicKey];
    } else {
        NSCAssert(fabric, @"initializeIfNeeded method called from a project that doesn't have Fabric.");
    }
}

#endif

@end

typedef NS_ENUM(NSInteger, PSTCKChargeStage) {
    PSTCKChargeStageNoHandle,
    PSTCKChargeStagePlusHandle,
    PSTCKChargeStageValidateToken,
    PSTCKChargeStageRequery,
    PSTCKChargeStageAuthorize,
};


@interface PSTCKServerTransaction : NSObject

@property (nonatomic, readwrite, nullable) NSString *id;
@property (nonatomic, readwrite, nullable) NSString *reference;

@end
@implementation PSTCKServerTransaction
- (instancetype)init {
    _id = nil;
    _reference = nil;
    
    return self;
}
@end

#pragma mark - Credit Cards
@implementation PSTCKAPIClient (CreditCards)

- (void)chargeCard:(nonnull PSTCKCardParams *)card
    forTransaction:(nonnull PSTCKTransactionParams *)transaction
  onViewController:(nonnull UIViewController *)viewController
   didEndWithError:(nonnull PSTCKErrorCompletionBlock)errorCompletion
didRequestValidation:(nullable PSTCKTransactionCompletionBlock)beforeValidateCompletion
didTransactionSuccess:(nonnull PSTCKTransactionCompletionBlock)successCompletion {
    NSCAssert(card != nil, @"'card' is required for a charge");
    NSCAssert(errorCompletion != nil, @"'errorCompletion' is required to handle any errors encountered while charging");
    NSCAssert(viewController != nil, @"'viewController' is required to show any alerts that may be needed");
    NSCAssert(transaction != nil, @"'transaction' is required so we may know who to charge");
    NSCAssert(successCompletion != nil, @"'successCompletion' is required so you can continue the process after charge succeeds. Remember to verify on server before giving value.");
    if(PROCESSING){
        [self didEndWithProcessingError:errorCompletion];
        return;
    }
    PROCESSING = YES;
    INVALID_DATA_SENT_RETRIES = 0;
    NSData *data = [PSTCKFormEncoder formEncryptedDataForCard:card
                                               andTransaction:transaction
                                                 usePublicKey:[self publicKey]
                                                 onThisDevice:[self.class device_id]];
    [self makeChargeRequest:data forServerTransaction:[PSTCKServerTransaction new] atStage:PSTCKChargeStageNoHandle chargeCard:card forTransaction:transaction onViewController:viewController didEndWithError:errorCompletion didRequestValidation:beforeValidateCompletion didTransactionSuccess:successCompletion];
}

- (void) makeChargeRequest:(NSData *)data
      forServerTransaction:(nonnull PSTCKServerTransaction *)serverTransaction
                   atStage:(PSTCKChargeStage) stage
                chargeCard:(nonnull PSTCKCardParams *)card
            forTransaction:(nonnull PSTCKTransactionParams *)transaction
          onViewController:(nonnull UIViewController *)viewController
           didEndWithError:(nonnull PSTCKErrorCompletionBlock)errorCompletion
      didRequestValidation:(nullable PSTCKTransactionCompletionBlock)beforeValidateCompletion
     didTransactionSuccess:(nonnull PSTCKTransactionCompletionBlock)successCompletion{
    NSString *endpoint;
    NSString *httpMethod;
    
    switch (stage){
        case PSTCKChargeStageNoHandle:
        case PSTCKChargeStagePlusHandle:
            endpoint = chargeEndpoint;
            httpMethod = @"POST";
            break;
        case PSTCKChargeStageValidateToken:
            endpoint = validateEndpoint;
            httpMethod = @"POST";
            break;
        case PSTCKChargeStageRequery:
            endpoint =  [requeryEndpoint stringByAppendingString:[serverTransaction id]] ;
            httpMethod = @"GET";
            break;
        case PSTCKChargeStageAuthorize:
            // No endpoint required here
            break;
    }
    
    [PSTCKAPIPostRequest<PSTCKTransaction *>
     startWithAPIClient:self
     endpoint:endpoint
     method:httpMethod
     postData:data
     serializer:[PSTCKTransaction new]
     completion:^(PSTCKTransaction * _Nullable responseObject, NSError * _Nullable error){
         if([responseObject trans] != nil){
             serverTransaction.id = [responseObject trans];
         }
         if([responseObject reference] != nil){
             serverTransaction.reference = [responseObject reference];
         }
         if(error != nil){
             [self didEndWithError:error
                         reference:serverTransaction.reference
                        completion:errorCompletion];
             return;
         } else {
             // This is where we test the status of the request.
             if([[responseObject message].lowercaseString isEqual:@"invalid data sent"] && INVALID_DATA_SENT_RETRIES<3){
                 INVALID_DATA_SENT_RETRIES = INVALID_DATA_SENT_RETRIES+1;
                 [self makeChargeRequest:data
                    forServerTransaction:serverTransaction
                                 atStage:stage
                              chargeCard:card
                          forTransaction:transaction
                        onViewController:viewController
                         didEndWithError:errorCompletion
                    didRequestValidation:beforeValidateCompletion
                   didTransactionSuccess:successCompletion];
                 return;
             } else if([[responseObject status] isEqual:@"1"] || [[responseObject status] isEqual:@"success"]){
                 [self didEndSuccessfully:responseObject.reference completion:successCompletion];
                 return;
             } else if([[responseObject status] isEqual:@"2"] || [[responseObject auth].lowercaseString isEqual:@"pin"]){
                 // will request PIN now
                 // show PIN dialog
                 UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Enter CARD PIN"
                                                                                message:@"To confirm that you are the owner of this card please enter your card PIN"
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                 
                 UIAlertAction* defaultAction = [UIAlertAction
                                                 actionWithTitle:@"Continue" style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action) {
                                                     [action isEnabled]; // Just to avoid Unused error
                                                     NSString *provided = ((UITextField *)[alert.textFields objectAtIndex:0]).text;
                                                     NSString *handle = [PSTCKCardValidator sanitizedNumericStringForString:provided];
                                                     if(handle == nil ||
                                                        [handle length]!=4 ||
                                                        ([provided length] != [handle length])){
                                                         [self didEndWithErrorMessage:@"Invalid PIN provided. Expected exactly 4 digits."
                                                                            reference:serverTransaction.reference
                                                                           completion:errorCompletion];
                                                         return;
                                                     }
                                                     NSData *hdata = [PSTCKFormEncoder formEncryptedDataForCard:card
                                                                                                 andTransaction:transaction
                                                                                                      andHandle:[PSTCKRSA encryptRSA:handle]
                                                                                                   usePublicKey:[self publicKey]
                                                                                                   onThisDevice:[self.class device_id]];
                                                     [self makeChargeRequest:hdata
                                                        forServerTransaction:serverTransaction
                                                                     atStage:PSTCKChargeStagePlusHandle
                                                                  chargeCard:card
                                                              forTransaction:transaction
                                                            onViewController:viewController
                                                             didEndWithError:errorCompletion
                                                        didRequestValidation:beforeValidateCompletion
                                                       didTransactionSuccess:successCompletion];
                                                     
                                                 }];
                 
                 [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                     textField.placeholder = @"****";
                     textField.clearButtonMode = UITextFieldViewModeWhileEditing;
                     textField.secureTextEntry = YES;
                 }];
                 
                 [alert addAction:defaultAction];
                 [viewController presentViewController:alert animated:YES completion:nil];
                 return;
             } else if([serverTransaction id] != nil){
              if([[responseObject status] isEqual:@"3"] || ([[responseObject auth].lowercaseString isEqual:@"otp"] && [responseObject otpmessage] != nil)){
                 [self.operationQueue addOperationWithBlock:^{
                     beforeValidateCompletion(responseObject.reference);
                 }];
                 // Will request otp now
                 // show otp dialog
                 UIAlertController* tkalert = [UIAlertController alertControllerWithTitle:@"Enter OTP"
                                                                                  message:responseObject.message
                                                                           preferredStyle:UIAlertControllerStyleAlert];
                 
                 UIAlertAction* tkdefaultAction = [UIAlertAction
                                                   actionWithTitle:@"Continue" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [action isEnabled]; // Just to avoid Unused error
                                                       NSString *provided = ((UITextField *)[tkalert.textFields objectAtIndex:0]).text;
                                                       PSTCKValidationParams *validateParams = [PSTCKValidationParams alloc];
                                                       validateParams.trans = responseObject.trans;
                                                       validateParams.token = provided;
                                                       NSData *vdata = [PSTCKFormEncoder formEncodedDataForObject:validateParams
                                                                                                     usePublicKey:[self publicKey]
                                                                                                     onThisDevice:[self.class device_id]];
                                                       [self makeChargeRequest:vdata
                                                          forServerTransaction:serverTransaction
                                                                       atStage:PSTCKChargeStageValidateToken
                                                                    chargeCard:card
                                                                forTransaction:transaction
                                                              onViewController:viewController
                                                               didEndWithError:errorCompletion
                                                          didRequestValidation:beforeValidateCompletion
                                                         didTransactionSuccess:successCompletion];
                                                       
                                                   }];
                 
                 [tkalert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                     textField.placeholder = @"OTP";
                     textField.clearButtonMode = UITextFieldViewModeWhileEditing;
                 }];
                 [tkalert addAction:tkdefaultAction];
                 [viewController presentViewController:tkalert animated:YES completion:nil];
                  return;
              } else if([[responseObject status].lowercaseString isEqual:@"requery"]) {
                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
                                 dispatch_get_main_queue(), ^{
                                     [self makeChargeRequest:nil
                                        forServerTransaction:serverTransaction
                                                     atStage:PSTCKChargeStageRequery
                                                  chargeCard:card
                                              forTransaction:transaction
                                            onViewController:viewController
                                             didEndWithError:errorCompletion
                                        didRequestValidation:beforeValidateCompletion
                                       didTransactionSuccess:successCompletion];
                                    
                                 });
                  return;
              }
             }
             

             
             
             if([[responseObject status] isEqual:@"0"] || [[responseObject status] isEqual:@"error"] || [[responseObject status] isEqual:@"timeout"]){
                 [self didEndWithErrorMessage:[responseObject message]
                                    reference:serverTransaction.reference
                                   completion:errorCompletion];
             } else {
                 // this is an invalid status
                 [self didEndWithErrorMessage:[@"The response status from Paystack had an invalid status. Status was: " stringByAppendingString:[responseObject status]]
                                    reference:serverTransaction.reference
                                   completion:errorCompletion];
             }
         }
     }];
}

- (void)didEndWithError:(NSError *)error
              reference:(NSString *)reference
             completion:(PSTCKErrorCompletionBlock )completion{
    PROCESSING=NO;
    [self.operationQueue addOperationWithBlock:^{
        completion(error, reference);
    }];
}

- (void)didEndSuccessfully:(NSString *)reference
             completion:(PSTCKTransactionCompletionBlock )successCompletion{
    PROCESSING=NO;
    [self.operationQueue addOperationWithBlock:^{
        successCompletion(reference);
    }];
}

- (void)didEndWithErrorMessage:(NSString *)errorString
                     reference:(NSString *)reference
                    completion:(PSTCKErrorCompletionBlock )completion{
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: PSTCKUnexpectedError,
                               PSTCKErrorMessageKey: errorString
                               };
    PROCESSING=NO;
    [self didEndWithError:[[NSError alloc] initWithDomain:PaystackDomain code:PSTCKAPIError userInfo:userInfo] reference:reference completion:completion];
}

- (void)didEndWithProcessingError:(PSTCKErrorCompletionBlock )completion{
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: PSTCKCardErrorProcessingTransactionMessage,
                               PSTCKErrorMessageKey: PSTCKCardErrorProcessingTransactionMessage
                               };
    [self didEndWithError:[[NSError alloc] initWithDomain:PaystackDomain code:PSTCKConflictError userInfo:userInfo] reference:nil completion:completion];
}

@end
