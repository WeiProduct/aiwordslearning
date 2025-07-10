//
//  DIContainerTests.swift
//  单词Tests
//
//  Created by Claude on 2025-06-28.
//

import XCTest
@testable import 单词

final class DIContainerTests: XCTestCase {
    var container: DIContainer!
    
    override func setUpWithError() throws {
        container = DIContainer()
    }
    
    override func tearDownWithError() throws {
        container.clear()
        container = nil
    }
    
    func testRegisterAndResolveInstance() throws {
        let testService = TestService()
        container.register(TestServiceProtocol.self, instance: testService)
        
        let resolved = container.resolve(TestServiceProtocol.self)
        XCTAssertNotNil(resolved)
        XCTAssertTrue(resolved === testService)
    }
    
    func testRegisterAndResolveFactory() throws {
        container.register(TestServiceProtocol.self) {
            TestService()
        }
        
        let resolved1 = container.resolve(TestServiceProtocol.self)
        let resolved2 = container.resolve(TestServiceProtocol.self)
        
        XCTAssertNotNil(resolved1)
        XCTAssertNotNil(resolved2)
        XCTAssertTrue(resolved1 === resolved2) // 应该是单例
    }
    
    func testResolveRequired() throws {
        let testService = TestService()
        container.register(TestServiceProtocol.self, instance: testService)
        
        let resolved = container.resolveRequired(TestServiceProtocol.self)
        XCTAssertTrue(resolved === testService)
    }
    
    func testResolveRequiredThrowsForUnregistered() throws {
        XCTAssertThrowsError(try {
            let _ = container.resolveRequired(TestServiceProtocol.self)
        }())
    }
    
    func testIsRegistered() throws {
        XCTAssertFalse(container.isRegistered(TestServiceProtocol.self))
        
        container.register(TestServiceProtocol.self, instance: TestService())
        XCTAssertTrue(container.isRegistered(TestServiceProtocol.self))
    }
    
    func testClear() throws {
        container.register(TestServiceProtocol.self, instance: TestService())
        XCTAssertTrue(container.isRegistered(TestServiceProtocol.self))
        
        container.clear()
        XCTAssertFalse(container.isRegistered(TestServiceProtocol.self))
    }
    
    func testInjectedPropertyWrapper() throws {
        let testService = TestService()
        container.register(TestServiceProtocol.self, instance: testService)
        
        let testObject = TestObjectWithInjection(container)
        XCTAssertTrue(testObject.service === testService)
    }
    
    func testLazyInjectedPropertyWrapper() throws {
        let testService = TestService()
        container.register(TestServiceProtocol.self, instance: testService)
        
        var testObject = TestObjectWithLazyInjection(container)
        XCTAssertTrue(testObject.service === testService)
    }
    
    func testThreadSafety() throws {
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.container.register(TestServiceProtocol.self) {
                    TestService()
                }
                
                let resolved = self.container.resolve(TestServiceProtocol.self)
                XCTAssertNotNil(resolved)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

protocol TestServiceProtocol: AnyObject {
    func doSomething() -> String
}

class TestService: TestServiceProtocol {
    func doSomething() -> String {
        return "Test Service"
    }
}

struct TestObjectWithInjection {
    @Injected var service: TestServiceProtocol
    
    init(_ container: DIContainer) {
        self._service = Injected(container)
    }
}

struct TestObjectWithLazyInjection {
    @LazyInjected var service: TestServiceProtocol
    
    init(_ container: DIContainer) {
        self._service = LazyInjected(container)
    }
}