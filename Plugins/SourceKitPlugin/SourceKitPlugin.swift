import PackagePlugin

@main
struct SourceKitPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // find a way to get all the files please?
        []
    }
}

