
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


