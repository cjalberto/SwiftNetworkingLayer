import Foundation
import NetworkingClient

protocol GlobalClientProtocol {
    func fetchGlobalCryptoCurrencies() async -> Result<CryptoCurrencyGlobalInfoDTO, HTTPClientError>
}

/// Fetches global cryptocurrency market data from the CoinGecko API.
public struct GlobalClient: EndpointClient {
    public var provider: Networking<HTTPClientError>
    
    public struct Global: JSONEndpointBase {
        public var body: Data?
        
        public typealias requestType = CryptoCurrencyGlobalInfoDTO
        
        internal init(body: Data? = nil){}
        
        public var method: HTTPMethod { .get }
        public var path: String {
            return "global"
        }
    }
}

extension GlobalClient: GlobalClientProtocol {
    func fetchGlobalCryptoCurrencies() async -> Result<CryptoCurrencyGlobalInfoDTO, HTTPClientError> {
        let result = await self.request(endpoint: GlobalClient.Global())
        return result
    }
}


