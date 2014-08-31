/*
 Copyright (c) 2012 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 One does not claim this software as ones own.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

/**A cross between NSDictionary and NSArray.
 @note Terminolgy:
 Entry - refers to an object-key pair.
 Object - refers to (id), with an index, and an assocoated key.
 Key - refers to <(id)NSCopying>, with an associated object.
 
 Each method at the end of its corresponding description will indicate what object (NSArray, NSDictionary) which that method is drawn from, so it is easier to find a longer description of what the method does.*/
@interface M13OrderedDictionary : NSObject <NSCopying, NSFastEnumeration, NSCoding>
{
    NSMutableArray *keys;
    NSMutableArray *objects;
    NSMutableDictionary *pairs;
}
/**@name Creation*/
/**Creates a new M13OrderedDictionary object.
 @return A M13OrderedDictionary object.*/
+ (instancetype)orderedDictionary;
/**Duplicates the M13OrderedDictionary, which will refrence the same objects that are in the given ordered dictionary.
 @param orderedDictionary The M13OrderedDictionary to duplicate.
 @return A M13OrderedDictionary object.*/
+ (instancetype)orderedDictionaryWithOrderedDictionary:(M13OrderedDictionary *)orderedDictionary;
/**Loads an M13OrderedDictionary from file.
 @param path The path of the file to load.
  @return A M13OrderedDictionary object.*/
+ (instancetype)orderedDictionaryWithContentsOfFile:(NSString *)path;
/**Loads an M13OrderedDictionary from the file at the given URL.
 @param URL The url of the file to load.
 @return A M13OrderedDictionary object.*/
+ (instancetype)orderedDictionaryWithContentsOfURL:(NSURL *)URL;
/**Create an M13OrderedDictionary with single entry.
 @param anObject The object that will be added to the M13OrderedDictionary.
 @param aKey The key for the object added to the M13OrderedDictionary.
 @return A M13OrderedDictionary object.*/
+ (instancetype)orderedDictionaryWithObject:(id)anObject pairedWithKey:(id<NSCopying>)aKey;
/**Create an M13OrderedDictionary with the contents of a NSDictionary.
 @param entries The NSDictionary to fill the ordered dictionary with.
 @return A M13OrderedDictionary object.
 @note The ordered dictionary entries will be ordered in the way their keys are returned by entries.allKeys*/
+ (instancetype)orderedDictionaryWithDictionary:(NSDictionary *)entries;

/**@name Initalization*/
/**Initalizes a new M13OrderedDictionary object.
 @return A M13OrderedDictionary object.*/
- (id)init;
/**Initializes an new M13OrderedDictionary object with another orderedDictionary, placing in itself the entries from the given orderedDictionary.
 @param orderedDictionary The dictionary to retreive the objects from.
 @return A M13OrderedDictionary object.*/
- (id)initWithOrderedDictionary:(M13OrderedDictionary *)orderedDictionary;
/**Initializes an new M13OrderedDictionary object with another orderedDictionary, optionally placing in itself copied entries from the given orderedDictionary.
 @param orderedDictionary The dictionary to retreive the objects from.
 @param flag Wether or not to copy the retreived objects.
 @return A M13OrderedDictionary object.*/
- (id)initWithOrderedDictionary:(M13OrderedDictionary *)orderedDictionary copyEntries:(BOOL)flag;
/**Initializes a newly allocated M13OrderedDictionary with the contents of the file at the given path.
 @param path The path of the file to load.
 @return A M13OrderedDictionary object.*/
- (id)initWithContentsOfFile:(NSString *)path;
/**Initalizes an M13OrderedDictionary from the file at the given URL.
 @param URL The url of the file to load.
 @return A M13OrderedDictionary object.*/
- (id)initWithContentsOfURL:(NSURL *)URL;
/**Initalizes an M13OrderedDictionary with the contents of a NSDictionary.
 @param entries The NSDictionary to fill the ordered dictionary with.
 @return A M13OrderedDictionary object.
 @note The ordered dictionary entries will be ordered in the way their keys are returned by entries.allKeys*/
- (id)initWithContentsOfDictionary:(NSDictionary *)entries;
/**Initalizes an M13OrderedDictionary with the given objects and keys.
 @param orderedObjects The array objects that will be added to the M13OrderedDictionary.
 @param orderedKeys The keys for the objects added to the M13OrderedDictionary, given in the same order as the objects.
 @return A M13OrderedDictionary object.*/
- (id)initWithObjects:(NSArray *)orderedObjects pairedWithKeys:(NSArray *)orderedKeys;

/**@name Querying*/
/**Check to see if a given object is in the ordered dictionary.
 @param object The object to check.
 @return Wether of not the object is in the ordered dictionary.*/
- (BOOL)containsObject:(id)object;
/**Check to see if an orderedDictionary conains the given entry.
 @param object The object to check.
 @param key The key to check.
 @return Wether or not the entry is in the ordered dictionary.*/
- (BOOL)containsObject:(id)object pairedWithKey:(id<NSCopying>)key;
/**Check to see if an orderedDictionary conains the given entry.
 @param entry The single object-key pair to check.
 @return Wether or not the ordered dictionary contains the single object-key pair in the NSDictionary.*/
- (BOOL)containsEntry:(NSDictionary *)entry;

/**The number of entries in the orderedDictionary
 @return The number of entries in the orderedDictionary.*/
- (NSUInteger)count;

/**The object with the highest index value.
 @return The object with the highest index value.*/
- (id)lastObject;
/**The key with the highest index value.
 @return The key with the highest index value.*/
- (id<NSCopying>)lastKey;
/**Returns the object key pair with the highest index value.
 @return The object key pair with the highest index value.*/
- (NSDictionary *)lastEntry;

/**The object located at the given index.
 @param index The index to retreive the object from.
 @return The object located at the given index.*/
- (id)objectAtIndex:(NSUInteger)index;
/**The key located at the given index.
 @param index The index to retreive the key from.
 @return The key located at the given index.*/
