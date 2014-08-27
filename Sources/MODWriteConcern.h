//
//  MODWriteConcern.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 27/08/2014.
//
//

#import <Foundation/Foundation.h>

/*
 MODWriteConcern is non mutable since MODClient instance doesn't keep it around
 this avoid errors like :
 client.writeConcern.journal = YES;
 */

@interface MODWriteConcern : NSObject
{
    void                                *_mongocWriteConcern;
}
@property (nonatomic, assign, readonly) BOOL fileSync;
@property (nonatomic, assign, readonly) BOOL journal;
@property (nonatomic, assign, readonly) int32_t w;
@property (nonatomic, assign, readonly) int32_t wtimeout;
@property (nonatomic, strong, readonly) NSString *wtag;
@property (nonatomic, strong, readonly) id compiled;

- (instancetype)initWithFileSync:(BOOL)fileSync journal:(BOOL)journal w:(int32_t)w wtimeout:(int32_t)wtimeout wtag:(NSString *)wtag compiled:(id)compiled;

@end
