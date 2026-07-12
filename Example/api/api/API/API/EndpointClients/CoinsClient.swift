import Foundation
import NetworkingClient

protocol CointClientProtocol {
    func fetchCryptoCurrencyBasicInfo() async -> Result<[CryptoCurrencyBasicDTO], HTTPClientError>
}

/// Fetches the list of coins known to the CoinGecko API.
public struct CoinsClient: EndpointClient {
    public var provider: Networking<HTTPClientError>
    
    public struct List: Endpoint {
        public var body: Data?
        
        public typealias requestType = [CryptoCurrencyBasicDTO]
        
        internal init(data: Data? = nil){}
        
        public var method: HTTPMethod { .get }
        public var path: String {
            return "coins/list"
        }
    }
}

extension CoinsClient: CointClientProtocol {
    func fetchCryptoCurrencyBasicInfo() async -> Result<[CryptoCurrencyBasicDTO], HTTPClientError> {
        let result = await self.request(endpoint: CoinsClient.List())
        return result
    }
}
