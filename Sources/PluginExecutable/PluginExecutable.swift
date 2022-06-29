import SourceKittenFramework
import ArgumentParser
import Foundation

class CurrentPath {
    var seenTypes = [String]()
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
        var matchedTypes = [String]()
        structures.forEach { walkTree(dictionary: $0.dictionary, acc: &matchedTypes) }
        print(matchedTypes)
        try createOutputFile(withContent: matchedTypes)
    }
    
    private func walkTree(dictionary: [String: SourceKitRepresentable], acc: inout [String], currentPath: CurrentPath? = nil) {
        guard let substructure = dictionary["key.substructure"] as? [[String: SourceKitRepresentable]] else {
            let hasMatched = hasMatchedType(withInheritance: protocolName, from: dictionary)
            
            if let name = dictionary["key.name"] as? String, let currentPath = currentPath {
                currentPath.seenTypes.append(name)
            }
            
            if hasMatched, let currentPath = currentPath {
                acc.append("\(currentPath.seenTypes.joined(separator: "."))")
            }
        
            return
        }
        
        substructure.forEach { innerDict in
            // Set if it's the beginning of a path.
            let toSendCurrentPath = currentPath ?? CurrentPath()
            if let name = innerDict["key.name"] as? String {
                toSendCurrentPath.seenTypes.append(name)
            }
            
            let hasMatched = hasMatchedType(withInheritance: protocolName, from: innerDict)
            
            if hasMatched, let currentPath = currentPath {
                acc.append("\(currentPath.seenTypes.joined(separator: "."))")
                return
            }
            
            // Recurse through every single bit...
            if let substructure = innerDict["key.substructure"] as? [[String: SourceKitRepresentable]] {
                substructure.forEach { walkTree(dictionary: $0, acc: &acc, currentPath: toSendCurrentPath) }
            }
        }
    }
    
    private func hasMatchedType(withInheritance inheritanceName: String, from dict: [String: SourceKitRepresentable]) -> Bool {
        guard let inheritedTypes = dict["key.inheritedtypes"] as? [[String: String]] else { return false }
        
        return !inheritedTypes
            .compactMap { $0["key.name"] }
            .filter { $0 == inheritanceName }
            .isEmpty
    }
    
    private func createOutputFile(withContent matchedTypes: [String]) throws {
        let testMethods = matchedTypes.map {
            """
            \tfunc testThis() {
            \t\t\($0)
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