- (id<NSCopying>)keyAtIndex:(NSUInteger)index;
/**The entry located at the given index.
 @param index The index to retreive the entry from.
 @return The entry located at the given index.*/
- (NSDictionary *)entryAtIndex:(NSUInteger)index;

/**The array containing the objects at the given index set.
 @param indices The indices to retreive the objects from.
 @return The array containing the objects at the given index set.*/
- (NSArray *)objectsAtIndices:(NSIndexSet *)indeces;
/**The array containing the keys at the given index set.
 @param indices The indices to retreive the keys from.
 @return The array containing the keys at the given index set.*/
- (NSArray *)keysAtIndices:(NSIndexSet *)indices;
/**The array containing the entries at the given index set.
 @param indices The indices to retreive the entries from.
 @return The array containing the entries at the given index set.*/
- (M13OrderedDictionary *)entriesAtIndices:(NSIndexSet *)indices;
/**The dictionary containing the entries at the given index set.
 @param indices The indices to retreive the entries from.
 @return The dictionary containing the entries at the given index set.*/
- (NSDictionary *)unorderedEntriesAtIndices:(NSIndexSet *)indices;

/**The ordered array of all keys in the ordered dictionary.
 @return The ordered array of all keys in the ordered dictionary.*/
- (NSArray *)allKeys;
/**The ordered array of all objects in the ordered dictionary.
 @return The ordered array of all objects in the ordered dictionary.*/
- (NSArray *)allObjects;
/**The array containing the keys corresponding to all occurrences of a given object in the ordered dictionary.
 @param anObject The object to check for.
 @return The array containing the keys corresponding to all occurrences of a given object in the ordered dictionary.*/
- (NSArray *)allKeysForObject:(id)anObject;
/**The value associated with a given key.
 @param The key to get the object for.
 @return he value associated with the given key.*/
- (id)objectForKey:(id<NSCopying>)key;
/**The set of objects from the orderedDictionary that corresponds to the specified keys as an NSArray.
 @param keys The keys to retreive the objects for.
 @param anObject The object to act as NSNotFound. It is placed in the array if the key is not found to maintain order.
 @return The set of objects from the orderedDictionary that corresponds to the specified keys.*/
- (NSArray *)objectForKeys:(NSArray *)keys notFoundMarker:(id)anObject;

/**@name Enumeration*/
/** The enumerator that lets you access each object in the ordered dictionary.
 @return The enumerator that lets you access each object in the ordered dictionary.*/
- (NSEnumerator *)objectEnumerator;
/** The enumerator that lets you access each key in the ordered dictionary.
 @return The enumerator that lets you access each key in the ordered dictionary.*/
- (NSEnumerator *)keyEnumerator;
/** The enumerator that lets you access each entry in the ordered dictionary.
 @return The enumerator that lets you access each entry in the ordered dictionary.
 @note The enumerator goes through an ordered array of dictionarys with one key-value pair.*/
- (NSEnumerator *)entryEnumerator;
/** The enumerator that lets you access each object in the ordered dictionary in reverse.
 @return The enumerator that lets you access each object in the ordered dictionary in reverse.*/
- (NSEnumerator *)reverseObjectEnumerator;
/** The enumerator that lets you access each key in the ordered dictionary in reverse.
 @return The enumerator that lets you access each key in the ordered dictionary in reverse.*/
- (NSEnumerator *)reverseKeyEnumerator;
/** The enumerator that lets you access each entry in the ordered dictionary in reverse.
 @return The enumerator that lets you access each entry in the ordered dictionary in reverse.
 @note The enumerator goes through an ordered array of dictionarys with one key-value pair.*/
- (NSEnumerator *)reverseEntryEnumerator;

/**@name Searching*/
/**The lowest index whose object is equal to the given object.
 @param object The object to search for.
 @return The index of said object.*/
- (NSUInteger)indexOfObject:(id)object;
/**The lowest index whose key is equal to the given key.
 @param key The key to search for.
 @return The index of said key.*/
- (NSUInteger)indexOfKey:(id<NSCopying>)key;
/**The lowest index of the entry where the object and key are equal to the given object and key.
 @param object The object to search for.
 @param key The key to search for.
 @return The index of said entry.*/
- (NSUInteger)indexOfEntryWithObject:(id)object pairedWithKey:(id<NSCopying>)key;
/**The lowest index of the entry where the object and key are equal to the given object and key.
 @param entry The single object-key pair to search for.
 @return The index of said entry.*/
- (NSUInteger)indexOfEntry:(NSDictionary *)entry;

/**The lowest index whose object is equal to the given object in the specified range.
 @param object The object to search for.
 @param range The range to search over.
 @return The index of said object.*/
- (NSUInteger)indexOfObject:(id)object inRange:(NSRange)range;
/**The lowest index whose key is equal to the given key in the specified range.
 @param key The key to search for.
 @param range The range to search over.
 @return The index of said key.*/
- (NSUInteger)indexOfKey:(id<NSCopying>)key inRange:(NSRange)range;
/**The lowest index of the entry where the object and key are equal to the given object and key in the specified range.
 @param object The object to search for.
 @param key The key to search for.
 @param range The range to search over.
 @return The index of said entry.*/
- (NSUInteger)indexOfEntryWithObject:(id)object pairedWithKey:(id<NSCopying>)key inRange:(NSRange)range;
/**The lowest index of the entry where the object and key are equal to the given object and key in the specified range.
 @param entry The single object-key pair to search for.
 @param range The range to search over.
 @return The index of said entry.*/
- (NSUInteger)indexOfEntry:(NSDictionary *)entry inRange:(NSRange)range;

/**The lowest index whose corresponding object value is identical to a given object. (If their memory addresses are the same).
 @param object The object to check for.
 @return The index of the object.*/
- (NSUInteger)indexOfObjectIdenticalTo:(id)object;
/**The lowest index whose corresponding key value is identical to a given object. (If their memory addresses are the same).
 @param object The key to check for.
 @return The index of the key.*/
- (id<NSCopying>)keyOfObjectIdenticalTo:(id)object;

