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
    
    @Argument(help: "The module's name")
    var moduleName: String
    
    @Option(help: "Directory containing the swift files")
    var input: String
    
    @Option(help: "The path where the generated files will be created")
    var output: String
    
    func run() throws {
        // Needed to ensure that sourcekit runs in a single process
        setenv("IN_PROCESS_SOURCEKIT", "YES", 1)
        let files = try deepSearch(URL(fileURLWithPath: input, isDirectory: true))
        let structures = try files.map { try Structure(file: File(path: $0.path)!) }
        var matchedTypes = [String]()
        structures.forEach { walkTree(dictionary: $0.dictionary, acc: &matchedTypes) }
        try createOutputFile(withContent: matchedTypes)
    }
    
    private func deepSearch(_ directory: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        
        return try enumerator
            .compactMap { $0 as? URL }
            .filter { try $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! }
            .filter { $0.pathExtension == "swift" }
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
        
        if let name = dictionary["key.name"] as? String, !hasMatchedType(withInheritance: protocolName, from: dictionary) {
            currentPath?.seenTypes.append(name)
        }
        
        substructure.forEach { innerDict in
            // Set if it's the beginning of a path.
            let currentPath = currentPath ?? CurrentPath()
            if let name = innerDict["key.name"] as? String {
                currentPath.seenTypes.append(name)
            }
            
            let hasMatched = hasMatchedType(withInheritance: protocolName, from: innerDict)
            
            if hasMatched {
                acc.append("\(currentPath.seenTypes.joined(separator: "."))")
                return
            }
            
            // Recurse through every single bit...
            if let substructure = innerDict["key.substructure"] as? [[String: SourceKitRepresentable]] {
                substructure.forEach { walkTree(dictionary: $0, acc: &acc, currentPath: currentPath) }
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
            \tfunc test\($0.replacingOccurrences(of: ".", with: "_"))() {
            \t\tassertCanParseFromDefaults(\($0).self)
            \t}
            """
        }.joined(separator: "\n")
        
        let template = """
        import XCTest
        @testable import \(moduleName)
        
        class GeneratedTests: XCTestCase {
        \(testMethods)
        
            private func assertCanParseFromDefaults<T: \(protocolName)>(_ type: T.Type) {
                // Logic goes here...
            }
        }
        """
        
        let fileURL = URL(fileURLWithPath: output)
        
        try template.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
