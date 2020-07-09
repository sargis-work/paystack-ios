//
//  Paystack.h
//  Paystack
//
//  Created by Ibrahim Lawal on 02/02/16.
//  Copyright (c) 2016 Paystack. All rights reserved.
//
// The code in this workspace was adapted from https://github.com/stripe/stripe-ios. 
// Stripe was replaced with Paystack - and STP with PSTCK - to avoid collisions within 
// apps that are using both Paystack and Stripe.

#import <Paystack/PSTCKAPIClient.h>
#import <Paystack/PaystackError.h>
#import <Paystack/PSTCKCardBrand.h>
#import <Paystack/PSTCKCardParams.h>
#import <Paystack/PSTCKTransactionParams.h>
#import <Paystack/PSTCKCard.h>
#import <Paystack/PSTCKCardValidationState.h>
#import <Paystack/PSTCKCardValidator.h>
#import <Paystack/PSTCKToken.h>
#import <Paystack/PSTCKRSA.h>

#if TARGET_OS_IPHONE
#import <Paystack/PSTCKPaymentCardTextField.h>
#endif
