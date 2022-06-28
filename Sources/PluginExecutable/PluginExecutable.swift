import SourceKittenFramework

struct MatchedType {
    let kind: String
    let name: String
}

@main struct PluginExecutable {
    static func main() throws {
        let structure = try Structure(file: File(path: "/Users/polpiella/Developer/CodeGenSample/Sources/CodeGenSample/CodeGenSample.swift")!)
        var matchedTypes = [MatchedType]()
        walkTree(dictionary: structure.dictionary, acc: &matchedTypes)
    }
    
    private static func walkTree(dictionary: [String: SourceKitRepresentable], acc: inout [MatchedType]) {
        acc.append(contentsOf: extractTypeNames(withInheritance: "FindThis", from: dictionary))
        
        if let array = dictionary["key.substructure"] as? [[String: SourceKitRepresentable]] {
            array.forEach { innerDict in
                acc.append(contentsOf: extractTypeNames(withInheritance: "FindThis", from: innerDict))
                
                // Recurse through every single bit...
                if let substructure = innerDict["key.substructure"] as? [[String: SourceKitRepresentable]] {
                    substructure.forEach { walkTree(dictionary: $0, acc: &acc) }
                }
            }
        }
    }
    
    private static func extractTypeNames(withInheritance inheritanceName: String, from dict: [String: SourceKitRepresentable]) -> [MatchedType] {
        guard let inheritedTypes = dict["key.inheritedtypes"] as? [[String: String]],
              let name = dict["key.name"] as? String,
              let kind = dict["key.kind"] as? String else { return [] }
        
        return inheritedTypes
            .compactMap { $0["key.name"] }
            .filter { $0 == inheritanceName }
            .map { _ in MatchedType(kind: kind, name: name) }
    }
}
