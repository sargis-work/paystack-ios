//
//  PSTCKRSA.m
//  Paystack
//
//  Created by Ibrahim Lawal on Feb/27/2016.
//  Copyright © 2016 Paystack, Inc. All rights reserved.
//

#import "PSTCKRSA.h"

extern OSStatus SecKeyEncrypt(
                                  SecKeyRef           key,
                                  SecPadding          padding,
                                  const uint8_t		*plainText,
                                  size_t              plainTextLen,
                                  uint8_t             *cipherText,
                                  size_t              *cipherTextLen)
__OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_2_0) __attribute__((weak_import));

@implementation PSTCKRSA

+ (NSData *)stripPublicKeyHeader:(NSData *)d_key
{
    // Skip ASN.1 public key header
    if (d_key == nil) return(nil);
    
    unsigned long len = [d_key length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;
    
    if (c_key[idx++] != 0x30) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
        else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
        else idx++;
    
    if (c_key[idx++] != '\0') return(nil);
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}


+(NSString *)encryptRSA:(NSString *)plainTextString  {
    
    NSString *key = @"-----BEGIN PUBLIC KEY-----\n"
    "MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBANIsL+RHqfkBiKGn/D1y1QnNrMkKzxWP\n"
    "2wkeSokw2OJrCI+d6YGJPrHHx+nmb/Qn885/R01Gw6d7M824qofmCvkCAwEAAQ==\n"
    "-----END PUBLIC KEY-----";
    NSString *s_key = [NSString string];
    NSArray  *a_key = [key componentsSeparatedByString:@"\n"];
    BOOL     f_key  = FALSE;
    
    for (NSString *a_line in a_key) {
        if ([a_line isEqualToString:@"-----BEGIN PUBLIC KEY-----"]) {
            f_key = TRUE;
        }
        else if ([a_line isEqualToString:@"-----END PUBLIC KEY-----"]) {
            f_key = FALSE;
        }
        else if (f_key) {
            s_key = [s_key stringByAppendingString:a_line];
        }
    }
    // NSLog(@"Key length = %lu",(unsigned long)s_key.length);
    if (s_key.length == 0) return nil;
    
    // This will be base64 encoded, decode it.
    NSData *d_key = [[NSData alloc] initWithBase64EncodedString:s_key options:0];
    d_key = [self stripPublicKeyHeader:d_key];
    if (d_key == nil) return nil;
    //NSLog(@"Dkey wasn't nil");
    
    //    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    //    [publicKey setObject:d_tag forKey:(id)kSecAttrApplicationTag];
    SecItemDelete((CFDictionaryRef)publicKey);
    
    CFTypeRef persistKey = nil;
    
    // Add persistent version of the key to system keychain
    [publicKey setObject:d_key forKey:(id)kSecValueData];
    [publicKey setObject:(id) kSecAttrKeyClassPublic forKey:(id)
     kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)
     kSecReturnPersistentRef];
    
    OSStatus secStatus = SecItemAdd((CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil) CFRelease(persistKey);
        
        if ((secStatus != noErr) && (secStatus != errSecDuplicateItem)) {
            return(FALSE);
        }
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    
    [publicKey removeObjectForKey:(id)kSecValueData];
    [publicKey removeObjectForKey:(id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef
     ];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    secStatus = SecItemCopyMatching((CFDictionaryRef)publicKey,
                                    (CFTypeRef *)&keyRef);
    
    
    if (keyRef == nil){
        //NSLog(@"No key");
        return nil;
    }
    
    // Add to our pseudo keychain
    //    [keyRefs addObject:[NSValue valueWithBytes:&keyRef objCType:@encode(
    //                                                                        SecKeyRef)]];
    //
    
    size_t cipherBufferSize = SecKeyGetBlockSize(keyRef);
    uint8_t *cipherBuffer = malloc(cipherBufferSize);
    uint8_t *nonce = (uint8_t *)[plainTextString UTF8String];
    
    SecKeyEncrypt(keyRef,
                  kSecPaddingPKCS1,
                  nonce,
                  strlen( (char*)nonce ),
                  &cipherBuffer[0],
                  &cipherBufferSize);
    NSData *encryptedData = [NSData dataWithBytes:cipherBuffer length:cipherBufferSize];
    return [encryptedData base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
}

@end
