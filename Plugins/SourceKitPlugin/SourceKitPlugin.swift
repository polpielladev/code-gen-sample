import PackagePlugin

@main
struct SourceKitPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        [
            .buildCommand(
                displayName: "Protocol Extraction!",
                executable: try context.tool(named: "PluginExecutable").path,
                arguments: [
                    "FindThis",
                    "--files",
                    target.directory.appending("CodeGenSample.swift"),
                    "--output",
                    context.pluginWorkDirectory.string
                ],
                environment: ["IN_PROCESS_SOURCEKIT": "YES"]
            )
        ]
    }
}

