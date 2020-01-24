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
// Use the JsonDecoder's decode method -> we specify the model that we've defined
//say that "the decoder should try to decode some data object given the format defined in that type's definition"


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
// For each property we want to use, we then have to make sure that we're casting the Any value to the type of the property in our object's definition

//Remember Firebase? How did we initialize objects when we looked at a collection in Firebase and tried to turn the data from that collection into Swift stuff?
//Had a failing init function that looked through a dictionary.


//This struct allows us to init from either a JSONDecoder or a JSONSerializer. In the real world, a struct will likely only need Codable. It was a fun exercise though, wasn't it?
struct BiggerObject: Codable {
    let name: String
    let title: String
    //Below: underscore as the leading character is a convention that indicates this property should NOT be available outside of the the current scope. It should be private. It shouldn't be exposed to anyone using your classes/structs. It's solely here to be used within this object. You'll see this convention in many languages
    //Here specifically, we should not allow anyone using an instance of the Greatness object to be able to look at the property someBiggerObject._greatness.
    //We'll later look at it to provide the value for a computed property.
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


//Lab walkthrough!
let randomUsers = """
{
"results": [
{
"gender": "male",
"name": {
"title": "Mr",
"first": "Samuel",
"last": "Latt"
},
"location": {
"street": {
"number": 3760,
"name": "Rotuaari"
},
"city": "Juankoski",
"state": "Southern Ostrobothnia",
"country": "Finland",
"postcode": 38169,
"coordinates": {
"latitude": "-7.5665",
"longitude": "-51.9414"
},
"timezone": {
"offset": "+6:00",
"description": "Almaty, Dhaka, Colombo"
}
},
"email": "samuel.latt@example.com",
"login": {
"uuid": "d7c6b3c5-be47-42ca-9af9-e9779234f018",
"username": "yellowmeercat943",
"password": "passw0rd",
"salt": "T5sDjXPL",
"md5": "ac32bf9833410a3cba11a3ea34596b96",
"sha1": "22b4312f18152d4f451aeb3c367d674e77113c88",
"sha256": "0f7dee0df3e2b6d6364bb7c5184c6b38cd9dd753e2a24340fb355f26411d49a6"
},
"dob": {
"date": "1978-05-22T21:35:00.425Z",
"age": 42
},
"registered": {
"date": "2009-12-24T17:38:10.952Z",
"age": 11
},
"phone": "06-123-901",
"cell": "045-905-29-26",
"id": {
"name": "HETU",
"value": "NaNNA491undefined"
},
"picture": {
"large": "https://randomuser.me/api/portraits/men/48.jpg",
"medium": "https://randomuser.me/api/portraits/med/men/48.jpg",
"thumbnail": "https://randomuser.me/api/portraits/thumb/men/48.jpg"
},
"nat": "FI"
},
{
"gender": "female",
"name": {
"title": "Miss",
"first": "Minttu",
"last": "Jarvinen"
},
"location": {
"street": {
"number": 6326,
"name": "Rautatienkatu"
},
"city": "Tervo",
"state": "South Karelia",
"country": "Finland",
"postcode": 13085,
"coordinates": {
"latitude": "73.2374",
"longitude": "-163.0831"
},
"timezone": {
"offset": "+8:00",
"description": "Beijing, Perth, Singapore, Hong Kong"
}
},
"email": "minttu.jarvinen@example.com",
"login": {
"uuid": "83f397f1-7aa3-43da-adb0-3e5c4c06b351",
"username": "bluegoose174",
"password": "respect",
"salt": "m6uUrVbx",
"md5": "56e581dac9f863244f0878e71636af4e",
"sha1": "39dc12d7006d31230b32dcba054ad68ae36b404b",
"sha256": "d96e587478e8e85652005d1903bc27daf3c79b45277a0191c14525d845535356"
},
"dob": {
"date": "1969-06-09T08:54:09.883Z",
"age": 51
},
"registered": {
"date": "2011-02-27T20:44:22.135Z",
"age": 9
},
"phone": "02-501-645",
"cell": "041-546-11-05",
"id": {
"name": "HETU",
"value": "NaNNA926undefined"
},
"picture": {
"large": "https://randomuser.me/api/portraits/women/39.jpg",
"medium": "https://randomuser.me/api/portraits/med/women/39.jpg",
"thumbnail": "https://randomuser.me/api/portraits/thumb/women/39.jpg"
},
"nat": "FI"
},
{
"gender": "male",
"name": {
"title": "Monsieur",
"first": "Nolan",
"last": "Guerin"
},
"location": {
"street": {
"number": 7161,
"name": "Avenue du Château"
},
"city": "Rossa",
"state": "St. Gallen",
"country": "Switzerland",
"postcode": 7690,
"coordinates": {
"latitude": "-7.5243",
"longitude": "3.7582"
},
"timezone": {
"offset": "-7:00",
"description": "Mountain Time (US & Canada)"
}
},
"email": "nolan.guerin@example.com",
"login": {
"uuid": "61812a79-287a-4120-8f49-32b62b0bb1cb",
"username": "bluewolf682",
"password": "sang",
"salt": "USSn8UPh",
"md5": "b4728bef97b9527dac9fdd681b811a77",
"sha1": "bee23e9788ac501a7b698bb1f64495363d59cd8b",
"sha256": "df87665923a6fb7c1e0e6dbbd27bce876b3181d71a5388e35d555ff953102e2d"
},
"dob": {
"date": "1963-07-11T14:25:08.309Z",
"age": 57
},
"registered": {
"date": "2008-02-18T07:15:39.276Z",
"age": 12
},
"phone": "075 866 72 39",
"cell": "077 746 18 24",
"id": {
"name": "AVS",
"value": "756.4899.2037.47"
},
"picture": {
"large": "https://randomuser.me/api/portraits/men/82.jpg",
"medium": "https://randomuser.me/api/portraits/med/men/82.jpg",
"thumbnail": "https://randomuser.me/api/portraits/thumb/men/82.jpg"
},
"nat": "CH"
},
{
"gender": "female",
"name": {
"title": "Ms",
"first": "رها",
"last": "نكو نظر"
},
"location": {
"street": {
"number": 8984,
"name": "کلاهدوز"
},
"city": "ارومیه",
"state": "خراسان شمالی",
"country": "Iran",
"postcode": 69881,
"coordinates": {
"latitude": "39.6791",
"longitude": "-100.7422"
},
"timezone": {
"offset": "-1:00",
"description": "Azores, Cape Verde Islands"
}
},
"email": "rh.nkwnzr@example.com",
"login": {
"uuid": "fba1c3fa-55db-42da-9c45-e6c7a2d376ef",
"username": "angryostrich639",
"password": "bitter",
"salt": "6pF2KHqV",
"md5": "ef4b60f79c4f2a43837130763d4cd487",
"sha1": "5a8e56f7b8b1bdb0b7b4c0b726fe7197d70229cc",
"sha256": "beb76dae2da8b625347e4999a981521693792c6346a8573521ff99c216fdc35e"
},
"dob": {
"date": "1957-09-14T04:43:28.810Z",
"age": 63
},
"registered": {
"date": "2019-07-13T05:42:25.141Z",
"age": 1
},
"phone": "022-96975223",
"cell": "0995-088-6222",
"id": {
"name": "",
"value": null
},
"picture": {
"large": "https://randomuser.me/api/portraits/women/44.jpg",
"medium": "https://randomuser.me/api/portraits/med/women/44.jpg",
"thumbnail": "https://randomuser.me/api/portraits/thumb/women/44.jpg"
},
"nat": "IR"
},
{
"gender": "male",
"name": {
"title": "Mr",
"first": "Veeti",
"last": "Valli"
},
"location": {
"street": {
"number": 4048,
"name": "Esplanadi"
},
"city": "Malax",
"state": "North Karelia",
"country": "Finland",
"postcode": 91262,
"coordinates": {
"latitude": "74.3270",
"longitude": "-74.4108"
},
"timezone": {
"offset": "-8:00",
"description": "Pacific Time (US & Canada)"
}
},
"email": "veeti.valli@example.com",
"login": {
"uuid": "05c7cac6-cf6e-4f15-ae38-d984c20a93f7",
"username": "smallzebra218",
"password": "pathfind",
"salt": "JjCUqxtw",
"md5": "209541cb6dc1a013fbe94063886e3370",
"sha1": "98029ff3bf233944d96c870b5eabd19e15d1a16d",
"sha256": "f54ac762e882a664b2c0e4e53b4c5b2f14736312d512b2b3864802f786d77530"
},
"dob": {
"date": "1967-12-12T20:00:08.300Z",
"age": 53
},
"registered": {
"date": "2002-12-07T09:10:28.274Z",
"age": 18
},
"phone": "08-013-073",
"cell": "041-700-28-69",
"id": {
"name": "HETU",
"value": "NaNNA197undefined"
},
"picture": {
"large": "https://randomuser.me/api/portraits/men/86.jpg",
"medium": "https://randomuser.me/api/portraits/med/men/86.jpg",
"thumbnail": "https://randomuser.me/api/portraits/thumb/men/86.jpg"
},
"nat": "FI"
}
],
"info": {
"seed": "cb6d110c4edea727",
"results": 5,
"page": 1,
"version": "1.3"
}
}
"""

//Your app must include their postcode which can be either a String or an Int.

// Decode this JSON into some type
// Serialize this JSON into some type
// Q: What type do we need the JSON to start as, in order to Decode or Serialize it?
// A: It must be Data in either case

let randomUserData = randomUsers.data(using: .utf8) ?? Data()


struct UserWrapper: Codable {
    let results: [User]
}

struct User: Codable {
    let gender: String
    var postcode: String {
        return _postcode.value
    }
    
    private let _postcode: PostCode
    
    struct PostCode: Codable {
        let value: String
        //init while decoding (from Decoder)
        //we'll need some error type that we can throw
        //try to decode it as a String -> if it works, set value to that
        //try to decode it as an Int, then try to cast to a string -> if it works, set value to that
        //otherwise, throw error
    }
}

//when I decode, what will be the type that I tell the decoder it should use as a blueprint?
//UserWrapper, and then I can look at its results property to return the Users array

// To initialize as a serialized string
// Serialize the JSON, which creates an Any object
// Downcast it to [String:Any]
// Have a failing init that downcasts the required values from the dictionary in order to create new instances of the SerializableUser

