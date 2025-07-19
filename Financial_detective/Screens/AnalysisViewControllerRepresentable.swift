import SwiftUI
import UIKit

struct AnalysisViewControllerRepresentable: UIViewControllerRepresentable {
    let viewModel: AnalysisViewModel

    func makeUIViewController(context: Context) -> AnalysisViewController {
        AnalysisViewController(viewModel: viewModel, client: viewModel.client)
    }

    func updateUIViewController(_ uiViewController: AnalysisViewController, context: Context) { }
}


