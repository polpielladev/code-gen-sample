import SourceKittenFramework
import ArgumentParser
import Foundation

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
    var output: String
    
    func run() throws {
        // Needed to ensure that sourcekit runs in a single process
        setenv("IN_PROCESS_SOURCEKIT", "YES", 1)
        let structures = try files.map { try Structure(file: File(path: $0)!) }
        var matchedTypes = [MatchedType]()
        structures.forEach { walkTree(dictionary: $0.dictionary, acc: &matchedTypes) }
        try createOutputFile(withContent: matchedTypes)
    }
    
    private func walkTree(dictionary: [String: SourceKitRepresentable], acc: inout [MatchedType]) {
        acc.append(contentsOf: extractTypeNames(withInheritance: protocolName, from: dictionary))
        
        if let array = dictionary["key.substructure"] as? [[String: SourceKitRepresentable]] {
            array.forEach { innerDict in
                let extractedTypes = extractTypeNames(withInheritance: protocolName, from: innerDict)
                let hasMatched = !extractedTypes.isEmpty
                
                acc.append(contentsOf: extractedTypes)
                
                guard !hasMatched else { return }
                
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
    
    private func createOutputFile(withContent matchedTypes: [MatchedType]) throws {
        let testMethods = matchedTypes.map {
            """
            \tfunc testThis() {
            \t\t\($0.name)
            \t}
            """
        }.joined(separator: "\n")
        
        let template = """
        import XCTestCase
        
        class XCTests: XCTestCase {
        \(testMethods)
        }
        """
        
        let fileURL = URL(fileURLWithPath: output)

        try template.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
