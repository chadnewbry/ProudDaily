import Foundation
import StoreKit
import SwiftData
import Observation

@Observable
final class StoreManager {
    static let shared = StoreManager()

    // MARK: - Product IDs

    static let premiumProductID = "com.openclaw.prouddaily.premium"

    // MARK: - State

    var premiumProduct: Product?
    var isPurchased: Bool = false
    var purchaseError: String?
    var isLoading: Bool = false

    // MARK: - Private

    private var transactionListener: Task<Void, Error>?

    private init() {}

    // MARK: - Setup

    func start() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await checkEntitlement()
        }
    }

    func stop() {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    @MainActor
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            premiumProduct = products.first
        } catch {
            purchaseError = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    @MainActor
    func purchase() async -> Bool {
        guard let product = premiumProduct else {
            purchaseError = "Product not available"
            return false
        }

        isLoading = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPurchased = true
                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                purchaseError = "Purchase is pending approval"
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Restore

    @MainActor
    func restore() async -> Bool {
        do {
            try await AppStore.sync()
            await checkEntitlement()
            return isPurchased
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Entitlement Check

    @MainActor
    func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID {
                isPurchased = true
                return
            }
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result,
                   transaction.productID == Self.premiumProductID {
                    await MainActor.run {
                        self.isPurchased = true
                    }
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    // MARK: - Sync to UserPreferences

    func syncPurchaseState(to preferences: UserPreferences) {
        if isPurchased && !preferences.hasPurchasedPremium {
            preferences.hasPurchasedPremium = true
        }
    }
}