/**The lowest index whose corresponding object value is identical to a given object in the specified range. (If their memory addresses are the same).
 @param object The object to check for.
 @param range The range to search for.
 @return The index of the object.*/
- (NSUInteger)indexOfObjectIdenticalTo:(id)object inRange:(NSRange)range;
/**The lowest index whose corresponding key value is identical to a given object in the given range. (If their memory addresses are the same).
 @param object The key to check for.
 @param range The range to search over.
 @return The index of the key.*/
- (id<NSCopying>)keyOfObjectIdenticalTo:(id)object inRange:(NSRange)range;

/**The index of the first object in the orderedDictionary that passes the test in the given block.
 @param predicate The block that tests the objects.
 @return The index of the first passing object.*/
- (NSUInteger)indexOfObjectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
/**The first key in the orderedDictionary that passes the test in the given block.
 @param predicate The block that tests the objects.
 @return The key of the first passing object.*/
- (id<NSCopying>)keyOfObjectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
/**The index of an object in the orderedDictionary that passes a test in a given Block for a given set of enumeration options.
 @param opts The enumerating options.
 @param predicate The block that tests the objects.
 @return The index of the first passing object.*/
- (NSUInteger)indexOfObjectWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
/**The key of an object in the orderedDictionary that passes a test in a given Block for a given set of enumeration options.
 @param opts The enumerating options.
 @param predicate The block that tests the objects.
 @return The key of the first passing object.*/
- (id<NSCopying>)keyOfObjectWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

/**The index, from a given set of indices, of the first object in the orderedDictionary that passes a test in a given Block for a given set of enumeration options.
 @param indexSet The set of indices to search over.
 @param opts The enumerating options.
 @param predicate The block that tests the objects.
 @return The index of the first passing object.*/
- (NSUInteger)indexOfObjectAtIndices:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
/**The key, from a given set of indices, of the first object in the orderedDictionary that passes a test in a given Block for a given set of enumeration options.
 @param indexSet The set of indices to search over.
 @param opts The enumerating options.
 @param predicate The block that tests the objects.
 @return The key of the first passing object.*/
- (id<NSCopying>)keyOfObjectAtIndices:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

/**The index, within a specified range, of an object compared with elements in the orderedDictionary using a given NSComparator block.
 @param object The object to searh for.
 @param r The range to searh for.
 @param opts The binary searching options.
 @param cmp The comparator to use for searching.
 @return The index of the first passing object.*/
- (NSUInteger)indexOfObject:(id)object inSortedRange:(NSRange)r options:(NSBinarySearchingOptions)opts usingComparator:(NSComparator)cmp;
/**The key, within a specified range, of an object compared with elements in the orderedDictionary using a given NSComparator block.
 @param object The object to searh for.
 @param r The range to searh for.
 @param opts The binary searching options.
 @param cmp The comparator to use for searching.
 @return The key of the first passing object.*/
- (id<NSCopying>)keyOfObject:(id)object inSortedRange:(NSRange)r options:(NSBinarySearchingOptions)opts usingComparator:(NSComparator)cmp;

/**The indices of objects in the orderedDictionary that pass a test in a given block.
 @param predicate The block that tests the objects.
 @return The indices of the passing objects.*/
- (NSIndexSet *)indicesOfObjectsPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
/**The keys of objects in the orderedDictionary that pass a test in a given block.
 @param predicate The block that tests the objects.
 @return The indices of the passing keys.*/
- (NSArray *)keysOfObjectsPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

/**The indices of objects in the orderedDictionary that pass a test in a given Block for a given set of enumeration options.
 @param opts The enumerating options.
 @param predicate The block that tests the objects.
 @return The indices of the passing objects.*/
- (NSIndexSet *)indicesOfObjectsWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
/**The keys of objects in the orderedDictionary that pass a test in a given Block for a given set of enumeration options.
 @param opts The enumerating options.
 @param predicate The block that tests the objects.
 @return The keys of the passing objects.*/
- (NSArray *)keysOfObjectsWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

/**The indices, from a given set of indices, of objects in the objectDictionary that pass a test in a given Block for a given set of enumeration options.
 @param indexSet The indices to search over.
 @param opts The enumerating options.
 @param predicate The block that tests the objects.
 @return The indices of the passing objects.*/
- (NSIndexSet *)indicesOfObjectsAtIndices:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
/**The keys, from a given set of indices, of objects in the objectDictionary that pass a test in a given Block for a given set of enumeration options.
 @param indexSet The indices to search over.
 @param opts The enumerating options.
 @param predicate The block that tests the objects.
 @return The keys of the passing objects.*/
- (NSArray *)keysOfObjectsAtIndices:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

/**@name Preforming Selectors*/
/**Sends to each object in the orderedDictionary the message identified by a given selector, starting with the first object and continuing through the array to the last object.
 @param aSelector The selector to make the objects perform.*/
- (void)makeObjectsPreformSelector:(SEL)aSelector;

/**Sends the aSelector message to each object in the orderedDictionary, starting with the first object and continuing through the array to the last object.
 @param aSelector The selector to perform.
 @param anObject The object to send.*/
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject;

/**Executes a given block using each object in the orderedDictionary, starting with the first object and continuing through the orderedDictionary to the last object. <NSArray> <NSDictionary>
 @param block The block to perform on each object.*/
- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;

/**Executes a given block using each object in the orderedDictionary.
 @param opts The enumerating options.
 @param block The block to perform on each object.*/
- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;

/**Executes a given block using the objects in the orderedDictionary at the specified indices.
 @param indexSet The indices to enumerate over.
 @param opts The enumerating options.
 @param block The block to perform on each object.*/
- (void)enumerateObjectsAtIndices:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;

/**@name Comparing*/
/**Returns the first object contained in the receiving orderedDictionary that’s equal to an object in the given ordered dictionary.
 @param orderedDictionary The orderedDictionary to compare to.
 @return The first object contained in the receiving orderedDictionary that’s equal to an object in the given ordered dictionary.*/
