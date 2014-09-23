/*
 Copyright (c) 2012 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 One does not claim this software as ones own.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "M13OrderedDictionary.h"

@implementation M13OrderedDictionary

#pragma mark - Creation

+ (id)orderedDictionary{
    return [[M13OrderedDictionary alloc] init];
}

+ (id)orderedDictionaryWithOrderedDictionary:(M13OrderedDictionary *)orderedDictionary
{
    return [[M13OrderedDictionary alloc] initWithOrderedDictionary:orderedDictionary];
}

+ (id)orderedDictionaryWithContentsOfFile:(NSString *)path
{
    return [[M13OrderedDictionary alloc] initWithContentsOfFile:path];
}

+ (id)orderedDictionaryWithContentsOfURL:(NSURL *)URL
{
    return [[M13OrderedDictionary alloc] initWithContentsOfURL:URL];
}

+ (id)orderedDictionaryWithObject:(id)anObject pairedWithKey:(id<NSCopying>)aKey
{
    return [[M13OrderedDictionary alloc] initWithObjects:[NSArray arrayWithObject:anObject] pairedWithKeys:[NSArray arrayWithObject:aKey]];
}

+ (id)orderedDictionaryWithDictionary:(NSDictionary *)entrys
{
    return [[M13OrderedDictionary alloc] initWithContentsOfDictionary:entrys];
}

#pragma mark - initialization

- (id)init
{
    self = [super init];
    if (self != nil) {
        keys = [[NSMutableArray alloc] init];
        objects = [[NSMutableArray alloc] init];
        pairs = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithOrderedDictionary:(M13OrderedDictionary *)orderedDictionary
{
    return [self initWithOrderedDictionary:orderedDictionary copyEntries:NO];
}

- (id)initWithOrderedDictionary:(M13OrderedDictionary *)orderedDictionary copyEntries:(BOOL)flag
{
    self = [super init];
    if (self != nil) {
        keys = [[NSMutableArray alloc] initWithArray:orderedDictionary.allKeys copyItems:flag];
        objects = [[NSMutableArray alloc] initWithArray:orderedDictionary.allObjects copyItems:flag];
        pairs = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys];
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
    NSDictionary *rawData = [NSDictionary dictionaryWithContentsOfFile:path];
    return [self initWithObjects:[rawData objectForKey:@"Objects"] pairedWithKeys:[rawData objectForKey:@"Keys"]];
}

- (id)initWithContentsOfURL:(NSURL *)URL
{
    NSDictionary *rawData = [NSDictionary dictionaryWithContentsOfURL:URL];
    return [self initWithObjects:[rawData objectForKey:@"Objects"] pairedWithKeys:[rawData objectForKey:@"Keys"]];
}

- (id)initWithContentsOfDictionary:(NSDictionary *)entrys
{
    self = [super init];
    if (self != nil) {
        keys = [[NSMutableArray alloc] initWithArray:entrys.allKeys];
        objects = [[NSMutableArray alloc] init];
        //Must loop through all keys, since order from NSDictionary is not defined.
        for (id key in keys) {
            [objects addObject:[entrys objectForKey:key]];
        }
        pairs = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys];
    }
    return self;
}

- (id)initWithObjects:(NSArray *)orderedObjects pairedWithKeys:(NSArray *)orderedKeys
{
    NSAssert(orderedObjects.count == orderedKeys.count, @"The amount of objects does not match the number of keys");
    NSAssert([[NSSet setWithArray:orderedKeys] count] == orderedKeys.count, @"There are duplicate keys on initialization");
    self = [super init];
    if (self != nil) {
        keys = [[NSMutableArray alloc] initWithArray:orderedKeys];
        objects = [[NSMutableArray alloc] initWithArray:orderedObjects];
        pairs = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys];
    }
    return self;
}

#pragma mark - Querying

- (BOOL)containsObject:(id)object
{
    return [objects containsObject:object];
}

- (BOOL)containsObject:(id)object pairedWithKey:(id<NSCopying>)key
{
    if ([object containsObject:object] && [keys containsObject:key]) {
        return YES;
    }
    return NO;
}

- (BOOL)containsEntry:(NSDictionary *)entry
{
    return [self containsObject:[entry.allValues objectAtIndex:0] pairedWithKey:[entry.allKeys objectAtIndex:0]];
}

- (NSUInteger)count
{
    return [keys count];
}

- (id)lastObject
{
    return objects.lastObject;
}

- (id <NSCopying>)lastKey
{
    return keys.lastObject;
}

- (NSDictionary *)lastEntry
{
    return [NSDictionary dictionaryWithObject:objects.lastObject forKey:keys.lastObject];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [objects objectAtIndex:index];
}

- (id<NSCopying>)keyAtIndex:(NSUInteger)index
{
    return [keys objectAtIndex:index];
}

- (NSDictionary *)entryAtIndex:(NSUInteger)index
{
    return [NSDictionary dictionaryWithObject:[self objectAtIndex:index] forKey:[keys objectAtIndex:index]];
}

- (NSArray *)objectsAtIndices:(NSIndexSet *)indexes
{
    return [objects objectsAtIndexes:indexes];
}

- (NSArray *)keysAtIndices:(NSIndexSet *)indexes
{
    return [keys objectsAtIndexes:indexes];
}

- (M13OrderedDictionary *)entriesAtIndices:(NSIndexSet *)indexes
{
    return [[M13OrderedDictionary alloc] initWithObjects:[objects objectsAtIndexes:indexes] pairedWithKeys:[keys objectsAtIndexes:indexes]];
}

- (NSDictionary *)unorderedEntriesAtIndices:(NSIndexSet *)indexes
{
    return [NSDictionary dictionaryWithObjects:[objects objectsAtIndexes:indexes] forKeys:[keys objectsAtIndexes:indexes]];
}

- (NSArray *)allKeys
{
    return keys;
}

- (NSArray *)allObjects
{
    return objects;
}

- (NSArray *)allKeysForObject:(id)anObject
{
    return [pairs allKeysForObject:anObject];
}

- (id)objectForKey:(id<NSCopying>)key
{
    return [pairs objectForKey:key];
}

- (NSArray *)objectForKeys:(NSArray *)orderedKeys notFoundMarker:(id)anObject
{
    return [pairs objectsForKeys:orderedKeys notFoundMarker:anObject];
}

#pragma mark - Enumeration

- (NSEnumerator *)objectEnumerator
{
    return [objects objectEnumerator];
}

- (NSEnumerator *)keyEnumerator
{
    return [keys objectEnumerator];
}

- (NSEnumerator *)entryEnumerator
{
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < keys.count; i++) {
        [temp addObject:[self entryAtIndex:i]];
    }
    return [temp objectEnumerator];
}

- (NSEnumerator *)reverseObjectEnumerator
{
    return [objects reverseObjectEnumerator];
}

- (NSEnumerator *)reverseKeyEnumerator
{
    return [keys reverseObjectEnumerator];
}

- (NSEnumerator *)reverseEntryEnumerator
{
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    for (NSUInteger i = 1; i <= keys.count; i--) {
        [temp addObject:[self entryAtIndex:(keys.count - i)]];
    }
    return [temp objectEnumerator];
}

#pragma mark - Searching

- (NSUInteger)indexOfObject:(id)object
{
    return [objects indexOfObject:object];
}

- (NSUInteger)indexOfKey:(id<NSCopying>)key
{
    return [keys indexOfObject:key];
}

- (NSUInteger)indexOfEntryWithObject:(id)object pairedWithKey:(id<NSCopying>)key
{
    NSIndexSet *idx1 = [objects indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqual:object];
    }];
    NSIndexSet *idx2 = [keys indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqual:key];
    }];
    NSUInteger index = NSNotFound;
    NSUInteger current_index = [idx1 firstIndex];
    while (current_index != NSNotFound && index == NSNotFound)
    {
        if ([idx2 containsIndex:current_index]) {
            index = current_index;
        }
        current_index = [idx1 indexGreaterThanIndex:current_index];
    }
    return index;
}

- (NSUInteger)indexOfEntry:(NSDictionary *)entry
{
    return [self indexOfEntryWithObject:[entry.allValues objectAtIndex:0] pairedWithKey:[entry.allKeys objectAtIndex:0]];
}

- (NSUInteger)indexOfObject:(id)object inRange:(NSRange)range
{
    return [objects indexOfObject:object inRange:range];
}

- (NSUInteger)indexOfKey:(id<NSCopying>)key inRange:(NSRange)range
{
    return [keys indexOfObject:key inRange:range];
}

- (NSUInteger)indexOfEntryWithObject:(id)object pairedWithKey:(id<NSCopying>)key inRange:(NSRange)range
{
    NSIndexSet *idx1 = [[objects objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]]indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqual:object];
    }];
    NSIndexSet *idx2 = [[keys objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqual:key];
    }];
    NSUInteger index = NSNotFound;
    NSUInteger current_index = [idx1 firstIndex];
    while (current_index != NSNotFound && index == NSNotFound)
    {
        if ([idx2 containsIndex:current_index]) {
            index = current_index;
        }
        current_index = [idx1 indexGreaterThanIndex:current_index];
    }
    return index;
}

- (NSUInteger)indexOfEntry:(NSDictionary *)entry inRange:(NSRange)range
{
    return [self indexOfEntryWithObject:[entry.allValues objectAtIndex:0] pairedWithKey:[entry.allKeys objectAtIndex:0] inRange:range];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)object
{
    return [objects indexOfObjectIdenticalTo:object];
}

- (id<NSCopying>)keyOfObjectIdenticalTo:(id)object
{
    return [keys objectAtIndex:[objects indexOfObjectIdenticalTo:object]];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)object inRange:(NSRange)range
{
    return [objects indexOfObjectIdenticalTo:object inRange:range];
}

- (id<NSCopying>)keyOfObjectIdenticalTo:(id)object inRange:(NSRange)range
{
    return [keys objectAtIndex:[objects indexOfObjectIdenticalTo:object inRange:range]];
}

- (NSUInteger)indexOfObjectPassingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [objects indexOfObjectPassingTest:predicate];
}

- (id<NSCopying>)keyOfObjectPassingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [keys objectAtIndex:[objects indexOfObjectPassingTest:predicate]];
}

- (NSUInteger)indexOfObjectWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [objects indexOfObjectWithOptions:opts passingTest:predicate];
}

- (id<NSCopying>)keyOfObjectWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [keys objectAtIndex:[objects indexOfObjectWithOptions:opts passingTest:predicate]];
}

- (NSUInteger)indexOfObjectAtIndices:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [objects indexOfObjectAtIndexes:indexSet options:opts passingTest:predicate];
}

- (id<NSCopying>)keyOfObjectAtIndices:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [keys objectAtIndex:[objects indexOfObjectAtIndexes:indexSet options:opts passingTest:predicate]];
}

- (NSUInteger)indexOfObject:(id)object inSortedRange:(NSRange)r options:(NSBinarySearchingOptions)opts usingComparator:(NSComparator)cmp
{
    return [objects indexOfObject:object inSortedRange:r options:opts usingComparator:cmp];
}

- (id<NSCopying>)keyOfObject:(id)object inSortedRange:(NSRange)r options:(NSBinarySearchingOptions)opts usingComparator:(NSComparator)cmp
{
    return [keys objectAtIndex:[object indexOfObject:object inSortedRange:r options:opts usingComparator:cmp]];
}

- (NSIndexSet *)indicesOfObjectsPassingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [objects indexesOfObjectsPassingTest:predicate];
}

- (NSArray *)keysOfObjectsPassingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [keys objectsAtIndexes:[objects indexesOfObjectsPassingTest:predicate]];
}

- (NSIndexSet *)indicesOfObjectsWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [objects indexesOfObjectsWithOptions:opts passingTest:predicate];
}

- (NSArray *)keysOfObjectsWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [keys objectsAtIndexes:[objects indexesOfObjectsWithOptions:opts passingTest:predicate]];
}

- (NSIndexSet *)indicesOfObjectsAtIndices:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [objects indexesOfObjectsAtIndexes:indexSet options:opts passingTest:predicate];
}

- (NSArray *)keysOfObjectsAtIndices:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate
{
    return [keys objectsAtIndexes:[objects indexesOfObjectsAtIndexes:indexSet options:opts passingTest:predicate]];
}

#pragma mark - Preforming Selectors

- (void)makeObjectsPreformSelector:(SEL)aSelector
{
    [objects makeObjectsPerformSelector:aSelector];
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject
{
    [objects makeObjectsPerformSelector:aSelector withObject:anObject];
}

- (void)enumerateObjectsUsingBlock:(void (^)(id, NSUInteger, BOOL *))block
{
    [objects enumerateObjectsUsingBlock:block];
}

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(id, NSUInteger, BOOL *))block
{
    [objects enumerateObjectsWithOptions:opts usingBlock:block];
}

- (void)enumerateObjectsAtIndices:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts usingBlock:(void (^)(id, NSUInteger, BOOL *))block
{
    [objects enumerateObjectsAtIndexes:indexSet options:opts usingBlock:block];
}

#pragma mark - Comparing

- (id)firstObjectInCommonWithOrderedDictionary:(M13OrderedDictionary *)otherOrderedDictionary
{
    return [objects firstObjectCommonWithArray:otherOrderedDictionary.allObjects];
}

- (id)firstKeyInCommonWithOrderedDictionary:(M13OrderedDictionary *)otherOrderedDictionary
{
    return [keys firstObjectCommonWithArray:otherOrderedDictionary.allKeys];
}

- (id)firstEntryInCommonWithOrderedDictionary:(M13OrderedDictionary *)otherOrderedDictionary
{
    NSArray *temp1 = [keys firstObjectCommonWithArray:otherOrderedDictionary.allKeys];
    
    id object = nil;
    int i = 0;
    while (i < temp1.count && object == nil) {
        if ([[self objectForKey:[temp1 objectAtIndex:i]] isEqual:[otherOrderedDictionary objectForKey:[temp1 objectAtIndex:i]]]) {
            objects = [self objectForKey:[temp1 objectAtIndex:i]];
        }
    }
    return object;
}

- (BOOL)isEqualToOrderedDictionary:(M13OrderedDictionary *)otherOrderedDictionary
{
    if ([self count] != otherOrderedDictionary.count) {
        return NO;
    } else {
        BOOL A = [keys isEqualToArray:otherOrderedDictionary.allKeys];
        BOOL B = [objects isEqualToArray:otherOrderedDictionary.allObjects];
        if (A && B) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Deriving

- (M13OrderedDictionary *)orderedDictionaryByAddingObject:(id)object pairedWithKey:(id<NSCopying>)aKey
{
    return [[M13OrderedDictionary alloc] initWithObjects:[objects arrayByAddingObject:object] pairedWithKeys:[keys arrayByAddingObject:aKey]];
}

- (M13OrderedDictionary *)orderedDictionaryByAddingEntry:(NSDictionary *)entry
{
    return [[M13OrderedDictionary alloc] initWithObjects:[objects arrayByAddingObject:[entry.allValues objectAtIndex:0]] pairedWithKeys:[keys arrayByAddingObject:[entry.allKeys objectAtIndex:0]]];
}

- (M13OrderedDictionary *)orderedDictionaryByAddingObjects:(NSArray *)orderedObjects pairedWithKeys:(NSArray *)orderedKeys
{
    return [[M13OrderedDictionary alloc] initWithObjects:[objects arrayByAddingObjectsFromArray:orderedObjects] pairedWithKeys:[keys arrayByAddingObjectsFromArray:orderedKeys]];
}

- (M13OrderedDictionary *)filteredOrderDictionarysUsingPredicateForObjects:(NSPredicate *)predicate
{
    NSArray *tempObj = [objects filteredArrayUsingPredicate:predicate];
    int i = 0;
    int j = 0;
    NSMutableArray *tempKey = [[NSMutableArray alloc] init];
    //Iterate though, since all objects are returned in order, you can just look along, object by object, untill they are equal, and grab the coresponding key.
    while (i < tempObj.count && j < keys.count) {
        if ([[tempObj objectAtIndex:i] isEqual:[objects objectAtIndex:j]]) {
            [tempKey addObject:[keys objectAtIndex:j]];
            j++;
            i++;
        }
        j++;
    }
    return [[M13OrderedDictionary alloc] initWithObjects:tempObj pairedWithKeys:tempKey];
}

- (M13OrderedDictionary *)subOrderedDictionaryWithRange:(NSRange)range
{
    return [[M13OrderedDictionary alloc] initWithObjects:[objects subarrayWithRange:range] pairedWithKeys:[keys subarrayWithRange:range]];
}

#pragma mark - Sorting
//Internal functions
- (NSArray *)keysForSortedObjects:(NSArray *)tempObj
{
    NSMutableArray *tempKey = [[NSMutableArray alloc] init];
    NSMutableArray *testObj = [[NSMutableArray alloc] initWithArray:objects];
    NSMutableArray *testKey = [[NSMutableArray alloc] initWithArray:keys];
    //Loop through and find first identical object, and  add that key to the array. then delete that pair from the testers so they are not used again. (That way if there is an identical object with a diffrent key, it will get used.)
    while (testObj.count > 0) {
        NSInteger index = [testObj indexOfObjectIdenticalTo:[tempObj objectAtIndex:(tempObj.count - testObj.count)]];
        [tempKey addObject:[testKey objectAtIndex:index]];
        [testKey removeObjectAtIndex:index];
        [testObj removeObjectAtIndex:index];
    }
    return tempKey;
}

- (NSArray *)objectsForSortedKeys:(NSArray *)tempKey
{
    NSMutableArray *tempObj = [[NSMutableArray alloc] init];
    for (id key in tempKey) {
        [tempObj addObject:[pairs objectForKey:key]];
    }
    return tempObj;
}
/////////////////

- (NSData *)sortedObjectsHint
{
    return [objects sortedArrayHint];
}

- (NSData *)sortedKeysHint
{
    return [keys sortedArrayHint];
}

- (M13OrderedDictionary *)sortedByObjectsUsingFunction:(NSInteger (*)(__strong id, __strong id, void *))comparator context:(void *)context
{
    NSArray *tempObj = [objects sortedArrayUsingFunction:comparator context:context];
    return [[M13OrderedDictionary alloc] initWithObjects:tempObj pairedWithKeys:[self keysForSortedObjects:tempObj]];
}

- (M13OrderedDictionary *)sortedByKeysUsingFunction:(NSInteger (*)(__strong id<NSCopying>, __strong id<NSCopying>, void *))comparator context:(void *)context
{
    NSArray *tempKey = [keys sortedArrayUsingFunction:comparator context:context];
    return [[M13OrderedDictionary alloc] initWithObjects:[self objectsForSortedKeys:tempKey] pairedWithKeys:tempKey];
}

- (M13OrderedDictionary *)sortedByObjectsUsingFunction:(NSInteger (*)(__strong id, __strong id, void *))comparator context:(void *)context hint:(NSData *)hint
{
    NSArray *tempObj = [objects sortedArrayUsingFunction:comparator context:context hint:hint];
    return [[M13OrderedDictionary alloc] initWithObjects:tempObj pairedWithKeys:[self keysForSortedObjects:tempObj]];
}

- (M13OrderedDictionary *)sortedByKeysUsingFunction:(NSInteger (*)(__strong id<NSCopying>, __strong id<NSCopying>, void *))comparator context:(void *)context hint:(NSData *)hint
{
    NSArray *tempKey = [keys sortedArrayUsingFunction:comparator context:context hint:hint];
    return [[M13OrderedDictionary alloc] initWithObjects:[self objectsForSortedKeys:tempKey] pairedWithKeys:tempKey];
}

- (M13OrderedDictionary *)sortedByObjectsUsingDescriptors:(NSArray *)descriptors
{
    NSArray *tempObj = [objects sortedArrayUsingDescriptors:descriptors];
    return [[M13OrderedDictionary alloc] initWithObjects:tempObj pairedWithKeys:[self keysForSortedObjects:tempObj]];
}

- (M13OrderedDictionary *)sortedByKeysUsingDescriptors:(NSArray *)descriptors
{
    NSArray *tempKey = [keys sortedArrayUsingDescriptors:descriptors];
    return [[M13OrderedDictionary alloc] initWithObjects:[self objectsForSortedKeys:tempKey] pairedWithKeys:tempKey];
}

- (M13OrderedDictionary *)sortedByObjectsUsingSelector:(SEL)comparator
{
    NSArray *tempObj = [objects sortedArrayUsingSelector:comparator];
    return [[M13OrderedDictionary alloc] initWithObjects:tempObj pairedWithKeys:[self keysForSortedObjects:tempObj]];
}

- (M13OrderedDictionary *)sortedByKeysUsingSelector:(SEL)comparator
{
    NSArray *tempKey = [keys sortedArrayUsingSelector:comparator];
    return [[M13OrderedDictionary alloc] initWithObjects:[self objectsForSortedKeys:tempKey] pairedWithKeys:tempKey];
}

- (M13OrderedDictionary *)sortedByObjectsUsingComparator:(NSComparator)cmptr
{
    NSArray *tempObj = [objects sortedArrayUsingComparator:cmptr];
    return [[M13OrderedDictionary alloc] initWithObjects:tempObj pairedWithKeys:[self keysForSortedObjects:tempObj]];
}

- (M13OrderedDictionary *)sortedByKeysUsingComparator:(NSComparator)cmptr
{
    NSArray *tempKey = [keys sortedArrayUsingComparator:cmptr];
    return [[M13OrderedDictionary alloc] initWithObjects:[self objectsForSortedKeys:tempKey] pairedWithKeys:tempKey];
}

- (M13OrderedDictionary *)sortedByObjectsWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr
{
    NSArray *tempObj = [objects sortedArrayWithOptions:opts usingComparator:cmptr];
    return [[M13OrderedDictionary alloc] initWithObjects:tempObj pairedWithKeys:[self keysForSortedObjects:tempObj]];    
}

- (M13OrderedDictionary *)sortedByKeysWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr
{
    NSArray *tempKey = [objects sortedArrayWithOptions:opts usingComparator:cmptr];
    return [[M13OrderedDictionary alloc] initWithObjects:[self objectsForSortedKeys:tempKey] pairedWithKeys:tempKey];
}

#pragma mark - Description

- (NSString *)description
{
    NSMutableString *string = [[NSMutableString alloc] init];
    [string appendString:@"{"];
    for (int i = 0; i < self.count; i++) {
        id key = [keys objectAtIndex:i];
        id object = [objects objectAtIndex:i];
        NSString *keyDes = @"";
        NSString *objDes = @"";
        if ([key respondsToSelector:@selector(description)]) {
            keyDes = [key description];
        } else {
            keyDes = nil;
        }
        if ([object respondsToSelector:@selector(description)]) {
            objDes = [object description];
        } else {
            objDes = nil;
        }
        
        [string appendFormat:@"\n\t%@ = %@", keyDes, objDes];
        
        if (i < self.count - 1)
        {
            [string appendString:@";"];
        }
    }
    [string appendString:@"\n}"];
    return string;
}

- (NSString *)descriptionWithLocale:(id)locale
{
    NSMutableString *string = [[NSMutableString alloc] init];
    [string appendString:@"{"];
    for (int i = 0; i < self.count; i++) {
        id key = [keys objectAtIndex:i];
        id object = [objects objectAtIndex:i];
        NSString *keyDes = @"";
        NSString *objDes = @"";
        if ([key respondsToSelector:@selector(descriptionWithLocale:indent:)])
        {
            keyDes = [key descriptionWithLocale:locale indent:1];
        }
        else if ([key respondsToSelector:@selector(descriptionWithLocale:)]) {
            keyDes = [key descriptionWithLocale:locale];
        } else if ([key respondsToSelector:@selector(description)]) {
            keyDes = [key description];
        } else {
            keyDes = nil;
        }
        if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)])
        {
            objDes = [object descriptionWithLocale:locale indent:1];
        }
        else if ([object respondsToSelector:@selector(descriptionWithLocale:)]) {
            objDes = [object descriptionWithLocale:locale];
        } else if ([object respondsToSelector:@selector(description)]) {
            objDes = [object description];
        } else {
            objDes = nil;
        }
        
        [string appendFormat:@"\n\t%@ = %@", keyDes, objDes];
        
        if (i < self.count - 1)
        {
            [string appendString:@";"];
        }
        
    }
    [string appendString:@"\n}"];
    return string;
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level
{
    NSMutableString *string = [[NSMutableString alloc] init];
    [string appendString:@"    {"];
    for (int i = 0; i < self.count; i++) {
        id key = [keys objectAtIndex:i];
        id object = [objects objectAtIndex:i];
        NSString *keyDes = @"";
        NSString *objDes = @"";
        if ([key respondsToSelector:@selector(descriptionWithLocale:indent:)]) {
            keyDes = [key descriptionWithLocale:locale indent:level + 1];
        } else if ([key respondsToSelector:@selector(descriptionWithLocale:)]) {
            keyDes = [key descriptionWithLocale:locale];
        } else if ([key respondsToSelector:@selector(description)]) {
            keyDes = [key description];
        } else {
            keyDes = nil;
        }
        if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)]) {
            objDes = [object descriptionWithLocale:locale indent:level + 1];
        } else if ([object respondsToSelector:@selector(descriptionWithLocale:)]) {
            objDes = [object descriptionWithLocale:locale];
        } else if ([object respondsToSelector:@selector(description)]) {
            objDes = [object description];
        } else {
            objDes = nil;
        }
        
        for (int i = 0; i < level; i++)
        {
            [string appendString:@"\t"];
        }
        
        [string appendFormat:@"\n%@ = %@", keyDes, objDes];
        
        if (i < self.count - 1)
        {
            [string appendString:@";"];
        }
    }
    
    [string appendString:@"\n"];
    for (int i = 0; i < level; i++)
    {
        [string appendString:@"\t"];
    }
    [string appendString:@"}"];
    return string;
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    return [dict writeToFile:path atomically:flag];
}

- (BOOL)writeToURL:(NSURL *)aURL atomically:(BOOL)flag
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    return [dict writeToURL:aURL atomically:flag];
}

#pragma mark - KVO

- (void)addObserver:(NSObject *)anObserver toObjectsAtIndices:(NSIndexSet *)indexes forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    [objects addObserver:anObserver toObjectsAtIndexes:indexes forKeyPath:keyPath options:options context:context];
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    [pairs addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (void)removeObserver:(NSObject *)anObserver fromObjectsAtIndices:(NSIndexSet *)indexes forKeyPath:(NSString *)keyPath
{
    [objects removeObserver:anObserver fromObjectsAtIndexes:indexes forKeyPath:keyPath];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context
{
    [pairs removeObserver:observer forKeyPath:keyPath context:context];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    [objects setValue:value forKey:key];
}

- (id)valueForKey:(NSString *)key
{
    return [objects valueForKey:key];
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    [pairs setValue:value forKeyPath:keyPath];
}

- (id)valueForKeyPath:(NSString *)keyPath
{
    return [pairs valueForKeyPath:keyPath];
}

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:objects forKey:@"NSODObjects"];
    [aCoder encodeObject:keys forKey:@"NSODKeys"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    return [self initWithObjects:[decoder decodeObjectForKey:@"NSODObjects"] pairedWithKeys:[decoder decodeObjectForKey:@"NSODKeys"]];
}

#pragma mark - NSCopying

- (id)copy
{
    return [self copyWithZone:NSDefaultMallocZone()];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[M13OrderedDictionary alloc] initWithObjects:[objects copyWithZone:zone] pairedWithKeys:[keys copyWithZone:zone]];
}

- (id)mutableCopy
{
    return [self mutableCopyWithZone:NSDefaultMallocZone()];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[M13MutableOrderedDictionary alloc] initWithOrderedDictionary:self];
}

#pragma mark - NSFastEnumeration


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    return [keys countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - Indexed Subscripts
- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    return [objects objectAtIndex:index];
}

- (id)objectForKeyedSubscript:(id)key
{
    return [pairs objectForKey:key];
}

@end

/*********************************************************************************
 
 NSMutableDictionary
 
 ********************************************************************************/

