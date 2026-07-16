import Foundation

final class CodexFileMonitor {
    private let queue = DispatchQueue(label: "CodexFileMonitor.queue")
    private var sources: [DispatchSourceFileSystemObject] = []
    private var descriptors: [Int32] = []
    private var currentPaths: Set<String> = []

    deinit {
        stop()
    }

    func updateMonitoredPaths(_ paths: [URL], onChange: @escaping @Sendable () -> Void) {
        let nextPaths = Set(paths.map(\.path))
        guard nextPaths != currentPaths else { return }
        currentPaths = nextPaths
        stop()

        for path in nextPaths {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { continue }
            guard isDirectory.boolValue else { continue }
            let fd = open(path, O_EVTONLY)
            guard fd >= 0 else { continue }

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .delete, .rename, .extend, .attrib],
                queue: queue
            )
            source.setEventHandler {
                DispatchQueue.main.async {
                    onChange()
                }
            }
            source.setCancelHandler {
                close(fd)
            }
            source.resume()
            descriptors.append(fd)
            sources.append(source)
        }
    }

    func stop() {
        sources.forEach { $0.cancel() }
        sources.removeAll()
        descriptors.removeAll()
        currentPaths.removeAll()
    }
}
