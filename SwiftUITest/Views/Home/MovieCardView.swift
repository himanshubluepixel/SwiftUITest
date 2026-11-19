//
//  MovieCardView.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import SwiftUI

struct MovieCard: View {
    @Environment(Router.self) private var router
    let movie: Movie

    var body: some View {
        // Reading favouriteIDs inside body means every card updates live when any heart is tapped
        let isFav = DatabaseManager.shared.isFavourite(movie.id)

        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16).foreground(.textSecondary)

                AsyncImage(url: movie.posterURL) { image in      // posterURL, since backdrop is landscape and gets cropped
                    image.resizable().scaledToFill()
                        .frame(width: 150, height: 200)
                        .clipShape(.rect(cornerRadius: 16))
                } placeholder: {
                    ProgressView().frame(width: 150, height: 200)
                }

                Button {
                    Haptic.impact()
                    DatabaseManager.shared.toggleFavourite(movie)   // saves or removes the JSON in SwiftData
                } label: {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .resizable().scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(isFav ? Color.red : AppColor.brand.color)
                        .padding(8)
                        .background { Capsule().foreground(.border) }
                        .padding(.top, 4).padding(.trailing, 4)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 150, height: 200)

            Text(movie.title).font(.medium, 16).foreground(.textPrimary).lineLimit(1)

            HStack {
                Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
                Text(movie.rating).font(.regular, 12).foreground(.textSecondary)
                Text("(\(movie.year))").font(.regular, 12).foreground(.textSecondary)
            }
        }
        .frame(width: 150)
        .contentShape(Rectangle())
        .onTapGesture { router.push(.movieDetail(id: movie.id)) }   // Grid had no navigation before
    }
}

struct MovieGrid: View {
    let movies: [Movie]
    var isLoading = false
    var onLastAppear: (() -> Void)? = nil
    private let cols = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: cols, spacing: 16) {
                ForEach(movies) { m in
                    MovieCard(movie: m)
                        .onAppear { if m.id == movies.last?.id { onLastAppear?() } }
                }
            }
            .padding(.md)
            if isLoading { ProgressView().padding(.md) }
        }
    }

}