- (id)firstObjectInCommonWithOrderedDictionary:(M13OrderedDictionary *)otherOrderedDictionary;
/**Returns the first key contained in the receiving orderedDictionary that’s equal to a key in the given ordered dictionary.
 @param orderedDictionary The orderedDictionary to compare to.
 @return The first key contained in the receiving orderedDictionary that’s equal to a key in the given ordered dictionary.*/
- (id)firstKeyInCommonWithOrderedDictionary:(M13OrderedDictionary *)otherOrderedDictionary;
/**Returns the first entry contained in the receiving orderedDictionary that’s equal to an entry in the given ordered dictionary.
 @param orderedDictionary The orderedDictionary to compare to.
 @return The first entry contained in the receiving orderedDictionary that’s equal to an entry in the given ordered dictionary.*/
- (id)firstEntryInCommonWithOrderedDictionary:(M13OrderedDictionary *)otherOrderedDictionary;

/**Returns wether or not two ordered dictionaries are equal. Two orderedDictionarys have equal contents if they each hold the same number of objects and objects and keys at a given index in each array satisfy the isEqual: test.
 @param otherOrderedDictionary The ordered dictionary to compare to.
 @return Wether or not the two ordered dictionaries are equal.*/
- (BOOL)isEqualToOrderedDictionary:(M13OrderedDictionary *)otherOrderedDictionary;

/**@name Deriving*/
/**Duplicate the ordered dictionary and add an entry to it.
 @param object The object to add.
 @param aKey The key for the given object.
 @return A new M13OrderedDictionary containing all the entries in the receiver plus the given entry.*/
- (M13OrderedDictionary *)orderedDictionaryByAddingObject:(id)object pairedWithKey:(id<NSCopying>)aKey;
/**Duplicate the ordered dictionary and add an entry to it.
 @param entry The entry to add.
 @return A new M13OrderedDictionary containing all the entries in the receiver plus the given entry.*/
- (M13OrderedDictionary *)orderedDictionaryByAddingEntry:(NSDictionary *)entry;
/**Duplicate the ordered dictionary and add an entries to it.
 @param orderedObjects The array of objects to add to the ordered dictionary.
 @param orderedKeys The array of keys that correspond to the given objects.
 @return A new M13OrderedDictionary containing all the entries in the receiver plus the given entries.*/
- (M13OrderedDictionary *)orderedDictionaryByAddingObjects:(NSArray *)orderedObjects pairedWithKeys:(NSArray *)orderedKeys;

/**Evaluates a given predicate against each object in the receiving orderedDictionary and returns a new orderedDictionary containing the objects for which the predicate returns true.
 @param predicate The predicate that tests each entry.
 @return A new orderedDictionary containing the objects for which the predicate returns true*/
- (M13OrderedDictionary *)filteredOrderDictionarysUsingPredicateForObjects:(NSPredicate *)predicate;
/**Returns a new orderedDictionary containing the receiving orderedDictionary's elements that fall within the limits specified by a given range.
 @param range The range to retreive entries from.
 @return The receiving orderedDictionary's elements that fall within the limits specified by the given range.*/
- (M13OrderedDictionary *)subOrderedDictionaryWithRange:(NSRange)range;

/**@name Sorting*/
/**Analyzes the ordered Dictionary and returns a hint that speeds the sorting of the objects when the hint is supplied to sorted______UsingFunction:context:hint:.
 @return A hint that speeds the sorting of the objects when the hint is supplied to sorted______UsingFunction:context:hint:.*/
- (NSData *)sortedObjectsHint;
/**Analyzes the ordered Dictionary and returns a hint that speeds the sorting of the keys when the hint is supplied to sorted______UsingFunction:context:hint:.
 @return A hint that speeds the sorting of the keys when the hint is supplied to sorted______UsingFunction:context:hint:.*/
- (NSData *)sortedKeysHint;

/**Returns a new orderedDictionary that lists the receiving orderedDictionary objects in ascending order as defined by the comparison function comparator.
 @param comparator The comparator to perform the sorting operation with.
 @param context The context to sort the objects in.
 @return  A new orderedDictionary that lists the receiving orderedDictionary objects in ascending order as defined by the comparison function comparator.*/
- (M13OrderedDictionary *)sortedByObjectsUsingFunction:(NSInteger (*)(id, id, void *))comparator context:(void *)context;
/**Returns a new orderedDictionary that lists the receiving orderedDictionary keys in ascending order as defined by the comparison function comparator.
 @param comparator The comparator to perform the sorting operation with.
 @param context The context to sort the objects in.
 @return  A new orderedDictionary that lists the receiving orderedDictionary keys in ascending order as defined by the comparison function comparator.*/
- (M13OrderedDictionary *)sortedByKeysUsingFunction:(NSInteger (*)(id<NSCopying>, id<NSCopying>, void *))comparator context:(void *)context;

/**Returns a new orderedDictionary that lists the receiving orderedDictionary objects in ascending order as defined by the comparison function comparator.
 @param comparator The comparator to perform the sorting operation with.
 @param context The context to sort the objects in.
 @param hit The sorting hint to speed sorting.
 @return  A new orderedDictionary that lists the receiving orderedDictionary objects in ascending order as defined by the comparison function comparator.*/
- (M13OrderedDictionary *)sortedByObjectsUsingFunction:(NSInteger (*)(id, id, void *))comparator context:(void *)context hint:(NSData *)hint;
/**Returns a new orderedDictionary that lists the receiving orderedDictionary keys in ascending order as defined by the comparison function comparator.
 @param comparator The comparator to perform the sorting operation with.
 @param context The context to sort the objects in.
 @param hit The sorting hint to speed sorting.
 @return  A new orderedDictionary that lists the receiving orderedDictionary keys in ascending order as defined by the comparison function comparator.*/
- (M13OrderedDictionary *)sortedByKeysUsingFunction:(NSInteger (*)(id<NSCopying>, id<NSCopying>, void *))comparator context:(void *)context hint:(NSData *)hint;

