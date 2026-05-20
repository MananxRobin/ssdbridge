import Foundation

/// Watches /Volumes for drive changes (mount/unmount) using DispatchSource.
final class DriveWatcher: @unchecked Sendable {
    private var source: DispatchSourceFileSystemObject?
    private var lastDrives: Set<String> = []
    var onDriveChange: (([String]) -> Void)?

    func startWatching() {
        lastDrives = Set(currentDrives())

        let fd = open("/Volumes", O_EVTONLY)
        guard fd >= 0 else {
            Log.file.warning("Cannot watch /Volumes")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            self?.checkForChanges()
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        self.source = source
        Log.file.info("Watching /Volumes for drive changes")
    }

    func stopWatching() {
        source?.cancel()
        source = nil
    }

    func currentDrives() -> [String] {
        let fm = FileManager.default
        do {
            let volumes = try fm.contentsOfDirectory(atPath: "/Volumes")
            return volumes.filter { !$0.hasPrefix(".") }.sorted()
        } catch {
            return []
        }
    }

    private func checkForChanges() {
        let current = Set(currentDrives())
        if current != lastDrives {
            let added = current.subtracting(lastDrives)
            let removed = lastDrives.subtracting(current)
            for d in added { Log.file.info("Drive mounted: \(d)") }
            for d in removed { Log.file.info("Drive ejected: \(d)") }
            lastDrives = current
            onDriveChange?(Array(current))
        }
    }
}
