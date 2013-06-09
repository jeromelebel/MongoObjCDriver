//
//  MOTAppDelegate.m
//  MongoObjectiveCTest
//
//  Created by Jérôme Lebel on 09/06/13.
//
//

#import "MOTAppDelegate.h"
#import "mongo-objc-driver-tests.h"
#import "MODJsonToObjectAssembler.h"

@implementation MOTAppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSError *error = nil;
    id object;
    
    object = [MODJsonToObjectAssembler objectsFromJson:@"{\"object\":{\"number\":1.234567891}}" error:&error];
    NSLog(@"error %@", error);
    NSLog(@"object %@", object);
    mongoObjcDriverTests([[NSProcessInfo processInfo] environment][@"test_mongo_server"]);
}

@end
