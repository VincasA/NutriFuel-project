import Foundation
import SwiftData

protocol OfficialFoodProviding {
    func lookupByBarcode(_ barcode: String) async throws -> OfficialFood?
    func searchByText(_ query: String, limit: Int) async throws -> [OfficialFood]
}

@MainActor
final class OfficialFoodRepository: OfficialFoodProviding {
    private let modelContext: ModelContext
    private let offClient: OpenFoodFactsProductFetching
    private let now: () -> Date
    private let refreshInterval: TimeInterval

    init(
        modelContext: ModelContext,
        offClient: OpenFoodFactsProductFetching,
        now: @escaping () -> Date = Date.init,
        refreshInterval: TimeInterval = 60 * 60 * 24 * 30
    ) {
        self.modelContext = modelContext
        self.offClient = offClient
        self.now = now
        self.refreshInterval = refreshInterval
    }

    convenience init(
        modelContext: ModelContext,
        now: @escaping () -> Date = Date.init,
        refreshInterval: TimeInterval = 60 * 60 * 24 * 30
    ) {
        self.init(
            modelContext: modelContext,
            offClient: OpenFoodFactsClient(),
            now: now,
            refreshInterval: refreshInterval
        )
    }

    func lookupByBarcode(_ barcode: String) async throws -> OfficialFood? {
        let normalized = OFFProductDTO.normalizeBarcode(barcode)
        guard !normalized.isEmpty else { return nil }

        let localByBarcode = fetchByBarcode(normalized)
        if let localByBarcode, !isStale(localByBarcode) {
            return localByBarcode
        }

        let remoteDTO: OFFProductDTO?
        do {
            remoteDTO = try await offClient.fetchProduct(barcode: normalized)
        } catch {
            return localByBarcode
        }

        guard let dto = remoteDTO else {
            return localByBarcode
        }

        let saved = upsert(dto)
        try modelContext.save()
        return saved
    }

    func searchByText(_ query: String, limit: Int = 20) async throws -> [OfficialFood] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let remoteResults = try await offClient.searchProducts(query: trimmedQuery, limit: max(limit, 1))
        if remoteResults.isEmpty {
            return searchLocalByText(trimmedQuery, limit: limit)
        }

        var seenFoodIds = Set<UUID>()
        var resolvedFoods: [OfficialFood] = []
        resolvedFoods.reserveCapacity(remoteResults.count)

        for dto in remoteResults {
            let upserted = upsert(dto)
            if seenFoodIds.insert(upserted.id).inserted {
                resolvedFoods.append(upserted)
            }
        }

        try modelContext.save()
        return resolvedFoods
    }

    func isStale(_ food: OfficialFood) -> Bool {
        now().timeIntervalSince(food.lastSyncedAt) > refreshInterval
    }

    func upsert(_ dto: OFFProductDTO) -> OfficialFood {
        let existingByFdc = fetchByFdcId(dto.surrogateId)
        let existingByBarcode = fetchByBarcode(dto.code)

        let target: OfficialFood
        if let existingByFdc {
            target = existingByFdc
            if let existingByBarcode, existingByBarcode !== existingByFdc {
                modelContext.delete(existingByBarcode)
            }
        } else if let existingByBarcode {
            target = existingByBarcode
        } else {
            let created = OfficialFood(fdcId: dto.surrogateId, gtinUpc: dto.code, name: dto.name)
            modelContext.insert(created)
            target = created
        }

        apply(dto, to: target)
        return target
    }

    private func apply(_ dto: OFFProductDTO, to food: OfficialFood) {
        food.fdcId = dto.surrogateId
        food.gtinUpc = dto.code
        food.name = dto.name
        food.brandOwner = dto.brandOwner
        food.servingSize = dto.servingSize
        food.servingUnit = dto.servingUnit
        food.calories = dto.calories
        food.protein = dto.protein
        food.carbohydrates = dto.carbohydrates
        food.fat = dto.fat
        food.fiber = dto.fiber
        food.sugar = dto.sugar
        food.sodium = dto.sodium
        food.potassium = dto.potassium
        food.calcium = dto.calcium
        food.iron = dto.iron
        food.vitaminC = dto.vitaminC
        food.vitaminD = dto.vitaminD
        food.lastSyncedAt = now()
        food.updatedAt = now()
    }

    private func fetchByBarcode(_ barcode: String) -> OfficialFood? {
        let descriptor = FetchDescriptor<OfficialFood>(
            predicate: #Predicate<OfficialFood> { item in
                item.gtinUpc == barcode
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchByFdcId(_ fdcId: Int) -> OfficialFood? {
        let descriptor = FetchDescriptor<OfficialFood>(
            predicate: #Predicate<OfficialFood> { item in
                item.fdcId == fdcId
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func searchLocalByText(_ query: String, limit: Int) -> [OfficialFood] {
        let lowered = query.lowercased()
        var descriptor = FetchDescriptor<OfficialFood>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = max(limit * 5, 100)
        let bounded = (try? modelContext.fetch(descriptor)) ?? []

        return bounded.filter {
            $0.name.lowercased().contains(lowered) ||
            ($0.brandOwner?.lowercased().contains(lowered) ?? false) ||
            $0.gtinUpc.contains(lowered)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        .prefix(max(limit, 1))
        .map { $0 }
    }
}