@implementation M13MutableOrderedDictionary

#pragma mark - Creating

+ (id)orderedDictionaryWithCapacity:(NSUInteger)numEntrys
{
    return [[M13MutableOrderedDictionary alloc] initWithCapacity:numEntrys];
}

- (id)initWithCapacity:(NSUInteger)numEntrys
{
    return [[M13MutableOrderedDictionary alloc] initWithObjects:[NSMutableArray arrayWithCapacity:numEntrys] pairedWithKeys:[NSMutableArray arrayWithCapacity:numEntrys]];
}

#pragma mark - Adding Objects

- (void)addObject:(id)object pairedWithKey:(id<NSCopying>)key
{
    if ([pairs objectForKey:key] != nil) {
        [self removeEntryWithKey:key];
    }
    [pairs setObject:object forKey:key];
    [keys addObject:key];
    [objects addObject:object];
}

- (void)addEntry:(NSDictionary *)entry
{
    [self addObject:[entry.allValues objectAtIndex:0] pairedWithKey:[entry.allKeys objectAtIndex:0]];
}

- (void)addEntriesFromOrderedDictionary:(M13OrderedDictionary *)orderedDictionary
{
    for (int i = 0; i < orderedDictionary.count; i++) {
        [self addObject:[orderedDictionary objectAtIndex:i] pairedWithKey:[orderedDictionary keyAtIndex:i]];
    }
}

