import Foundation

/// When bridging from a sync to async context using multiple `Task`s, order of execution is not guaranteed.
/// Using an `AsyncStream` we can bridge enqueued work to an async context within a single `Task`.
/// https://forums.swift.org/t/a-pitfall-when-using-didset-and-task-together-order-cant-be-guaranteed/71311/6
@available(iOS 13, tvOS 13, *)
final class Queue {
    typealias Operation = @Sendable () async -> Void
    private let continuation: AsyncStream<Operation>.Continuation
    private let task: Task<Void, Never>

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: Operation.self)

        self.continuation = continuation
        self.task = Task {
            for await operation in stream {
                await operation()
            }
        }
    }

    func enqueue(_ operation: @escaping Operation) {
        continuation.yield(operation)
    }

    deinit {
        task.cancel()
    }
}
