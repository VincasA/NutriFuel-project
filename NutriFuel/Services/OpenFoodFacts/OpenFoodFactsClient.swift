import Foundation

enum OpenFoodFactsError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Failed to build Open Food Facts request URL."
        case .requestFailed(let statusCode):
            return "Open Food Facts request failed with status code \(statusCode)."
        case .decodeFailed:
            return "Failed to decode Open Food Facts response payload."
        }
    }
}

protocol OpenFoodFactsProductFetching {
    func fetchProduct(barcode: String) async throws -> OFFProductDTO?
    func searchProducts(query: String, limit: Int) async throws -> [OFFProductDTO]
}

struct OpenFoodFactsClient: OpenFoodFactsProductFetching {
    private let session: URLSession
    private let userAgent: String

    init(session: URLSession = .shared, userAgent: String = "NutriFuel/1.0 (iOS)") {
        self.session = session
        self.userAgent = userAgent
    }

    func fetchProduct(barcode: String) async throws -> OFFProductDTO? {
        let normalizedBarcode = OFFProductDTO.normalizeBarcode(barcode)
        guard !normalizedBarcode.isEmpty else { return nil }

        guard var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(normalizedBarcode)") else {
            throw OpenFoodFactsError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "fields", value: OFFAPIFields.productFields)
        ]

        guard let url = components.url else {
            throw OpenFoodFactsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.requestFailed(statusCode: -1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw OpenFoodFactsError.requestFailed(statusCode: http.statusCode)
        }

        guard let decoded = try? JSONDecoder().decode(OFFProductResponse.self, from: data) else {
            throw OpenFoodFactsError.decodeFailed
        }

        guard decoded.status == 1, let product = decoded.product else {
            return nil
        }

        return OFFProductDTO.from(product: product, expectedBarcode: normalizedBarcode)
    }

    func searchProducts(query: String, limit: Int = 20) async throws -> [OFFProductDTO] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        guard var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl") else {
            throw OpenFoodFactsError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "search_terms", value: trimmedQuery),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: String(max(limit, 1))),
            URLQueryItem(name: "fields", value: OFFAPIFields.searchFields),
        ]

        guard let url = components.url else {
            throw OpenFoodFactsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.requestFailed(statusCode: -1)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw OpenFoodFactsError.requestFailed(statusCode: http.statusCode)
        }

        guard let decoded = try? JSONDecoder().decode(OFFSearchResponse.self, from: data) else {
            throw OpenFoodFactsError.decodeFailed
        }

        var seenCodes = Set<String>()
        var resolved: [OFFProductDTO] = []
        resolved.reserveCapacity(decoded.products.count)

        for product in decoded.products {
            guard let mapped = OFFProductDTO.from(product: product, expectedBarcode: nil) else { continue }
            if seenCodes.insert(mapped.code).inserted {
                resolved.append(mapped)
            }
        }

        return resolved
    }
}

private enum OFFAPIFields {
    static let productFields = [
        "code",
        "product_name",
        "brands",
        "serving_size",
        "serving_quantity",
        "serving_quantity_unit",
        "nutrition_data_per",
        "nutriments",
    ].joined(separator: ",")

    static let searchFields = productFields
}

struct OFFProductResponse: Decodable {
    let status: Int
    let product: OFFProductPayload?
}

struct OFFSearchResponse: Decodable {
    let count: Int?
    let pageSize: Int?
    let products: [OFFProductPayload]

    enum CodingKeys: String, CodingKey {
        case count
        case pageSize = "page_size"
        case products
    }
}
