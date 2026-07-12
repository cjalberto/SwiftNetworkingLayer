import Foundation
import NetworkingClient

/// The app's entry point into the CoinGecko API: one `EndpointClient` per resource group.
@available(macOS 10.13, *)
public protocol APIClient {
    var provider: Networking<HTTPClientError> { get }
    var coins: CoinsClient { get }
    var global: GlobalClient { get }
    var simple: SimpleClient { get }
}

/// Default `APIClient`, configured against the production CoinGecko `v3` API.
@available(macOS 12.0, *)
public struct API: APIClient {
    public var provider: Networking<HTTPClientError>

    public var coins: CoinsClient
    public var global: GlobalClient
    public var simple: SimpleClient

    static var shared: API = API(provider: Networking<HTTPClientError>(provider: ServerFactory.createServer(for: Environment.production.path, baseURL: BaseURL.network(version: "v3").description)))

    public init(provider: Networking<HTTPClientError>) {
        self.provider = provider
        self.coins = CoinsClient(provider: provider)
        self.global = GlobalClient(provider: provider)
        self.simple = SimpleClient(provider: provider)
    }
}
