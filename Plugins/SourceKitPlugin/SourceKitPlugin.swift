import PackagePlugin

@main
struct SourceKitPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let outputPath = context.pluginWorkDirectory.appending("Generated.swift")
        guard let path = target.dependencies.compactMap({ dependency -> Target? in
            switch dependency {
            case .target(let target): return target
            default: return nil
            }
        }).filter({ "\($0.name)Tests" == target.name  }).map({ $0.directory }).first else {
            Diagnostics.error("Could not get a path!")
            return []
        }
        
        return [
            .buildCommand(
                displayName: "Protocol Extraction!",
                executable: try context.tool(named: "PluginExecutable").path,
                arguments: [
                    "FindThis",
                    "--input",
                    path,
                    "--output",
                    outputPath.string
                ],
                environment: ["IN_PROCESS_SOURCEKIT": "YES"],
                outputFiles: [outputPath]
            )
        ]
    }
}