- (void)addEntriesFromDictionary:(NSDictionary *)dictionary
{
    for (id key in dictionary.allKeys) {
        [self addObject:[dictionary objectForKey:key] pairedWithKey:key];
    }
}

- (void)insertObject:(id)object pairedWithKey:(id<NSCopying>)key atIndex:(NSUInteger)index
{
    if ([pairs objectForKey:key] != nil) {
        [self removeEntryWithKey:key];
    }
    
    [pairs setObject:object forKey:key];
    [keys insertObject:key atIndex:index];
    [objects insertObject:object atIndex:index];
}

- (void)insertEntry:(NSDictionary *)entry atIndex:(NSUInteger)index
{
    [self insertObject:[entry.allValues objectAtIndex:0] pairedWithKey:[entry.allKeys objectAtIndex:0] atIndex:index];
}

- (void)insertEntriesFromOrderedDictionary:(M13OrderedDictionary *)orderedDictionary atIndex:(NSUInteger)index
{
    for (int i = 0; i < orderedDictionary.count; i++) {
        [self insertObject:[orderedDictionary objectAtIndex:i] pairedWithKey:[orderedDictionary keyAtIndex:i] atIndex:(index + i)];
    }
}

- (void)insertEntriesFromDictionary:(NSDictionary *)dictionary atIndex:(NSUInteger)index
{
    NSUInteger i = index;
    for (id key in dictionary.allKeys) {
        [self insertObject:[dictionary objectForKey:key] pairedWithKey:key atIndex:i];
        i++;
    }
}

