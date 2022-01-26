import XCTest
@testable import Asynchrone


final class AsyncSequenceTests: XCTestCase {
    private var sequence: AsyncStream<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }
    }
    
    // MARK: First
    
    func testFirst() async {
        let firstValue = await self.sequence.first()
        XCTAssertEqual(firstValue, 1)
    }
    
    // MARK: Collect
    
    func testCollect() async {
        let values = await self.sequence.collect()
        XCTAssertEqual(values, [1, 2, 3])
    }
    
    // MARK: Sink
    
    func testSink() async {
        var values: [Int] = []
        self.sequence.sink { values.append($0) }
        
        await XCTAssertEventuallyEqual(
            { values },
            { [1, 2, 3] }
        )
    }
    
    func testSinkWithFinishedCompletion() async {
        var values: [Int] = []
        self.sequence.sink(
            receiveValue: { values.append($0) },
            receiveCompletion: {
                switch $0 {
                case .failure(let error):
                    XCTFail("Invalid completion case: Failure \(error)")
                case .finished:()
                }
            }
        )
        
        await XCTAssertEventuallyEqual(
            { values },
            { [1, 2, 3] }
        )
    }
    
    func testSinkWithFailedCompletion() async {
        let completionExpectation = self.expectation(description: "Completion called")
        let sequence = AsyncThrowingStream<Int, Error> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish(throwing: TestError())
        }
        
        var values: [Int] = []
        sequence.sink(
            receiveValue: { values.append($0) },
            receiveCompletion: {
                switch $0 {
                case .failure:
                    completionExpectation.fulfill()
                case .finished:
                    XCTFail("Invalid completion case: Finished")
                }
            }
        )
        
        await self.waitForExpectations(timeout: 5.0, handler: nil)
        
        await XCTAssertEventuallyEqual(
            { values },
            { [1, 2, 3] }
        )
    }
}