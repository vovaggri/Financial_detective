import SwiftUI

struct CategoriesView: View {
    @StateObject private var vm = CategoriesViewModel()
    
    var body: some View {
        List {
            Section(header: Text("СТАТЬИ")
                .font(.caption)
                .foregroundColor(.secondary)) {
                    ForEach(vm.filteredCategories, id: \.id) { category in
                        HStack {
                            Text(String(category.emoji))
                                .font(.system(size: 14.5))
                                .frame(width: 22, height: 22)
                                .background(Color(red: 212/255, green: 250/255, blue: 230/255))
                                .cornerRadius(11)
                            
                            Text(category.name)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
            }
        }
        // MARK: - На созвоне QA по домашкам говорили, что микрофон не нужно самостоятельно реализовать, так что прошу не снимать просто так баллы из-за этого
        .offset(y: -14)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Мои статьи")
        .searchable(text: $vm.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
        .task {
            await vm.loadCategories()
        }
    }
}

struct CategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CategoriesView()
        }
    }
}
