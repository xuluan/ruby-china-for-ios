//
//  RCAppDelegate.m
//  ruby-china-for-ios
//
//  Created by Jason Lee on 12-12-10.
//  Copyright (c) 2012年 Ruby China. All rights reserved.
//

#import "RCAppDelegate.h"
#import "RCViewController.h"
#import "RCAll.h"
#import "RCPreferences.h"
#import "RCLoginViewController.h"


@implementation RCAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    [self mapObjects];
    
    [RCUser checkLogin];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)mapObjects {
    AFHTTPClient* client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kApiURL]];
    [client setDefaultHeader:@"Accept" value:RKMIMETypeJSON];
    RKObjectManager *manager = [[RKObjectManager alloc] initWithHTTPClient:client];
   
    // Error
    
//    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
//    [errorMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"" toKeyPath:@"message"]];
//    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping
//                                                                                    pathPattern:nil
//                                                                                        keyPath:nil
//                                                                                    statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
    
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    // The entire value at the source key path containing the errors maps to the message
    [errorMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"" toKeyPath:@"errorMessage"]];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError);
    // Any response in the 4xx status code range with an "errors" key path uses this mapping
    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping pathPattern:nil keyPath:@"error" statusCodes:statusCodes];

    
    // Node
    RKObjectMapping *nodeMapping = [RKObjectMapping mappingForClass:[RCNode class]];
    [nodeMapping addAttributeMappingsFromArray:@[@"name", @"summary",@"sort"]];
    [nodeMapping addAttributeMappingsFromDictionary:@{
     @"id" : @"ID",
     @"topics_count" : @"topicsCount",
    }];
    RKResponseDescriptor *nodeDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:nodeMapping
                                                                                   pathPattern:[RCNode tableName]
                                                                                       keyPath:nil
                                                                                   statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    // User
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RCUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"login", @"name", @"company", @"location", @"bio", @"tagline", @"website"]];
    [userMapping addAttributeMappingsFromDictionary:@{
     @"id" : @"ID",
     @"created_at" : @"createdAt",
     @"updated_at" : @"updatedAt",
     @"github_url" : @"githubUrl",
     @"avatar_url" : @"avatarUrl"
     }];
    RKResponseDescriptor *userDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping
                                                                                   pathPattern:@"users/:id"
                                                                                       keyPath:nil
                                                                                   statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    
    
    // Reply
    RKObjectMapping *replyMapping = [RKObjectMapping mappingForClass:[RCReply class]];
    [replyMapping addAttributeMappingsFromArray:@[@"body"]];
    [replyMapping addAttributeMappingsFromDictionary:@{
     @"id" : @"ID",
     @"created_at" : @"createdAt",
     @"updated_at" : @"updatedAt",
     @"body_html" : @"bodyHtml",
     @"topic_id" : @"topicId",
     }];
    [replyMapping addRelationshipMappingWithSourceKeyPath:@"user" mapping:userMapping];
    RKResponseDescriptor *replyDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:replyMapping
                                                                                    pathPattern:@"replies"
                                                                                        keyPath:nil
                                                                                    statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    
    
    // Topic
    RKObjectMapping *topicMapping = [RKObjectMapping mappingForClass:[RCTopic class]];
    [topicMapping addAttributeMappingsFromArray:@[@"title", @"body", @"hits"]];
    [topicMapping addAttributeMappingsFromDictionary:@{
         @"id" : @"ID",
         @"created_at" : @"createdAt",
         @"updated_at" : @"updatedAt",
         @"body_html" : @"bodyHtml",
         @"last_reply_user_login" : @"lastReplyUserLogin",
         @"last_reply_user_id" : @"lastReplyUserId",
         @"node_name" : @"nodeName",
         @"node_id" : @"nodeId",
         @"replied_at" : @"repliedAt",
         @"replies_count" : @"repliesCount",
         @"user_login" : @"userLogin",
     }];
    [topicMapping addRelationshipMappingWithSourceKeyPath:@"user" mapping:userMapping];
    [topicMapping addRelationshipMappingWithSourceKeyPath:@"node" mapping:nodeMapping];
    [topicMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"replies" toKeyPath:@"replies" withMapping:replyMapping]];

    
    RKResponseDescriptor *topicsDescripter = [RKResponseDescriptor responseDescriptorWithMapping:topicMapping
                                                                                    pathPattern:@"topics"
                                                                                        keyPath:nil
                                                                                    statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *topicDescripter = [RKResponseDescriptor responseDescriptorWithMapping:topicMapping
                                                                                     pathPattern:@"topics/:id"
                                                                                         keyPath:nil
                                                                                     statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [manager addResponseDescriptorsFromArray:@[errorDescriptor, nodeDescriptor, userDescriptor, replyDescriptor, topicsDescripter, topicDescripter ]];
}


@end
