import UIKit
import SwiftUI

extension AnalysisViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tx = viewModel.transactions[indexPath.row]
        
        // строим SwiftUI-вью со всеми зависимостями
        let formView = TransactionFormView(
            transaction: tx,
            direction: viewModel.direction,
            accountId: viewModel.accountId,
            transactionsService: viewModel.service,
            categoriesService: CategoriesService(client: client),
            bankAccountsService: BankAccountsService(client: client)
        )
        // оборачиваем в хостинг-контроллер
        let hosting = UIHostingController(rootView: formView)
        hosting.modalPresentationStyle = .fullScreen 
        present(hosting, animated: true)
    }
}
