//
//  StoreKitManager.swift
//  Linkeeper
//
//  Created by Om Chachad on 28/06/23.
//

import Foundation
import StoreKit

typealias Transaction = StoreKit.Transaction
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

public enum StoreError: Error {
    case failedVerification
}

class Store: ObservableObject {
    static let shared = Store()
    
    @Published private(set) var tippableProducts: [Product]
    
    @Published private(set) var tippedProducts: [Product] = []
    
    var updateListenerTask: Task<Void, Error>? = nil

    private let productIdToEmoji: [String: String]

    init() {
        productIdToEmoji = Store.loadProductIdToEmojiData()

        //Initialize empty products, and then do a product request asynchronously to fill them in.
        tippableProducts = []

        //Start a transaction listener as close to app launch as possible so you don't miss any transactions.
        updateListenerTask = listenForTransactions()

        Task {
            //During store initialization, request products from the App Store.
            await requestProducts()

            //Deliver products that the customer purchases.
            await updateCustomerProductStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }
    
    var userHasTipped: Bool {
        !tippedProducts.isEmpty
    }
    
    static func loadProductIdToEmojiData() -> [String: String] {
        guard let path = Bundle.main.path(forResource: "Tips", ofType: "plist"),
              let plist = FileManager.default.contents(atPath: path),
              let data = try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String] else {
            return [:]
        }
        return data
    }

    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    //Deliver products to the user.
                    await self.updateCustomerProductStatus()

                    //Always finish a transaction.
                    await transaction.finish()
                } catch {
                    //StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }

    @MainActor
    func requestProducts() async {
        do {
            //Request products from the App Store using the identifiers that the Products.plist file defines.
            let storeProducts = try await Product.products(for: productIdToEmoji.keys)
            
            tippableProducts = sortByPrice(storeProducts)
        } catch {
            print("Failed product request from the App Store server: \(error)")
        }
    }
    
    @available(visionOS, introduced: 1.0, unavailable)
    func purchase(_ product: Product) async throws -> Transaction? {
        //Begin purchasing the `Product` the user selects.
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            //Check whether the transaction is verified. If it isn't,
            //this function rethrows the verification error.
            let transaction = try checkVerified(verification)

            //The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()

            //Always finish a transaction.
            await transaction.finish()

            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }

    func isPurchased(_ product: Product) -> Bool {
        //Determine whether the user purchases a given product.
        tippedProducts.contains(product)
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            //The result is verified. Return the unwrapped value.
            return safe
        }
    }

    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedTips: [Product] = []

        //Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                //Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)
                if let tip = tippableProducts.first(where: { $0.id == transaction.productID }) {
                    purchasedTips.append(tip)
                }
                
            } catch {
                print()
            }
        }

        //Update the store information with the purchased products.
        self.tippedProducts = purchasedTips
    }

    func emoji(for productId: String) -> String {
        return productIdToEmoji[productId]!
    }

    func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted(by: { return $0.price < $1.price })
    }
}

