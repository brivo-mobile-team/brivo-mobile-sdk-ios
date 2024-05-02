//
//  BrivoBLE.h
//  BrivoBLE
//
//  Created by Constantin Georgiu on 25/07/2019.
//  Copyright © 2019 Brivo. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface BrivoBLECPP : NSObject

+(NSString*)getNextMessage;
+(BOOL)hasNextMessage;
+(void)endTransaction;
+(void)provideResponse:(NSArray*)packet serviceUuid: (NSString*) serviceUuid characteristicUuid: (NSString*) characteristicUuid;
+(BOOL)startTransaction:(NSString*)serviceUid jsonData:(NSString*) jsonData;
+(NSString*)getAdvertisementServiceUids;
+(NSString*)getBleServiceUids;

@end
