//
//  PSTCKFormEncoder.h
//  Paystack
//

#import <Foundation/Foundation.h>

@class PSTCKCardParams;
@protocol PSTCKFormEncodable;

@interface PSTCKFormEncoder : NSObject

+ (nonnull NSData *)formEncryptedDataForCard:(nonnull NSObject<PSTCKFormEncodable> *)object;

+ (nonnull NSString *)stringByURLEncoding:(nonnull NSString *)string;

+ (nonnull NSString *)stringByReplacingSnakeCaseWithCamelCase:(nonnull NSString *)input;

@end