- (void)setObject:(id)object forKey:(id<NSCopying>)aKey
{
    if ([pairs objectForKey:aKey] != nil) {
        [pairs setObject:object forKey:aKey];
        [objects replaceObjectAtIndex:[self indexOfKey:aKey] withObject:object];
    } else {
        [self addObject:object pairedWithKey:aKey];
    }
}

- (void)setEntry:(NSDictionary *)entry
{
    [self setObject:[entry.allValues objectAtIndex:0] forKey:[entry.allKeys objectAtIndex:0]];
}

- (void)setEntriesFromOrderedDictionary:(M13OrderedDictionary *)orderedDictionary
{
    for (NSUInteger i = 0; i < orderedDictionary.count; i++) {
        [self setObject:[orderedDictionary objectAtIndex:i] forKey:[orderedDictionary keyAtIndex:i]];
    }
}

- (void)setEntriesFromDictionary:(NSDictionary *)dictionary
{
    for (id key in dictionary.allKeys) {
        [self setObject:[dictionary objectForKey:key] forKey:key];
    }
}

- (void)setObject:(id)object forKey:(id<NSCopying>)aKey atIndex:(NSUInteger)index
{
    if ([pairs objectForKey:aKey] != nil) {
        [pairs setObject:object forKey:aKey];
        [objects replaceObjectAtIndex:[self indexOfKey:aKey] withObject:object];
    } else {
        [self insertObject:object pairedWithKey:keys atIndex:index];
    }
}

