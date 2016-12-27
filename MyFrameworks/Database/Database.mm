#import "Database.h"

@implementation Database
NSString *dbName = @"app.sqlite";
sqlite3 *database = nil;

- (BOOL)open{
    NSArray *dbFolderPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dbFilePath = [[dbFolderPath objectAtIndex:0] stringByAppendingPathComponent:dbName];
    return (sqlite3_open([dbFilePath UTF8String], &database) == SQLITE_OK);
}

- (void)close{
    if (database != nil) {
        sqlite3_close(database);
    }
}

- (char *)initialized:(NSString *)name{
    char *errorMsg;
    if (database != nil) {
        const char *createSQL = [[NSString stringWithFormat:@"CREATE TABLE %@ (_SN integer primary key, _Value text);",name] UTF8String];
        if (sqlite3_exec(database, createSQL, NULL, NULL, &errorMsg) != SQLITE_OK) {
            NSLog(@"error: %s", errorMsg);
            //sqlite3_free(errorMsg);
            return errorMsg;
        }
    }
}

- (void)insertData:(NSString *)data tableName:(NSString *)name{
    char *errorMsg;
    if (database != nil) {
        NSString *sqlString = [NSString stringWithFormat:@"INSERT INTO %@ (_Value) values ('%@')",name, data];
        const char *insertSQL = [sqlString UTF8String];
        if (sqlite3_exec(database, insertSQL, NULL, NULL, &errorMsg) != SQLITE_OK) {
            NSLog(@"error: %s", errorMsg);
            sqlite3_free(errorMsg);
        }
    }
}

- (NSArray*)selectData:(NSString *)name{
    NSMutableArray *DataArray = [[NSMutableArray alloc] init];
    if (database != nil) {
        sqlite3_stmt *statement = nil;
        const char *selectSQL = [[NSString stringWithFormat:@"SELECT * FROM %@",name] UTF8String];
        if (sqlite3_prepare_v2(database, selectSQL, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSString *data = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
                NSString *data1 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];

                NSLog(@"column1 %@",data);
                NSLog(@"column0 %@", data1);
                [DataArray addObject:data];
            }
        }
        sqlite3_finalize(statement);
    }
    return [NSArray arrayWithArray:DataArray];
}

- (void)deleteData:(NSString *)name{
    char *errorMsg;
    if (database != nil) {
        const char *deleteSQL = [[NSString stringWithFormat:@"DELETE FROM %@",name] UTF8String];
        if (sqlite3_exec(database, deleteSQL, NULL, NULL, &errorMsg) != SQLITE_OK) {
            NSLog(@"error: %s", errorMsg);
            sqlite3_free(errorMsg);
        }
    }
}

- (void)updateData:(int) status {
    char *errorMsg;
    if (database != nil) {
        const char *updateSQL = [[NSString stringWithFormat:@"UPDATE status SET _Value = %d", status] UTF8String];
        if (sqlite3_exec(database, updateSQL, NULL, NULL, &errorMsg) != SQLITE_OK) {
            NSLog(@"error: %s", errorMsg);
            sqlite3_free(errorMsg);
        }
    }
}

- (char *)initializedValue:(NSString *)name{
    char *errorMsg;
    if (database != nil) {
        const char *createSQL = [[NSString stringWithFormat:@"CREATE TABLE %@ (_SN integer primary key, _xValue float, _yValue float, _zValue float, _size float, _xRotation float, _yRotation float, _zRotation float);",name] UTF8String];
        if (sqlite3_exec(database, createSQL, NULL, NULL, &errorMsg) != SQLITE_OK) {
            NSLog(@"error: %s", errorMsg);
            //sqlite3_free(errorMsg);
            return errorMsg;
        }
    }
}

- (void)insertDataValue:(NSString *)name xValue:(float)xValue yValue:(float)yValue zValue:(float)zValue size:(float)size xRotation:(float)xRotation yRotation:(float)yRotation zRotation:(float)zRotation{
    char *errorMsg;
    if (database != nil) {
        NSString *sqlString = [NSString stringWithFormat:@"INSERT INTO %@ (_xValue,_yValue,_zValue,_size,_xRotation,_yRotation,_zRotation) values ('%f','%f','%f','%f','%f','%f','%f')",name, xValue,yValue,zValue,size,xRotation,yRotation,zRotation];
        const char *insertSQL = [sqlString UTF8String];
        if (sqlite3_exec(database, insertSQL, NULL, NULL, &errorMsg) != SQLITE_OK) {
            NSLog(@"error~~~: %s", errorMsg);
            sqlite3_free(errorMsg);
        }
    }
}

- (NSArray*)selectDataValue:(NSString *)name selectId:(int) selectId{
    NSMutableArray *DataArray = [[NSMutableArray alloc] init];
    if (database != nil) {
        sqlite3_stmt *statement = nil;
        const char *selectSQL = [[NSString stringWithFormat:@"SELECT * FROM %@ WHERE _SN = '%d'",name, selectId] UTF8String];
        if (sqlite3_prepare_v2(database, selectSQL, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSString *data1 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
                NSString *data2 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)];
                NSString *data3 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
                NSString *data4 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 4)];
                NSString *data5 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 5)];
                NSString *data6 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 6)];
                NSString *data7 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 7)];
                //NSString *data1 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                
                [DataArray addObject:data1];
                [DataArray addObject:data2];
                [DataArray addObject:data3];
                [DataArray addObject:data4];
                [DataArray addObject:data5];
                [DataArray addObject:data6];
                [DataArray addObject:data7];
            }
        }
        sqlite3_finalize(statement);
    }
    return [NSArray arrayWithArray:DataArray];
}


@end