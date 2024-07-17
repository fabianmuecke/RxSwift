//
//  ActorScheduler.swift
//  RxSwift
//
//  Created by Fabian Mücke on 17.07.24.
//  Copyright © 2024 Krunoslav Zaher. All rights reserved.
//

import Foundation

/// Schedules work to be isolated by a dedicated actor.
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public final class ActorScheduler<A: Actor>: SchedulerType, ImmediateSchedulerType {
    private let actor: A

    /// Creates a new instance.
    /// 
    /// Work will be isolated on the given `actor`.
    public init(actor: A) {
        self.actor = actor
    }
    
    // MARK: ImmediateSchedulerType

    public func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        let disposable = SingleAssignmentDisposable()

        let onActor: (isolated A) -> Void = { _ in
            if disposable.isDisposed {
                return
            }
            disposable.setDisposable(action(state))
        }

        Task { await onActor(actor) }

        return disposable
    }
    
    // MARK: SchedulerType
    
    public var now: RxTime { Date() }
    
    public func scheduleRelative<StateType>(_ state: StateType, dueTime: RxTimeInterval, action: @escaping (StateType) -> any Disposable) -> any Disposable {
        let deadline = DispatchTime.now().advanced(by: dueTime)

        let compositeDisposable = CompositeDisposable()
        
        let onActor: (isolated A) -> Void = { _ in
            if compositeDisposable.isDisposed {
                return
            }
            _ = compositeDisposable.insert(action(state))
        }
        
        let task = Task {
            let nanos = DispatchTime.now().distance(to: deadline).nanos
            if nanos > 0 {
                try await Task.sleep(nanoseconds: UInt64(nanos))
            }
            await onActor(actor)
        }
        
        _ = compositeDisposable.insert(Disposables.create {
            task.cancel()
        })
        
        return compositeDisposable
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
extension ActorScheduler where A: GlobalActor, A.ActorType == A {
    /// Shorthand initializer for global actors.
    public convenience init(actorType: A.Type = A.self) {
        self.init(actor: actorType.shared)
    }
}

private extension DispatchTimeInterval {
   var nanos: Int64 {
       switch self {
       case let .seconds(seconds):
           return Int64(seconds) * 1_000_000_000
       case let .milliseconds(millis):
           return Int64(millis) * 1_000_000
       case let .microseconds(micros):
           return Int64(micros) * 1000
       case let .nanoseconds(nanos):
           return Int64(nanos)
       case .never:
           return .max
       @unknown default:
           assertionFailure()
           return 0
       }
   }
}
