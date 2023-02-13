//
//  RepeatingTimer.swift
//  
//
// From: https://medium.com/over-engineering/a-background-repeating-timer-in-swift-412cecfd2ef9
//

import Foundation

class RepeatingTimer {
    
    let retryTimeInMilliseconds: Int
    
    init(retryTimeInMilliseconds: Int) {
        self.retryTimeInMilliseconds = retryTimeInMilliseconds
    }
    
    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(wallDeadline: .now(), repeating: .milliseconds(retryTimeInMilliseconds))
        timer.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return timer
    }()
    
    var eventHandler: (() -> Void)?
    
    private enum State {
        case suspended
        case resumed
    }
    
    private var state: State = .suspended
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }
    
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
    
}
