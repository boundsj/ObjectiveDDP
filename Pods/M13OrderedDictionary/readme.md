<img src="https://raw.github.com/Marxon13/M13OrderedDictionary/master/ReadmeResources/M13OrderedDictionaryBanner.png">

M13OrderedDictionary
============

M13OrderedDictionary is a cross between NSArray and NSDictionary. It holds an ordered list of objects and keys. All of which can be accessed by index, or key. This class is the only fully implemented ordered dictionary class for Objective C. It follows Apple's subclassing protocols for NSArray and NSDictionary. It has methods comparable to all of NSArray's methods and all of NSDictionary's methods. It also supports NSCoding, NSCopying, KVO, and supports NSFastEnumeration over the objects or keys.

Features:
----------

* Setup as easy as setting up a NSArray or NSDictionary.

* Includes methods for:
    * Creation
    * Initialization
    * Accessing Keys and Values
    * Querying
    * Searching
    * Sending Messages 
    * Comparing
    * Deriving
    * Enumerating
    * Sorting
    * Descriptions / Storing
    * Key Value Observing
    * Key Value Coding
    * Indexed Subscripting

Usage:
-------
Just add M13OrderedDictionary.h and M13OrderedDictionary.m to your projects, and start using. Explanations of each method, or set of methods are given in the interface file.

There are three main terms used throughout the methods:

* Entry - A single object-key pair at an index. When passing an entry to a method it is a NSDictionary with a single object-key pair.
* Object - refers to <code>(id)</code>, and has an associated key, and an index shared with that key.
* Key - refers to <code>(id < NSCopying > )</code>, and has an associated object, and an index shared with that object.

Limitations:
------------
The objects and keys are subject to the requirements and limitations of NSArray and NSDictionary; As the objects and keys are stored in a NSArray, as well as an NSDictionary. Mainly, nil cannot be passed as an object or a key since you cannot store nil in a NSArray. So, removing an object needs to be doe with the NSArray method <code>remove*:</code> instead of the NSDictionary method <code>setValue:nil forKey:someKey</code>

Index subscripting will only retrieve an object at an index, retrieve an object for a key, and set an object for a key.

Notes:
----------
If something is not working, or does not work as expected when compared to Apples's docs. let me know, I'll get it fixed ASAP.

License:
---------
> Copyright 2013 Brandon McQuilkin 
>
>Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

>The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
