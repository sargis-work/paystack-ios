//
//  PSTCKFormEncoder.h
//  Paystack
//

#import <Foundation/Foundation.h>

@class PSTCKCardParams;
@class PSTCKTransactionParams;
@protocol PSTCKFormEncodable;

@interface PSTCKFormEncoder : NSObject

+ (nonnull NSData *)formEncodedDataForObject:(nonnull NSObject<PSTCKFormEncodable> *)object;

+ (nonnull NSData *)formEncryptedDataForCard:(nonnull PSTCKCardParams *)card
                              andTransaction:(nonnull PSTCKTransactionParams *)transaction;

+ (nonnull NSData *)formEncryptedDataForCard:(nonnull PSTCKCardParams *)card
                              andTransaction:(nonnull PSTCKTransactionParams *)transaction
                                   andHandle:(nonnull NSString *)handle;

+ (nonnull NSString *)stringByURLEncoding:(nonnull NSString *)string;

+ (nonnull NSString *)stringByReplacingSnakeCaseWithCamelCase:(nonnull NSString *)input;

@end
