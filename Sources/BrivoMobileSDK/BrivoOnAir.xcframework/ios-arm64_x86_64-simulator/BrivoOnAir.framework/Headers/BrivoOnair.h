//
//  BrivoOnAir.h
//  BrivoOnAir
//
//  Created by Constantin Georgiu on 25/07/2019.
//  Copyright © 2019 Brivo. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface BrivoOnair : NSObject

+(NSString*)decodeJWTToken:(NSString*)jwtToken;

@end
