//
//  FWKVStorage.h
//  UIViewTest
//
//  Created by silver on 2017/8/25.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FWKDStorageItem : NSObject

@property(nonatomic,strong)NSString *key;
@property(nonatomic,strong)NSData *data;  
@property(nonatomic,strong)NSString *fileName; //fileName in sandbox
@property(nonatomic,assign)int size;           //data.length
@property(nonatomic,assign)int modTime;        // modification unix timestamp
@property(nonatomic,assign)int accessTime;     //last access unix timestamp

@end



@interface FWKDStorage : NSObject

@property(readonly)NSString *path;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)new UNAVAILABLE_ATTRIBUTE;

-(instancetype)initWithPath:(NSString*)path  NS_DESIGNATED_INITIALIZER;

#pragma mark - Save Items

/**
 save an item or update an item with 'key' if it already exists.
 **/
-(BOOL)saveItem:(FWKDStorageItem*)item;

/**
 save an item or update an item with 'key' if it already exists.
 save a key-data pair to sqlite
 **/
-(BOOL)saveItemWithKey:(NSString*)key data:(NSData*)data;

/**
 save an item or update an item with 'key' if it already exists.
 if the fileName is empty, the data will be saved to sqlite.
 if the fileName is not empty, the data will be saved as a file to sandBox.
 Anyway,there will be a record in sqlite.
 **/
-(BOOL)saveItemWithKey:(NSString*)key data:(NSData*)data fileName:(NSString *)fileName;

#pragma mark - Remove Items

/**
 Delete the record in sqlite.
 Delete the file in the sandBox if fileName exists.
 **/
-(BOOL)removeItemForKey:(NSString*)key;

/**
 Remove items wiht an array of keys.
 **/
-(BOOL)removeItemForKeys:(NSArray<NSString*> *)keys;

/**
 Remove items which 'data' is large than a special size.
 **/
-(BOOL)removeItemsLargeThanSize:(int)size;

/**
 Remove all items which 'last_access_time' earlier than a special timestamp.
 **/
- (BOOL)removeItemsEarlierThanTime:(int)time;

/**
 Remove some items to make total size not larger than a special size.
 The least recently used (LRU) items will be removed first.
 **/
-(BOOL)removeItemsFitSize:(int)maxSize;

/**
 Remove some items to make total count not lagger than a special count.
 The least recently used (LRU) items will be remove first.
 **/
-(BOOL)removeItemsFitCount:(int)maxCount;

/**
 Remove all items
 **/
-(BOOL)removeAllItems;


#pragma mark - Get Items

/**
 Get item with key.
 Update last_access_time.
 **/
-(FWKDStorageItem*)getItemForKey:(NSString*)key;

/**
 Get item with key but the item.data is ignored
 **/
-(FWKDStorageItem*)getItemExcludeDataForKey:(NSString*)key;

/**
 Get item data with key
 Update last_access_time.
 **/
-(NSData*)getItemDataForKey:(NSString*)key;

/**
 Get items with an array of keys
 Update last_access_time.
 **/
-(NSArray<FWKDStorageItem*> *)getItemForKeys:(NSArray<NSString*> *)keys;

/**
 Get items with an array of keys
 But the 'data' in items will be ignored
 **/
-(NSArray<FWKDStorageItem*> *)getItemExcludeDataForKeys:(NSArray<NSString*> *)keys;


/**
 Get items data with an array of keys
 Update last_access_time.
 **/
-(NSDictionary<NSString*,NSData*> *)getItemDataForKeys:(NSArray<NSString*> *)keys;

#pragma mark - Status

/**
 Whether an item exists for a special key.
 **/
-(BOOL)itemExistsForKey:(NSString*)key;

/**
 Total count of all items.
 **/
-(int)getItemsCount;

/**
 Total size of all items.
 **/
-(int)getItemsSize;

@end
