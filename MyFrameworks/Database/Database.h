#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface Database : NSObject
//資料庫開啟
- (BOOL)open;
//資料庫關閉
- (void)close;
//資料庫初始化
- (char *)initialized:(NSString *)name;
//新增資料
- (void)insertData:(NSString *)data tableName:(NSString *)name;
//查詢資料
- (NSArray*)selectData:(NSString *)name;
//刪除資料
- (void)deleteData:(NSString *)name;
//更新資料
- (void)updateData:(int) status;

//資料庫初始化
- (char *)initializedValue:(NSString *)name;
//新增資料
- (void)insertDataValue:(NSString *)name xValue:(float)xValue yValue:(float)yValue zValue:(float)zValue size:(float)size xRotation:(float)xRotation yRotation:(float)yRotation zRotation:(float)zRotation;
//查詢資料
- (NSArray*)selectDataValue:(NSString *)name selectId:(int) selectId;

@end