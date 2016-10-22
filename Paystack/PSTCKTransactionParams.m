//
//  PSTCKCardParams.m
//  Paystack
//

#import "PSTCKTransactionParams.h"
#import "PSTCKCardValidator.h"
#import "PaystackError.h"
#import "PSTCKRSA.h"

@implementation PSTCKTransactionParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    self = [super init];
    if (self) {
        _additionalAPIParameters = @{};
    }
    return self;
}


#pragma mark - 

#pragma mark - PSTCKFormEncodable

+ (NSString *)rootObjectName {
    return @"";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             @"email": @"email",
             @"amount": @"amount",
             @"reference": @"reference",
             @"subaccount": @"subaccount",
             @"transaction_charge": @"transaction_charge",
             @"bearer": @"bearer",
             @"metadata": @"metadata",
             };
}

@end
