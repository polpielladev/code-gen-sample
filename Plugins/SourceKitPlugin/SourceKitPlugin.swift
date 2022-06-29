import PackagePlugin

@main
struct SourceKitPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let outputPath = context.pluginWorkDirectory.appending("Generated.swift")
        guard let dependencyTarget = target
            .dependencies
            .compactMap({ dependency -> Target? in
                switch dependency {
                case .target(let target): return target
                default: return nil
                }
            }).filter({ "\($0.name)Tests" == target.name  }).first else {
            Diagnostics.error("Could not get a dependency to scan!")
            return []
        }
        return [
            .buildCommand(
                displayName: "Protocol Extraction!",
                executable: try context.tool(named: "PluginExecutable").path,
                arguments: [
                    "FindThis",
                    dependencyTarget.name,
                    "--input",
                    dependencyTarget.directory,
                    "--output",
                    outputPath.string
                ],
                environment: ["IN_PROCESS_SOURCEKIT": "YES"],
                outputFiles: [outputPath]
            )
        ]
    }
}

