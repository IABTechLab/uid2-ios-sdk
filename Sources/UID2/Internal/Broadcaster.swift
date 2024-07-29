import Foundation

/// Send a value to multiple observers
actor Broadcaster<Element: Sendable> {
    typealias Identifier = UUID
    private var continuations: [Identifier: AsyncStream<Element>.Continuation] = [:]

    func values() -> AsyncStream<Element> {
        .init { continuation in
            let id = Identifier()
            continuations[id] = continuation

            continuation.onTermination = { _ in
                Task { [weak self] in
                    await self?.remove(id)
                }
            }
        }
    }

    func remove(_ id: Identifier) {
        continuations[id] = nil
    }

    func send(_ value: Element) {
        continuations.values.forEach { $0.yield(value) }
    }

    deinit {
        continuations.values.forEach { $0.finish() }
    }
}
