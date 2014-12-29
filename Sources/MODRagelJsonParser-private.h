//
//  MODRagelJsonParser-private.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 28/12/2014.
//
//

@interface MODRagelJsonParser (private)
+ (BOOL)bsonFromJson:(bson_t *)bsonResult json:(NSString *)json error:(NSError **)error;

@end
