import Foundation

#if canImport(Combine)
import Combine
#endif

// MARK: - Sync Selector
public typealias SetBody<T> = (MutableContext, T) -> Void

public typealias CombineGetFunc<T: Equatable, E: Error> = (Getter) throws -> AnyPublisher<T, E>

public typealias SyncGetFunc<T> = (Getter) throws -> T

public typealias AsyncGetFunc<T: Equatable> = (Getter) async throws -> T

///A ``selector`` is a pure function that accepts atoms or other sync selectors as input. When these upstream atoms or sync selectors are updated, the selector function will be re-evaluated. Components can subscribe to selectors just like atoms, and will then be re-rendered when the selectors change.

/// **Selectors** are used to calculate derived data that is based on state. This lets us avoid redundant state because a minimal set of state is stored in atoms, while everything else is efficiently computed as a function of that minimal state.
///
///```swift
/// let currentBooksSel = selector { get -> [Book] in
///    let books = get(allBookStore)
///      if let category = get(selectedCategoryState) {
///          return books.filter { $0.category == category }
///      }
///    return books
///}
///```
public struct Selector<T: Equatable>: SyncSelectorNode {
    public typealias T = T
    public typealias E = Never
    
    public let key: String
    public var get: (Getter) throws -> T
    
    init(key: String = "R-Sel-\(UUID())", body: @escaping SyncGetFunc<T>) {
        self.key = key
        self.get = body
    }
}

/// ``MutableSelector`` is a bi-directional sync selector receives the incoming value as a parameter and can use that to propagate the changes back upstream along the data-flow graph.

///```swift
/// let tempFahrenheitState = atom(32)
/// let tempCelsiusSelector = selector(
///      get: { get in
///        let fahrenheit = get(tempFahrenheitState)
///        return (fahrenheit - 32) * 5 / 9
///      },
///      set: { context, newValue in
///        let newFahrenheit = (newValue * 9) / 5 + 32
///        context.set(tempFahrenheitState, newFahrenheit)
///      }
///)
///```
public struct MutableSelector<T: Equatable>: SyncSelectorNode {
    public typealias T = T
    public typealias E = Never
    
    public let key: String
    public var get: (Getter) throws -> T
    public let set: SetBody<T>

    public init(key: String = "WR-Sel-\(UUID())", get: @escaping SyncGetFunc<T>, set: @escaping SetBody<T>) {
        self.key = key
        self.get = get
        self.set = set
    }
}

extension MutableSelector: Writeable {
    public func update(context: MutableContext, newValue: T) {
        set(context, newValue)
    }
}

// MARK: - Async Selector

/// A ``AsyncSelector`` is a pure function that other async selectors as input. those selector be impletemented
/// by ``Combine`` or ``async/await``
/// ``Selector`` and ``AsyncSelector`` can not allow you pass a user-defined argument, if you want to pass a
/// customable parameters. please refer to ``selectorFamily``

public struct AsyncSelector<T: Equatable>: AsyncSelectorNode {
    public let key: String
    public var get: (Getter) async throws -> T

    public init<E: Error>(key: String = "R-AsyncSel-\(UUID())", get: @escaping CombineGetFunc<T, E>) {
        self.key = key
        self.get = { try await get($0).async() }
    }
    
    public init(key: String = "R-AsyncSel-\(UUID())", get: @escaping AsyncGetFunc<T>) {
        self.key = key
        self.get = get
    }
}

// TODO: Not support yet
//
//public struct MutableAsyncSelector<T: Equatable, E: Error>: RecoilAsyncValue {
//    public let key: String
//    public let get: AsyncGet
//    public let set: SetBody<T?>
//
//    public init(key: String = "WR-AsyncSel-\(UUID())",
//                get: @escaping CombineGetBody<T, E>,
//                set: @escaping SetBody<T?>) {
//        self.key = key
//        self.get = CombineCallback(get: get)
//        self.set = set
//    }
//}
//
//
//extension MutableAsyncSelector: RecoilSyncWriteable { }
