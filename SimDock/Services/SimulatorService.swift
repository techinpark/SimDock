import Foundation

final class SimulatorService {

    func fetchDevices() throws -> [SimulatorRuntime] {
        let data = try ShellExecutor.run(arguments: ["simctl", "list", "devices", "--json"])
        let response = try JSONDecoder().decode(SimctlDevicesResponse.self, from: data)

        return response.devices.compactMap { (runtimeID, devices) in
            let available = devices.filter(\.isAvailable)
            guard !available.isEmpty else { return nil }
            return SimulatorRuntime(
                runtimeIdentifier: runtimeID,
                displayName: SimulatorRuntime.displayName(from: runtimeID),
                devices: available
            )
        }
        .sorted { $0.displayName < $1.displayName }
    }

    func bootDevice(_ udid: String) {
        ShellExecutor.runFireAndForget(arguments: ["simctl", "boot", udid])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ShellExecutor.runFireAndForget(
                executable: "/usr/bin/open",
                arguments: ["-a", "Simulator"]
            )
        }
    }

    func shutdownDevice(_ udid: String) {
        ShellExecutor.runFireAndForget(arguments: ["simctl", "shutdown", udid])
    }
}
