import SourceKittenFramework
import ArgumentParser

struct MatchedType {
    let kind: String
    let name: String
}

@main
struct PluginExecutable: ParsableCommand {
    @Argument(help: "The protocol name to match")
    var protocolName: String
    
    @Option(help: "The files to be parsed by the script")
    var files: [String]
    
    @Option(help: "The path where the generated files will be created")
    var outputPath: String
    
    func run() throws {
        let structures = try files.map { try Structure(file: File(path: $0)!) }
        var matchedTypes = [MatchedType]()
        structures.forEach { walkTree(dictionary: $0.dictionary, acc: &matchedTypes) }
    }
    
    private func walkTree(dictionary: [String: SourceKitRepresentable], acc: inout [MatchedType]) {
        acc.append(contentsOf: extractTypeNames(withInheritance: protocolName, from: dictionary))
        
        if let array = dictionary["key.substructure"] as? [[String: SourceKitRepresentable]] {
            array.forEach { innerDict in
                acc.append(contentsOf: extractTypeNames(withInheritance: protocolName, from: innerDict))
                
                // Recurse through every single bit...
                if let substructure = innerDict["key.substructure"] as? [[String: SourceKitRepresentable]] {
                    substructure.forEach { walkTree(dictionary: $0, acc: &acc) }
                }
            }
        }
    }
    
    private func extractTypeNames(withInheritance inheritanceName: String, from dict: [String: SourceKitRepresentable]) -> [MatchedType] {
        guard let inheritedTypes = dict["key.inheritedtypes"] as? [[String: String]],
              let name = dict["key.name"] as? String,
              let kind = dict["key.kind"] as? String else { return [] }
        
        return inheritedTypes
            .compactMap { $0["key.name"] }
            .filter { $0 == inheritanceName }
            .map { _ in MatchedType(kind: kind, name: name) }
    }
}