- (void)setEntry:(NSDictionary *)entry atIndex:(NSUInteger)index
{
    [self setObject:[entry.allValues objectAtIndex:0] forKey:[entry.allKeys objectAtIndex:0] atIndex:index];
}

- (void)setEntriesFromOrderedDictionary:(M13OrderedDictionary *)orderedDictionary atIndex:(NSUInteger)index
{
    for (NSUInteger i = 0; i < orderedDictionary.count; i++) {
        [self setObject:[orderedDictionary objectAtIndex:i] forKey:[orderedDictionary keyAtIndex:i] atIndex:(index + i)];
    }
}

- (void)setEntriesFromDictionary:(NSDictionary *)dictionary atIndex:(NSUInteger)index
{
    NSUInteger i = index;
    for (id key in dictionary.allKeys) {
        [self setObject:[dictionary objectForKey:key] forKey:key atIndex:i];
        i++;
    }
}

#pragma mark - Removing

- (void)removeObjectForKey:(id)key
{
    [self removeEntryWithKey:key];
}

- (void)removeObjectsForKeys:(NSArray *)arrayKeys
{
    [self removeEntriesWithKeysInArray:arrayKeys];
}

- (void)removeAllObjects
{
    [self removeAllEntries];
}

- (void)removeAllEntries
{
    [keys removeAllObjects];
    [objects removeAllObjects];
    [pairs removeAllObjects];
}

