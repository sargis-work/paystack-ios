//
//  PSTCKTransactionParams.h
//  Paystack
//

#import <Foundation/Foundation.h>
#import "PSTCKFormEncodable.h"
/**
 *  Representation of a user's credit card details. You can assemble these with information that your user enters and
 *  then create Paystack tokens with them using an PSTCKAPIClient. @see https://paystack.com/docs/api#cards
 */
@interface PSTCKTransactionParams : NSObject<PSTCKFormEncodable>

@property (nonatomic, copy, nonnull) NSString *email;
@property (nonatomic) NSUInteger amount;
@property (nonatomic, copy, nullable) NSString *reference;
@property (nonatomic, copy, nullable) NSString *subaccount;
@property (nonatomic) NSInteger transaction_charge;
@property (nonatomic, copy, nullable) NSString *bearer;
@property (nonatomic, copy, nullable) NSString *metadata;

@end