/**Returns a copy of the receiving orderedDicitionary's objects sorted as specified by a given array of sort descriptors.
 @param descriptors The NSSortDescriptors to sort with.
 @return A copy of the receiving orderedDicitionary's objects sorted as specified by a given array of sort descriptors.*/
- (M13OrderedDictionary *)sortedByObjectsUsingDescriptors:(NSArray *)descriptors;
/**Returns a copy of the receiving orderedDicitionary's keys sorted as specified by a given array of sort descriptors.
 @param descriptors The NSSortDescriptors to sort with.
 @return A copy of the receiving orderedDicitionary's keys sorted as specified by a given array of sort descriptors.*/
- (M13OrderedDictionary *)sortedByKeysUsingDescriptors:(NSArray *)descriptors;

/**Returns an orderedDictionary that lists the receiving orderedDictionary's objects in ascending order, as determined by the comparison method specified by a given selector.
 @param comparator The comparator to sort with.
 @return An orderedDictionary that lists the receiving orderedDictionary's objects in ascending order, as determined by the comparison method specified by a given selector.*/
- (M13OrderedDictionary *)sortedByObjectsUsingSelector:(SEL)comparator;
/**Returns an orderedDictionary that lists the receiving orderedDictionary's keys in ascending order, as determined by the comparison method specified by a given selector.
 @param comparator The comparator to sort with.
 @return An orderedDictionary that lists the receiving orderedDictionary's keys in ascending order, as determined by the comparison method specified by a given selector.*/
- (M13OrderedDictionary *)sortedByKeysUsingSelector:(SEL)comparator;

/**Returns an orderedDictionary that lists the receiving orderedDictionary's objects in ascending order, as determined by the comparison method specified by a given NSComparator Block.
 @param cmptr The comparator to sort with.
 @return An orderedDictionary that lists the receiving orderedDictionary's objects in ascending order, as determined by the comparison method specified by a given NSComparator Block.*/
- (M13OrderedDictionary *)sortedByObjectsUsingComparator:(NSComparator)cmptr;
/**Returns an orderedDictionary that lists the receiving orderedDictionary's keys in ascending order, as determined by the comparison method specified by a given NSComparator Block.
 @param cmptr The comparator to sort with.
 @return An orderedDictionary that lists the receiving orderedDictionary's keys in ascending order, as determined by the comparison method specified by a given NSComparator Block.*/
- (M13OrderedDictionary *)sortedByKeysUsingComparator:(NSComparator)cmptr;

/**Returns an orderedDictionary that lists the receiving orderedDictionary's objects in ascending order, as determined by the comparison method specified by a given NSComparator Block.
 @param opts The sorting options.
 @param cmptr The comparator to sort with.
 @return An orderedDictionary that lists the receiving orderedDictionary's objects in ascending order, as determined by the comparison method specified by a given NSComparator Block.*/
- (M13OrderedDictionary *)sortedByObjectsWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr;
/**Returns an orderedDictionary that lists the receiving orderedDictionary's keys in ascending order, as determined by the comparison method specified by a given NSComparator Block.
 @param opts The sorting options.
 @param cmptr The comparator to sort with.
 @return An orderedDictionary that lists the receiving orderedDictionary's keys in ascending order, as determined by the comparison method specified by a given NSComparator Block.*/
- (M13OrderedDictionary *)sortedByKeysWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr;


/**@name Descriptions*/
/**Returns the contents formatted as a property list.
 @return The contents formatted as a property list.*/
- (NSString *)description;
/**Returns the contents formatted as a property list.
 @param locale The local to format the property list with.
 @return The contents formatted as a property list.*/
- (NSString *)descriptionWithLocale:(id)locale;
/**Returns the contents formatted as a property list.
 @param locale The local to format the property list with.
 @param indent The indentation level of the property list.
 @return The contents formatted as a property list.*/
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level;
/**Writes contents to file at a given path.
 @param path The path to write the file to.
 @param flag Wether or not to write atimically.*/
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag;
/**Writes contents to file at a given URL.
 @param aURL The URL to write the file to.
 @param flag Wether or not to write atimically.*/
- (BOOL)writeToURL:(NSURL *)aURL atomically:(BOOL)flag;

/**@name Key Value Observing*/
/**Registers an observer to receive key value observer notifications for the specified key-path relative to the objects at the indices.
 @param anObserver The KVO Observer.
 @param indices The indices to receive notifications for.
 @param keyPath The key path to receive notifications for.
 @param options The observing options.
 @param context The observing context.*/
- (void)addObserver:(NSObject *)anObserver toObjectsAtIndices:(NSIndexSet *)indices forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
/**Registers an observer to receive key value observer notifications for the specified key-path relative to the objects at the first key value.
 @param anObserver The KVO Observer.
 @param keyPath The key path to receive notifications for.
 @param options The observing options.
 @param context The observing context.*/
- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
/**Removes anObserver from all key value observer notifications associated with the specified keyPath relative to the array’s objects at indices.
 @param anObserver The KVO Observer.
 @param indices The indices to remove notifications for.
 @param keyPath The key path to remove notifications for.*/
- (void)removeObserver:(NSObject *)anObserver fromObjectsAtIndices:(NSIndexSet *)indices forKeyPath:(NSString *)keyPath;
/**Removes an observer to receive key value observer notifications for the specified key-path relative to the objects at the first key value.
 @param anObserver The KVO Observer.
 @param keyPath The key path to remove notifications for.
 @param context The observing context.*/
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context;
/**Invokes setValue:forKey: on each of the orderedDictionary's entries using the specified value and key. 
 @param value The value to set.
 @param key The key to set the value of.*/
- (void)setValue:(id)value forKey:(NSString *)key;
/**Sets a value to the object whos key is the first key in the key path.
 @param value The value to set.
 @param keyPath The path of the key to set.*/
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath;
/**Returns an NSArray containing the results of invoking valueForKey: using key on each of the array's objects.
 @param key The key to retreive the object of.
 @return An NSArray containing the results of invoking valueForKey: using key on each of the array's objects.*/