- (void)removeLastEntry
{
    [self removeEntryAtIndex:(keys.count - 1)];
}

- (void)removeEntryWithObject:(id)object
{
    [self removeEntryAtIndex:[self indexOfObject:object]];
}

- (void)removeEntryWithKey:(id<NSCopying>)key
{
    [self removeEntryAtIndex:[self indexOfKey:key]];
}

- (void)removeEntryWithObject:(id)object pairedWithKey:(id<NSCopying>)key
{
    [self removeEntryAtIndex:[self indexOfEntryWithObject:object pairedWithKey:key]];
}

- (void)removeEntry:(NSDictionary *)entry
{
    [self removeEntryWithObject:[entry.allValues objectAtIndex:0] pairedWithKey:[entry.allKeys objectAtIndex:0]];
}

- (void)removeEntryWithObject:(id)object inRange:(NSRange)range
{
    [self removeEntryAtIndex:[self indexOfObject:object inRange:range]];
}

- (void)removeEntryWithKey:(id<NSCopying>)key inRange:(NSRange)range
{
    [self removeEntryAtIndex:[self indexOfKey:key inRange:range]];
}

- (void)removeEntryWithObject:(id)object pairedWithKey:(id<NSCopying>)key inRange:(NSRange)ramge
{
    [self removeEntryAtIndex:[self indexOfEntryWithObject:object pairedWithKey:key inRange:ramge]];
}

