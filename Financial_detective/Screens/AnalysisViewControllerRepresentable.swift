import SwiftUI
import UIKit

struct AnalysisViewControllerRepresentable: UIViewControllerRepresentable {
    let viewModel: AnalysisViewModel
    @EnvironmentObject var store: TransactionsServiceHolder

    func makeUIViewController(context: Context) -> AnalysisViewController {
        let vc = AnalysisViewController(
            viewModel: viewModel,
            client: store.client,
            transactionsService: store.service,
            categoriesService: store.categoriesService,
            bankAccountsService: store.bankAccountsService,
            accountId: store.accountId
        )
        return vc
    }

    func updateUIViewController(_ uiViewController: AnalysisViewController, context: Context) {}
}
