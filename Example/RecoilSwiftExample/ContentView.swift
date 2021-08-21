import SwiftUI
import RecoilSwift

struct ContentView: HookView {
//    @RecoilValue(BookShop.currentBooksSel) var currentBooks: [Book]
//    @RecoilValue(BookShop.fetchRemoteBookNames) var bookNames: [String]?
//    @RecoilState(BookShop.allBookStore) var allBooks: [Book]
//    @RecoilState(BookShop.selectedCategoryState) var selectedCategoryState: BookCategory?

    var hookBody: some View {
        let currentBooks = useRecoilValue(BookShop.currentBooksSel)
        let allBooks = useRecoilState(BookShop.allBookStore)
        let selectedCategoryState = useRecoilState(BookShop.selectedCategoryState)
        
        let selectedCateName = selectedCategoryState.wrappedValue?.rawValue ?? "ALL"
        let bookNames = useRecoilValue(BookShop.fetchRemoteBookNamesByCategory(selectedCateName))
        
        VStack {
            HStack {
                ForEach(BookCategory.allCases, id: \.self) { category in
                    Button(category.rawValue) {
                        print(category.rawValue)
                        selectedCategoryState.wrappedValue = category
                    }.padding()
                }
            }

            ForEach(currentBooks, id: \.self) { itemView($0) }
           
            if let names = bookNames {
                ForEach(names, id: \.self) {
                    Text($0)
                }
            }
        }.padding()
         .onAppear {
             allBooks.wrappedValue = Mocks.ALL_BOOKS
         }
    }

    func itemView(_ book: Book) -> some View {
        HStack {
            Text(book.name)
            Spacer()
            Text(book.category.rawValue)
        }
        .padding()
        .background(Color.yellow)
    }
}