- (id)valueForKey:(NSString *)key;
/**Returns a value to the object whos key is the first key in the key path.
 @param keyPath The path of the key to retreive the value for.
 @return A value to the object whos key is the first key in the key path.*/
- (id)valueForKeyPath:(NSString *)keyPath;

/**@name NSCoding*/
/**Encode the ordered dictionary with the given coder.
 @param aCoder The coder to encode the ordered dictionary with.*/
- (void)encodeWithCoder:(NSCoder *)aCoder;
/**Initalize the ordered dictionary with a decoder.
 @param decoder The decoder to initalize the ordered dictionary with.
 @return A M13OrderedDictionary.*/
- (id)initWithCoder:(NSCoder *)decoder;

/**@name NSCopying*/
/**Returns a copy of the ordered dictionary.
 @return A copy of the ordered dictionary.*/
- (id)copy;
/**Returns a copy of the ordered dictionary.
 @param The zone to copy with.
 @return A copy of the ordered dictionary.*/
- (id)copyWithZone:(NSZone *)zone;
/**Returns a mutable copy of the ordered dictionary.
 @return A copy of the ordered dictionary.*/
- (id)mutableCopy;
/**Returns a mutable copy of the ordered dictionary.
 @param The zone to copy with.
 @return A copy of the ordered dictionary.*/
- (id)mutableCopyWithZone:(NSZone *)zone;

/************ NSFastEnumeration ************/
//Cannot figure out how to implement this, in this way without incuring excessive overhead by creating the array of dictionarys each time. Not sure where to put code to create array on the first run, and delete on the last run.
//- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len; //Will only produce NSDictionarys with single object-key pairs. If you need to iterate over only the objects and keys, use "allKeys" and "allObjects".

/**@name Indexed Subscripts*/
/**Returns the object at the given indexed subscript.
 @param index The indexed subscript.
 @return The object at the given indexed subscript.*/
- (id)objectAtIndexedSubscript:(NSUInteger)index;
/**Returns the object for the given keyed subscript.
 @param key The keyed subscript.
 @return The object at the given keyed subscript.*/
- (id)objectForKeyedSubscript:(id)key;

@end

/**A mutable version of M13OrderedDictionary*/
@interface M13MutableOrderedDictionary : M13OrderedDictionary

/**@name Creation and Initalization*/
/**Create the mutable ordered dictionary with the given capacity.
 @param The capacity of the ordered dictionary.
 @return A M13MutableOrderedDictionary object.*/
+ (instancetype)orderedDictionaryWithCapacity:(NSUInteger)numEntries;
/**Initalize the mutable ordered dictionary with the given capacity.
 @param The capacity of the ordered dictionary.
 @return A M13MutableOrderedDictionary object.*/
- (id)initWithCapacity:(NSUInteger)numEntries;

/**@name Adding Objects*/
/**Add the entry at the end of the orderedDictionary. If the key exists, its entry will be deleted, before the entry is added.
 @param object The object to add.
 @param key The key for the given object.*/
- (void)addObject:(id)object pairedWithKey:(id<NSCopying>)key;
/**Add the entry at the end of the orderedDictionary. If the key exists, its entry will be deleted, before the entry is added.
 @param entry The entry to add.*/
- (void)addEntry:(NSDictionary *)entry;
/**Add the entries at the end of the orderedDictionary. If a key exists, its entry will be deleted, before the entry is added.
 @param orderedDictionary The orderedDictionary of entries to add.*/
- (void)addEntriesFromOrderedDictionary:(M13OrderedDictionary *)orderedDictionary;
/**Add the entries at the end of the orderedDictionary. If a key exists, its entry will be deleted, before the entry is added.
 @param dictionary The dictionary of entries to add.*/
- (void)addEntriesFromDictionary:(NSDictionary *)dictionary;

/**Insert the entry at the specific index. If the key exists, its entry will be deleted, before the entry is inserted; also, the insertion compensates for the deleted key, so the entry will end up between the same to indices regardless if a key is deleted or not.
 @param object The object to add.
 @param key The key for the given object.
 @param index The index to place the given object*/
- (void)insertObject:(id)object pairedWithKey:(id<NSCopying>)key atIndex:(NSUInteger)index;
/**Insert the entry at the specific index. If the key exists, its entry will be deleted, before the entry is inserted; also, the insertion compensates for the deleted key, so the entry will end up between the same to indices regardless if a key is deleted or not.
 @param entry The entry to add.
 @param index The index to place the given entry*/
- (void)insertEntry:(NSDictionary *)entry atIndex:(NSUInteger)index;
/**Insert the entries from the given ordered dictionary at the specific index. If a key exists, its entry will be deleted, before the entry is inserted; also, the insertion compensates for the deleted key, so the entry will end up between the same to indices regardless if a key is deleted or not.
 @param orderedDictionary The entries to add.
 @param index The index to place the given entries*/
- (void)insertEntriesFromOrderedDictionary:(M13OrderedDictionary *)orderedDictionary atIndex:(NSUInteger)index;
/**Insert the entries from the given dictionary at the specific index. If a key exists, its entry will be deleted, before the entry is inserted; also, the insertion compensates for the deleted key, so the entry will end up between the same to indices regardless if a key is deleted or not.
 @param dictionary The entries to add.
 @param index The index to place the given entries*/
- (void)insertEntriesFromDictionary:(NSDictionary *)dictionary atIndex:(NSUInteger)index;

/**If a key exists this will overrite the object for said key, not changing the order of keys. If the key does not exist, it will be appended at the end of the ordered dictionary.
 @param object The object to add.
 @param aKey The key for the given object.*/
- (void)setObject:(id)object forKey:(id<NSCopying>)aKey;
/**If a key exists this will overrite the object for said key, not changing the order of keys. If the key does not exist, it will be appended at the end of the ordered dictionary.
 @param entry The entry to add.*/
