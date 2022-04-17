import SwiftUI
import XCTest
import Combine

@testable import RecoilSwift

final class RecoilReactiveTests: XCTestCase {
  typealias Selector = RecoilSwift.Selector
  
  struct TestModule  {
    static var stringAtom: Atom<String>!
    static var upstreamSyncState: Selector<String>!
    static var downstreamSyncState: Selector<String>!
    
    static var upstreamAsyncState: AsyncSelector<String, Error>!
    static var downstreamAsyncState: AsyncSelector<String, Error>!
  }
  
  override func setUp() {
    TestModule.stringAtom = atom { "rawValue" }
    TestModule.upstreamSyncState = selector { _ throws -> String in "sync value" }
    TestModule.downstreamSyncState = selector { get throws -> String in
      let string = get(TestModule.upstreamSyncState)
      return string.uppercased()
    }
    TestModule.upstreamAsyncState = makeAsyncSelector(value: "async value")
    TestModule.downstreamAsyncState = selector { get throws -> String in
      let string = get(TestModule.upstreamAsyncState) ?? ""
      return string.uppercased()
    }
  }
  
  func testShouldGetValueFromUpstreamSyncSelector() {
    let tester = HookTester {
      useRecoilValue(TestModule.downstreamSyncState)
    }
    
    XCTAssertEqual(tester.value, "sync value".uppercased())
  }
  
  func testShouldGetValueFromUpstreamAsyncSelector() {
    let expectation = XCTestExpectation(description: "Async value reovled")
    
    let tester = HookTester { () -> LoadableContent<String, Error> in
      let loadable = useRecoilValueLoadable(TestModule.downstreamAsyncState)
      
      if loadable.data == "async value".uppercased() {
        expectation.fulfill()
      }
      
      return loadable
    }
    
    XCTAssertNil(tester.value.data)

    wait(for: [expectation], timeout: TestConfig.expectation_wait_seconds)
  }
  
  func testShouldReturnLoadingWhenUpstream() {
    let expectation = XCTestExpectation(description: "should return correct loading status")
    
    let tester = HookTester { () -> LoadableContent<String, Error> in
       useRecoilValueLoadable(TestModule.downstreamAsyncState)
    }
    
    XCTAssertTrue(tester.value.isLoading)
    DispatchQueue.main.asyncAfter(deadline: .now() + TestConfig.expectation_wait_seconds) {
      if tester.value.isLoading == false {
        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: TestConfig.expectation_wait_seconds)
  }
}
