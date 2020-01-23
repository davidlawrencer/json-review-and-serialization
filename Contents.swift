
import UIKit
//JSON -> It's not Jason Ruan
//Javascript Object Notation.

// what is the purpose of JSON
// Get data from APIs, or from other sources -> we transfer data using RESTful transfer
// What REST -> Representational State Transfer.
// Data() is unintelligible to us

// What is the format -> series of key/value pairs, where the key is always a string

//Do they have to be Codable? We'll find out today


//stores data - comes as a dictionary or a dictionary


let dataString = """
{"someKey":"a word encoded to data"}
"""
let data = dataString.data(using: .utf8) ?? Data()
//what is utf8 -> a way to encode into/decode out of unicode!

//How in the past have we decoded this data object?
// Use the JsonDecoder method -> we specify the model that we've defined
//say that "the decoder should try to decode some data object given the format defined in that tyoe's definition"


struct BasicObject: Codable {
    //decoding data using this struct's definition (BasicObject.self) will automatically try to find the key in the json called "someKey" and assign its value to this property
    let someKey: String
}
//to use decoder here, my object whose type i'll be using must conform to Codable
//Codable is a typealias for Decodable and Encodable.

//first argument called "type"

//what is .self here? it's a property of an object, specifically what kind though?
//.self is static property of a type
let aBasicObject = try? JSONDecoder().decode(BasicObject.self, from: data)
print(aBasicObject?.someKey)


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


//this is an array of json objects, so we'll need to get an array of dictionaries to turn into BiggerObjects
let biggerObjectString = """
[{"name":"istishna","greatness":"10"},{"name":"iram","greatness":9},{"name":"tia","greatness":11}, {}, {"name":"something else that won't work"}]
"""

struct BiggerObject {
    let name: String
    let greatness: Int
    let title: String
    
    //what does this do -> it can initialize an object, but it's allowed fail and return nil
    init?(from dict: [String:Any]) {
        guard let name = dict["name"] as? String else {
            return nil
        }
        let title = dict["title"] as? String

        //what if the key greatness has heterogenous values in the JSON provided by the API?
        //We can handle that!
        if let greatness = dict["greatness"] as? Int {
            self.greatness = greatness
        } else if let greatnessString = dict["greatness"] as? String, let greatness = Int(greatnessString) {
            self.greatness = greatness
        } else {
            return nil
        }

        self.name = name
        //We'll never fail to create an instance of BiggerObject just because the JSON data didn't include a value for title.
        self.title = title ?? "N/A"
    }
}

//if we have an array of things, how can we look through each and make sure that we're only keeping the non-nil elements?
// compactMap (it's a map that tries to do some stuff, but gets rid of the nils when that stuff doesnt work)

//utf8 -> 8 bits? Why, David? Let me get back to you.
//most US/Latin characters are represented in utf8
// chinese characters (because they're a composite of many characters in an extended grapheme cluster) are represented in utf16
let objectData = biggerObjectString.data(using: .utf8) ?? Data()

//Now we need to go from Any to [[String:Any]]
let serializedJSON = (try? JSONSerialization.jsonObject(with: objectData, options: []) as? [[String:Any]])!


//now let's go from [[String:Any]] to [BiggerObject]

let biggerObjects = serializedJSON.compactMap { BiggerObject(from: $0) }

biggerObjects