- (void)setEntry:(NSDictionary *)entry;
/**If a key exists this will overrite the object for said key, not changing the order of keys. If the key does not exist, it will be appended at the end of the ordered dictionary.
 @param orderedDictionary The entries to add.*/
- (void)setEntriesFromOrderedDictionary:(M13OrderedDictionary *)orderedDictionary;
/**If a key exists this will overrite the object for said key, not changing the order of keys. If the key does not exist, it will be appended at the end of the ordered dictionary.
 @param dictionary The entries to add.*/
- (void)setEntriesFromDictionary:(NSDictionary *)dictionary;

/**If a key exists will overrite the object for said key, not changing the order of keys. if the key does not exist, the entry will be inserted at the specified index.
 @param object The object to add.
 @param key The key to change the object for.
 @param index The index to insert the object if the key does not exist.*/
- (void)setObject:(id)object forKey:(id<NSCopying>)aKey atIndex:(NSUInteger)index;
/**If a key exists will overrite the object for said key, not changing the order of keys. if the key does not exist, the entry will be inserted at the specified index.
 @param object The entry to add.
 @param index The index to insert the entry if the key does not exist.*/
- (void)setEntry:(NSDictionary *)entry  atIndex:(NSUInteger)index;
/**If a key exists will overrite the object for said key, not changing the order of keys. if the key does not exist, the entry will be inserted at the specified index.
 @param orderedDictionary The entries to add.
 @param index The index to insert the entryies if the key for an entry does not exist.*/
- (void)setEntriesFromOrderedDictionary:(M13OrderedDictionary *)orderedDictionary atIndex:(NSUInteger)index;
/**If a key exists will overrite the object for said key, not changing the order of keys. if the key does not exist, the entry will be inserted at the specified index.
 @param dictionary The entries to add.
 @param index The index to insert the entries if the key for an entry does not exist.*/
- (void)setEntriesFromDictionary:(NSDictionary *)dictionary  atIndex:(NSUInteger)index;



/**@name Removing Objects*/

/** Removes the entry for the given key.
 @param key The key for the entry to remove.*/
- (void)removeObjectForKey:(id)key;
/** Removes the entries for the given keys.
 @param key The keys for the entries to remove.*/
- (void)removeObjectsForKeys:(NSArray *)keys;
/** Removes all the entries in the ordered dictionary.*/
- (void)removeAllObjects;

/** Removes all the entries in the ordered dictionary.*/
- (void)removeAllEntries;
/** Removes the last entry in the ordered dictionary.*/
- (void)removeLastEntry;

/**Removes the entry with the given object.
 @param object The object to search for.*/
- (void)removeEntryWithObject:(id)object;
/**Removes the entry with the given key.
 @param key The key to search for.*/
- (void)removeEntryWithKey:(id<NSCopying>)key;
/**Removes the given entry
 @param object The object to search for.
 @param key The key to search for.*/
- (void)removeEntryWithObject:(id)object pairedWithKey:(id<NSCopying>)key;
/**Removes the given entry
 @param entry The entry to search for.*/
- (void)removeEntry:(NSDictionary *)entry;


/**Removes the entry with the given object.
 @param object The object to search for.
 @param range The range to search over.*/
- (void)removeEntryWithObject:(id)object inRange:(NSRange)range;
/**Removes the entry with the given key.
 @param key The key to search for.
 @param range The range to search over.*/
- (void)removeEntryWithKey:(id<NSCopying>)key inRange:(NSRange)range;
/**Removes the given entry
 @param object The object to search for.
 @param key The key to search for.
 @param range The range to search over.*/
- (void)removeEntryWithObject:(id)object pairedWithKey:(id<NSCopying>)key inRange:(NSRange)ramge;
/**Removes the given entry
 @param entry The entry to search for.
 @param range The range to search over.*/
- (void)removeEntry:(NSDictionary *)entry inRange:(NSRange)range;

/**Remove the entry at the given index.
 @param index The index to remove.*/
- (void)removeEntryAtIndex:(NSUInteger)index;
/**Remove the entry at the given indices.
 @param indices The indices to remove.*/
- (void)removeEntriesAtIndices:(NSIndexSet *)indices;

/**Remove the entry with the given object. Object is found by memory address.
 @param anObject The object in the entry to remove.*/
- (void)removeEntryWithObjectIdenticalTo:(id)anObject;
/**Remove the entry with the given object. Object is found by memory address.
 @param anObject The object in the entry to remove.
 @param range The range to search over.*/
- (void)removeEntryWithObjectIdenticalTo:(id)anObject inRange:(NSRange)range;

/**Remove the entries containing the objects in the given array.
 @param array Array of objects to search for.*/
- (void)removeEntriesWithObjectsInArray:(NSArray *)array;
/**Remove the entries containing the keys in the given array.
 @param array Array of keys to search for.*/
- (void)removeEntriesWithKeysInArray:(NSArray *)array;
/**Remove the entries in the given range.
 @param range The range of objects to remove.*/
- (void)removeEntriesInRange:(NSRange)range;

/**@name Replacing Objects*/
/**Replace the entry at the given index with the given entry.
 @param index The index to replace.
 @param object The object of the new entry.
 @param key The key of the new entry.*/
- (void)replaceEntryAtIndex:(NSInteger)index withObject:(id)object pairedWithKey:(id<NSCopying>)key;
/**Replace the entry at the given index with the given entry.
 @param index The index to replace.
 @param entry The entry to insert.*/
- (void)replaceEntryAtIndex:(NSUInteger)index withEntry:(NSDictionary *)entry;
/**Replace the entries at the given indices with the given entries.
 @param indices The indices to replace.
 @param objects The objects of the new entries.
 @param keys The keys of the new entries.
 @note The number of indices, objects, and keys needs to be equal.*/
- (void)replaceEntriesAtIndices:(NSIndexSet *)indices withObjects:(NSArray *)objects pairedWithKeys:(NSArray *)keys;
/**Replace the entries at the given indices with the given entries.
 @param indices The indices to replace.
 @param orderedEntries An ordered array with NSDictionarys with a single object-key pair as entries.*/