- (void)removeEntry:(NSDictionary *)entry inRange:(NSRange)range
{
    [self removeEntryAtIndex:[self indexOfEntry:entry inRange:range]];
}

- (void)removeEntryAtIndex:(NSUInteger)index
{
    id key = [keys objectAtIndex:index];
    [keys removeObjectAtIndex:index];
    [objects removeObjectAtIndex:index];
    [pairs removeObjectForKey:key];
}

- (void)removeEntriesAtIndices:(NSIndexSet *)indexes
{
    NSArray *tempKey = [self keysAtIndices:indexes];
    for (id key in tempKey) {
        [self removeEntryWithKey:key];
    }
}

- (void)removeEntryWithObjectIdenticalTo:(id)anObject
{
    [self removeEntryAtIndex:[self indexOfObjectIdenticalTo:anObject]];
}

- (void)removeEntryWithObjectIdenticalTo:(id)anObject inRange:(NSRange)range
{
    [self removeEntryAtIndex:[self indexOfObjectIdenticalTo:anObject inRange:range]];
}

- (void)removeEntriesWithObjectsInArray:(NSArray *)array
{
    for (id object in array) {
        [self removeEntryWithObject:object];
    }
}

- (void)removeEntriesWithKeysInArray:(NSArray *)array
{
    for (id key in array) {
        [self removeEntryWithKey:key];
    }
}

- (void)removeEntriesInRange:(NSRange)range
{
    for (NSUInteger i = range.location; i < range.location + range.length; i++) {
        [self removeEntryAtIndex:i];
    }
}

#pragma mark - Replacing Objects

- (void)replaceEntryAtIndex:(NSInteger)index withObject:(id)object pairedWithKey:(id<NSCopying>)key
{
    id oldKey = [keys objectAtIndex:index];
    [pairs removeObjectForKey:oldKey];
    [pairs setObject:object forKey:key];
    [keys replaceObjectAtIndex:index withObject:key];
    [objects replaceObjectAtIndex:index withObject:object];
}

- (void)replaceEntryAtIndex:(NSUInteger)index withEntry:(NSDictionary *)entry
{
    [self replaceEntryAtIndex:index withObject:[entry.allValues objectAtIndex:0] pairedWithKey:[entry.allKeys objectAtIndex:0]];
}

- (void)replaceEntriesAtIndices:(NSIndexSet *)indexes withObjects:(NSArray *)aobjects pairedWithKeys:(NSArray *)akeys
{
    NSUInteger index = [indexes firstIndex];
    int i = 0;
    while (index != NSNotFound) {
        if (i < aobjects.count && i < akeys.count) {
            [self replaceEntryAtIndex:index withObject:[aobjects objectAtIndex:i] pairedWithKey:[akeys objectAtIndex:i]];
        }
        index = [indexes indexGreaterThanIndex:index];
        i++;
    }
}

- (void)replaceEntriesAtIndices:(NSIndexSet *)indexes withEntries:(NSArray *)orderedEntrys
{
    NSUInteger index = [indexes firstIndex];
    int i = 0;
    while (index != NSNotFound) {
        if (i < orderedEntrys.count) {
            [self replaceEntryAtIndex:index withObject:[[orderedEntrys objectAtIndex:i] objectAtIndex:0] pairedWithKey:[[orderedEntrys objectAtIndex:i] objectAtIndex:0]];
        }
        index = [indexes indexGreaterThanIndex:index];
    }
}

- (void)replaceEntriesAtIndices:(NSIndexSet *)indexes withEntriesFromOrderedDictionary:(M13OrderedDictionary *)orderedDictionary
{
    NSUInteger index = [indexes firstIndex];
    int i = 0;
    while (index != NSNotFound) {
        if (i < orderedDictionary.count) {
            [self replaceEntryAtIndex:index withObject:[orderedDictionary objectAtIndex:i] pairedWithKey:[orderedDictionary keyAtIndex:i]];
        }
        index = [indexes indexGreaterThanIndex:index];
    }
}

- (void)replaceEntriesInRange:(NSRange)range withObjectsFromArray:(NSArray *)object pairedWithKeysFromArray:(NSArray *)key inRange:(NSRange)range2
{
    [self replaceEntriesAtIndices:[NSIndexSet indexSetWithIndexesInRange:range] withObjects:[object objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range2]] pairedWithKeys:[key objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range2]]];
}

- (void)replaceEntriesInRange:(NSRange)range withEntriesFrom:(NSArray *)orderedEntries inRange:(NSRange)range2
{
    [self replaceEntriesAtIndices:[NSIndexSet indexSetWithIndexesInRange:range] withEntries:[orderedEntries objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range2]]];
}

- (void)replaceEntriesInRange:(NSRange)range withEntriesFromOrderedDictionary:(M13OrderedDictionary *)dictionary inRange:(NSRange)range2
{
    [self replaceEntriesInRange:range withObjectsFromArray:[dictionary.allObjects objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range2]] pairedWithKeysFromArray:[dictionary.allKeys objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range2]]];
}

- (void)replaceEntriesInRange:(NSRange)range withObjectsFromArray:(NSArray *)object pairedWithKeysFromArray:(NSArray *)key
{
    [self replaceEntriesAtIndices:[NSIndexSet indexSetWithIndexesInRange:range] withObjects:object pairedWithKeys:key];
}

- (void)replaceEntriesInRange:(NSRange)range withEntriesFrom:(NSArray *)orderedEntrys
{
    [self replaceEntriesAtIndices:[NSIndexSet indexSetWithIndexesInRange:range] withEntries:orderedEntrys];
}

- (void)replaceEntriesInRange:(NSRange)range withEntriesFromOrderedDictionary:(M13OrderedDictionary *)dictionary
{
    [self replaceEntriesAtIndices:[NSIndexSet indexSetWithIndexesInRange:range] withEntriesFromOrderedDictionary:dictionary];
}

