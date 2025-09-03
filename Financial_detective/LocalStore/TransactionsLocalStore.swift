import Foundation

protocol TransactionsLocalStore {
    func all() async throws -> [Transaction]
    func replaceAll(_ items: [Transaction]) async throws
    func upsert(_ tx: Transaction) async throws
    func delete(id: Int) async throws
}

enum TransactionBackupAction: String, Codable { case create, update, delete }

struct TransactionBackupItem: Identifiable, Codable {
    let id: Int               // уникальный id транзакции (может быть временным, см. create оффлайн)
    var action: TransactionBackupAction
    var payload: Transaction? // для create/update, для delete — nil
    var updatedAt: Date
}

protocol TransactionsBackupStore {
    func pending() async throws -> [TransactionBackupItem]
    func upsert(_ item: TransactionBackupItem) async throws // коалесцирует действия по одному id
    func remove(ids: [Int]) async throws
}