- (void)replaceEntriesAtIndices:(NSIndexSet *)indices withEntries:(NSArray *)orderedEntries;
/**Replace the entries at the given indices with the given entries.
 @param indices The indices to replace.
 @param orderedDictionary The entries to insert.*/
- (void)replaceEntriesAtIndices:(NSIndexSet *)indices withEntriesFromOrderedDictionary:(M13OrderedDictionary *)orderedDictionary;

/**Replace the entries in the given range with the given entries in the given range.
 @param range The range of objects to be replaced.
 @param objects The objects of the new entries.
 @param keys The keys of the new entries.
 @param range2 The range of the objects to insert.
 @note The number of indices, objects, and keys needs to be equal.*/
- (void)replaceEntriesInRange:(NSRange)range withObjectsFromArray:(NSArray *)objects pairedWithKeysFromArray:(NSArray *)keys inRange:(NSRange)range2;
/**Replace the entries in the given range with the given entries in the given range.
 @param range The range of objects to be replaced.
 @param orderedEntries An ordered array with NSDictionarys with a single object-key pair as entries.
 @param range2 The range of the objects to insert.*/
- (void)replaceEntriesInRange:(NSRange)range withEntriesFrom:(NSArray *)orderedEntries inRange:(NSRange)range2;
/**Replace the entries in the given range with the given entries in the given range.
 @param range The range of objects to be replaced.
 @param orderedDictionary The entries to insert.
 @param range2 The range of the objects to insert.*/
- (void)replaceEntriesInRange:(NSRange)range withEntriesFromOrderedDictionary:(M13OrderedDictionary *)dictionary inRange:(NSRange)range2;
/**Replace the entries in the given range with the given entries.
 @param range The range of objects to be replaced.
 @param objects The objects of the new entries.
 @param keys The keys of the new entries.
 @note The number of indices, objects, and keys needs to be equal.*/
- (void)replaceEntriesInRange:(NSRange)range withObjectsFromArray:(NSArray *)objects pairedWithKeysFromArray:(NSArray *)keys;
/**Replace the entries in the given range with the given entries.
 @param range The range of objects to be replaced.
 @param orderedEntries An ordered array with NSDictionarys with a single object-key pair as entries.
 @param range2 The range of the objects to insert.*/
- (void)replaceEntriesInRange:(NSRange)range withEntriesFrom:(NSArray *)orderedEntries;
/**Replace the entries in the given range with the given entries in the given range.
 @param range The range of objects to be replaced.
 @param orderedDictionary The entries to insert.*/
- (void)replaceEntriesInRange:(NSRange)range withEntriesFromOrderedDictionary:(M13OrderedDictionary *)dictionary;
/**Replace the current entries with the given entries. If there are less entries given than in the ordered dictionary, the entries past the count of the given entries will not be replaced.
 @param objects The objects of the new entries.
 @param keys The keys of the new entries.*/
- (void)setEntriesToObjects:(NSArray *)objects pairedWithKeys:(NSArray *)keys;
/**Replace the current entries with the given entries. If there are less entries given than in the ordered dictionary, the entries past the count of the given entries will not be replaced.
 @param orderedDictionary The new entries.*/
- (void)setEntriesToOrderedDictionary:(M13OrderedDictionary *)orderedDictionary;

/**@name Filtering Content*/
/**Filter the ordered dictionary by removing objects that do not pass the predicate.
 @param predicate The predicate filter.*/
- (void)filterEntriesUsingPredicateForObjects:(NSPredicate *)predicate;

/**@name Rearranging Content*/
/**Exchange the entry at the first index with the entry at the second index.
 @param idx1 The index of the first entry.
 @param idx2 The index of the second entry.*/
- (void)exchangeEntryAtIndex:(NSUInteger)idx1 withEntryAtIndex:(NSUInteger)idx2;
/**Sort the entries by their objects using NSSortDescriptors.
 @param descriptors The array of NSSortDescriptors to use when sorting.*/
- (void)sortEntriesByObjectUsingDescriptors:(NSArray *)descriptors;
/**Sort the entries by their keys using NSSortDescriptors.
 @param descriptors The array of NSSortDescriptors to use when sorting.*/
- (void)sortEntriesByKeysUsingDescriptors:(NSArray *)descriptors;

/**Sort the entries by their objects using the given comparator.
 @param cmptr The comparator to use to sort the entries.*/
- (void)sortEntriesByObjectUsingComparator:(NSComparator)cmptr;
/**Sort the entries by their keys using the given comparator.
 @param cmptr The comparator to use to sort the entries.*/
- (void)sortEntriesByKeysUsingComparator:(NSComparator)cmptr;

/**Sort the entries by their objects using the given comparator.
 @param opts The options to use while sorting.
 @param cmptr The comparator to use to sort the entries.*/
- (void)sortEntriesByObjectWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr;
/**Sort the entries by their keys using the given comparator.
 @param opts The options to use while sorting.
 @param cmptr The comparator to use to sort the entries.*/
- (void)sortEntriesByKeysWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr;

/**Sort the entries by their objects using the comparator function.
 @param compare The comparison function.
 @param context The context to sort in.*/
- (void)sortEntriesByObjectUsingFunction:(NSInteger (*)(id, id, void *))compare context:(void *)context;
/**Sort the entries by their keys using the comparator function.
 @param compare The comparison function.
 @param context The context to sort in.*/
- (void)sortEntriesByKeysUsingFunction:(NSInteger (*)(id, id, void *))compare context:(void *)context;

/**Sort the entries by their objects using the given selector.
 @param comparator The selector to use to sort the entries.*/
- (void)sortEntriesByObjectUsingSelector:(SEL)comparator;
/**Sort the entries by their keys using the given selector.
 @param comparator The selector to use to sort the entries.*/
- (void)sortEntriesByKeysUsingSelector:(SEL)comparator;

/************ Indexed Subscripts ************/
/**Set the given object for the given keyed subscript.
 @param object The object to insert.
 @param key The keyed subscript.*/
- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key;

@end