- (void)setEntriesToObjects:(NSArray *)object pairedWithKeys:(NSArray *)key
{
    int i = 0;
    while (i < object.count && i < key.count) {
        [self setObject:[object objectAtIndex:i] forKey:[key objectAtIndex:i]];
        i++;
    }
}

- (void)setEntriesToOrderedDictionary:(M13OrderedDictionary *)orderedDictionary
{
    for (id key in orderedDictionary.allKeys) {
        [self setObject:[orderedDictionary objectForKey:key] forKey:key];
    }
}

#pragma mark - Filtering
//Internal functions
- (NSArray *)keysForSortedObjects:(NSArray *)tempObj
{
    NSMutableArray *tempKey = [[NSMutableArray alloc] init];
    NSMutableArray *testObj = [[NSMutableArray alloc] initWithArray:objects];
    NSMutableArray *testKey = [[NSMutableArray alloc] initWithArray:keys];
    //Loop through and find first identical object, and  add that key to the array. then delete that pair from the testers so they are not used again. (That way if there is an identical object with a diffrent key, it will get used.)
    while (testObj.count > 0) {
        NSInteger index = [testObj indexOfObjectIdenticalTo:[tempObj objectAtIndex:(tempObj.count - testObj.count)]];
        [tempKey addObject:[testKey objectAtIndex:index]];
        [testKey removeObjectAtIndex:index];
        [testObj removeObjectAtIndex:index];
    }
    return tempKey;
}

- (NSArray *)objectsForSortedKeys:(NSArray *)tempKey
{
    NSMutableArray *tempObj = [[NSMutableArray alloc] init];
    for (id key in tempKey) {
        [tempObj addObject:[pairs objectForKey:key]];
    }
    return tempObj;
}
//////////////////

- (void)filterEntriesUsingPredicateForObjects:(NSPredicate *)predicate
{
    NSArray *tempObj = [objects filteredArrayUsingPredicate:predicate];
    NSArray *tempKey = [self keysForSortedObjects:tempObj];
    [pairs removeAllObjects];
    objects = [tempObj mutableCopy];
    keys = [tempKey mutableCopy];
    for (int i = 0; i < keys.count; i++) {
        [pairs setObject:[objects objectAtIndex:i] forKey:[keys objectAtIndex:i]];
    }
}

#pragma mark - Sorting

- (void)exchangeEntryAtIndex:(NSUInteger)idx1 withEntryAtIndex:(NSUInteger)idx2
{
    [keys exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
    [objects exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
}

- (void)sortEntriesByObjectUsingDescriptors:(NSArray *)descriptors
{
    NSArray *tempObj = [objects sortedArrayUsingDescriptors:descriptors];
    NSArray *tempKey = [self keysForSortedObjects:tempObj];
    keys = [tempKey mutableCopy];
    objects = [tempObj mutableCopy];
}

- (void)sortEntriesByKeysUsingDescriptors:(NSArray *)descriptors
{
    NSArray *tempKey = [keys sortedArrayUsingDescriptors:descriptors];
    NSArray *tempObj = [self objectsForSortedKeys:tempKey];
    keys = [tempKey mutableCopy];
    objects = [tempObj mutableCopy];
}

- (void)sortEntriesByObjectUsingComparator:(NSComparator)cmptr
{
    NSArray *tempObj = [objects sortedArrayUsingComparator:cmptr];
    NSArray *tempKey = [self keysForSortedObjects:tempObj];
    keys = [tempKey mutableCopy];
    objects = [tempObj mutableCopy];
}

- (void)sortEntriesByKeysUsingComparator:(NSComparator)cmptr
{
    NSArray *tempKey = [keys sortedArrayUsingComparator:cmptr];
    NSArray *tempObj = [self objectsForSortedKeys:tempKey];
    keys = [tempKey mutableCopy];
    objects = [tempObj mutableCopy];
}

- (void)sortEntriesByObjectWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr
{
    NSArray *tempObj = [objects sortedArrayWithOptions:opts usingComparator:cmptr];
    NSArray *tempKey = [self keysForSortedObjects:tempObj];
    keys = [tempKey mutableCopy];
    objects = [tempObj mutableCopy];
}

- (void)sortEntriesByKeysWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr
{
    NSArray *tempKey = [keys sortedArrayWithOptions:opts usingComparator:cmptr];
    NSArray *tempObj = [self objectsForSortedKeys:tempKey];
    keys = [tempKey mutableCopy];
    objects = [tempObj mutableCopy];
}

- (void)sortEntriesByObjectUsingFunction:(NSInteger (*)(__strong id, __strong id, void *))compare context:(void *)context
{
    NSArray *tempObj = [objects sortedArrayUsingFunction:compare context:context];
    NSArray *tempKey = [self keysForSortedObjects:tempObj];
    keys = [tempKey mutableCopy];
    objects = [tempObj mutableCopy];
}

- (void)sortEntriesByKeysUsingFunction:(NSInteger (*)(__strong id, __strong id, void *))compare context:(void *)context
{
    NSArray *tempKey = [keys sortedArrayUsingFunction:compare context:context];
    NSArray *tempObj = [self objectsForSortedKeys:tempKey];
    keys = [tempKey mutableCopy];
    objects = [tempObj mutableCopy];
}

- (void)sortEntriesByObjectUsingSelector:(SEL)comparator
{
    NSArray *tempObj = [objects sortedArrayUsingSelector:comparator];
    NSArray *tempKey = [self keysForSortedObjects:tempObj];
    keys = [tempKey mutableCopy];
    objects = [tempObj mutableCopy];
}

- (void)sortEntriesByKeysUsingSelector:(SEL)comparator
{
    NSArray *tempKey = [keys sortedArrayUsingSelector:comparator];
    NSArray *tempObj = [self objectsForSortedKeys:tempKey];
    keys = [tempKey mutableCopy];
    objects = [tempObj mutableCopy];
}

#pragma mark - Indexed Subscripts

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    [self setObject:obj forKey:key];
}

@end
