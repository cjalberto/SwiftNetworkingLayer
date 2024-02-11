import XCTest
@testable import NetwokingClient

final class NetwokingClientTests: XCTestCase {
    
    struct EpisodeResponse: Codable {
        let info: Info
        let results: [Episode]
    }

    struct Info: Codable {
        let count: Int
        let pages: Int
        let next: String?
        let prev: String?
    }

    struct Episode: Codable {
        let id: Int
        let name: String
        let airDate: String
        let episode: String
        let characters: [String]
        let url: String
        let created: String
        
        enum CodingKeys: String, CodingKey {
            case id, name, episode, characters, url, created
            case airDate = "air_date"
        }
    }
    
    // Mock Endpoint for testing
    struct MockEndpoint: Endpoint {
        typealias requestType = EpisodeResponse
        var method: HTTPMethod = .get
        var path: String = "episode"
        var body: Data? = nil
    }
    
    // Test asynchronous request
    func testAsyncRequest() {
        let server = ServerFactory.createServer(for: "", baseURL: "https://rickandmortyapi.com/api")
        let networking = Networking(provider: server)
        let expectation = expectation(description: "Async request expectation")
        
        networking.request(endpoint: MockEndpoint()) { result in
            switch result {
            case .success(let data):
                XCTAssert(true, "Decoding successful")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // Test synchronous request
    func testSyncRequest() async {
        let server = ServerFactory.createServer(for: "test", baseURL: "https://example.com")
        let networking = Networking(provider: server)
        
        let result = await networking.request(endpoint: MockEndpoint())
        
        switch result {
        case .success(let data):
            XCTAssert(true, "Decoding successful")
        case .failure(let error):
            XCTFail("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    // Test Combine request
    @available(iOS 13.0, *)
    func testCombineRequest() {
        let server = ServerFactory.createServer(for: "test", baseURL: "https://example.com")
        let networking = Networking(provider: server)
        
        let publisher = networking.request(endpoint: MockEndpoint())
        
        let expectation = XCTestExpectation(description: "Combine request expectation")
        
        let cancellable = publisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Unexpected error: \(error.localizedDescription)")
                }
            }, receiveValue: { data in
                XCTAssert(true, "Decoding successful")
            })
        
        wait(for: [expectation], timeout: 5)
        cancellable.cancel()
    }
}
