import UIKit

//JSON -> It's not Jason Ruan
//Javascript Object Notation.

// what is the purpose of JSON in our apps
// Get data from APIs, or from other sources -> we transfer data using RESTful transfer in a familiar format
// What's REST -> Representational State Transfer.
// Data objects are unintelligible to us (unless we know how to read bytes) so we'll need to decode them. We typically count on information from the internet coming in JSON. It makes life easier!

// What is actually going on in JSON's format -> series of key/value pairs, where the key is always a string

//Do the key/value pairs have to be Codable? We'll find out today!

//JSON represents some data, and arrives as a dictionary or an array

let dataString = """
{"someKey":"a word encoded to data"}
"""
let data = dataString.data(using: .utf8) ?? Data()

//How in the past have we decoded this data object?
// Use the JsonDecoder method -> we specify the model that we've defined
//say that "the decoder should try to decode some data object given the format defined in that tyoe's definition"


struct BasicObject: Codable {
    //decoding data using this struct's definition (BasicObject.self) will automatically try to find the key in the json called "someKey" and assign its value to this property
    let someKey: String
}
//to use decoder here, my object whose type i'll be using must conform to Codable
//Codable is a typealias for Decodable and Encodable.

//first argument for .decode is called "type".

//what is .self here? it's a property of an object, specifically what kind though?
//.self functions like a static property that provides the type's blueprint
let aBasicObject = try? JSONDecoder().decode(BasicObject.self, from: data)


//The old ways: JSON Serialization

//Before Codable, we couldn't directly look at the blueprint for a specific type (ex: BasicObject.self).

// Instead, we used a process called serialization
// We had to work with JSON in the way that we've been describing it: [String:Any] or [[String:Any]]

// What serialization and Codable have in common is that you have to define how an object will get its values
// If I define objects (create a model), I still have to make explicit which properties I'm going to use from JSON
// We're still turning JSON into a Swift object, but now we have to do the hard work of looking in a dictionary and getting the values for specific keys

// In swift, when we look up a value in a dictionary using a key, what is the return type? Optional!
// To serialize JSON data into a Swift object, we're gonna have to use a whole bunch of downcasting

// We start with [String: Any]
// For each property we want to use, we then have make sure that we're casting the Any value to the type of the property in our object's definition

//Remember Firebase? How did we initialize objects when we looked at a collection in Firebase and tried to turn the data from that collection into Swift stuff?
//Had an init function that looked through a dictionary.


//This struct allows us to init from either a JSONDecoder or a JSONSerializer. In the real world, a struct will likely only need Codable. It was a fun exercise though, wasn't it?
struct BiggerObject: Codable {
    let name: String
    let title: String
    //Underscore indicates that this property should NOT be available outside of the the current scope. It should be private. It shouldn't be exposed to anyone using your classes/structs. It's solely here to be used within this object.
    //Here specifically, we should not allow anyone using an instance of the Greatness object to be able to look at the property someBiggerObject._greatness.
    //We'll look at it to provide the value for a computed property.
    private let _greatness: Greatness

    var greatness: Int {
        return _greatness.value
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, title
        case _greatness = "greatness"
    }
    
    struct Greatness:Codable {
        enum GreatnessError: Error {
            case decodingError
        }
        let value: Int
        init(decoder: Decoder) throws {
            let greatness: Int
            //if it's an int, initialize value
            if let greatnessInt = try? decoder.singleValueContainer().decode(Int.self) {
                greatness = greatnessInt
            } else if let greatnessString = try? decoder.singleValueContainer().decode(String.self), let greatnessInt = Int(greatnessString) {
            //else if it's a string, try to cast it and initialize that value as an int
                greatness = greatnessInt
            } else {
            //else, throw an error :(
                throw GreatnessError.decodingError
            }
            self.value = greatness
        }
        init?(int:Int) {
            self.value = int
        }
    }
    
    //what does this do -> it can initialize an object, but it's allowed fail and return nil
    init?(from dict: [String:Any]) {
        guard let name = dict["name"] as? String else {
            return nil
        }
        let title = dict["title"] as? String

        //what if the key greatness has heterogenous values in the JSON provided by the API?
        //We can handle that! Since looking up keys in dictionaries provides us with optional values, we can downcast repeatedly until we get the value we need. If downcasting to get this value fails, then the entire init will fail.
        if let greatnessInt = dict["greatness"] as? Int, let greatness = Greatness(int: greatnessInt) {
            self._greatness = greatness
        } else if let greatnessString = dict["greatness"] as? String, let greatnessInt = Int(greatnessString), let greatness = Greatness(int: greatnessInt) {
            self._greatness = greatness
        } else {
            return nil
        }

        self.name = name
        //Here, the "title" property will always get a value, regardless of whether the serialized json has a key/value pair for it. This means that we'll never fail to create an instance of BiggerObject just because the JSON data didn't include a value for "title".
        self.title = title ?? "N/A"
    }
}

//this is an array of json objects, so we'll need to get an array of dictionaries to turn into BiggerObjects
let biggerObjectString = """
[{"name":"istishna","greatness":"10"},{"name":"iram","greatness":9},{"name":"tia","greatness":11}, {}, {"name":"something else that won't work"}]
"""

//utf8 -> 8 bits? Why, David? Let me get back to you.
//https://www.quora.com/What-is-UTF8
//Hi it's Jack and I know why- most US/Latin characters are represented in utf8
// example of utf16 - chinese characters. Because they're a composite of many characters in an extended grapheme cluster, they are represented in utf16
//Thanks Jack!

//Let's deserialize
let objectData = biggerObjectString.data(using: .utf8) ?? Data()

//Now we need to go from Any to [[String:Any]]
let serializedJSON = (try? JSONSerialization.jsonObject(with: objectData, options: []) as? [[String:Any]])!

//now let's go from [[String:Any]] to [BiggerObject]
//if we have an array of things, how can we look through each and make sure that we're only keeping the non-nil elements?
// compactMap (it's a map that tries to do some stuff, but gets rid of the nils when that stuff doesnt work)
let biggerObjects = serializedJSON.compactMap { BiggerObject(from: $0) }

//ultimately, we can get access to this computed variable without worrying about the type in the JSON. The heterogenous property is private, so anyone using our code does not have to worry.
biggerObjects.first?.greatness


