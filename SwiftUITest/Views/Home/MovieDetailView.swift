//
//  MovieDetailView.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import SwiftUI

struct MovieDetailView: View {
    let id: Int
    @State private var viewModel : MovieDetailViewModel
    @Environment(\.openURL) private var openURL

    init(id: Int) {
        self.id = id
        _viewModel = State(initialValue: MovieDetailViewModel(id: id))

    }

    var body: some View {
           Group {
               if let message = viewModel.error, viewModel.movie == nil {
                   // EMPTY / ERROR STATE: no data and no cached copy
                   ContentUnavailableView {
                       Label("Couldn't load movie", systemImage: "wifi.slash")
                   } description: {
                       Text(message)
                   } actions: {
                       AppButton("Retry", fullWidth: false) {
                           viewModel.error = nil                // switches back to the skeleton
                           viewModel.load(id: id)
                       }
                   }
               } else {
                   content
                       // LOADING STATE: skeleton while movie is nil
                       .redacted(reason: viewModel.movie == nil ? .placeholder : [])
                       .allowsHitTesting(viewModel.movie != nil)
               }
           }
           .screenBackground()                                  // replaces .bgColor(.bg), fills the safe area
           .navigationBarTitleDisplayMode(.inline)              // no title is set, so .large left a blank gap
           .onFirstAppear { viewModel.load(id: id) }            // single fetch (see note below)
           .toolbar {
               if let movie = viewModel.movie {
                   ToolbarItem(placement: .topBarTrailing) {
                       let isFav = DatabaseManager.shared.isFavourite(movie.id)
                       Button {
                           Haptic.impact()
                           DatabaseManager.shared.toggleFavourite(movie)
                       } label: {
                           Image(systemName: isFav ? "heart.fill" : "heart")
                               .foregroundStyle(isFav ? Color.red : AppColor.brand.color)
                       }
                   }
               }
           }
       }

       // Your original ScrollView, moved here so body can switch between the three states
       private var content: some View {
           ScrollView {
               VStack(alignment: .leading, spacing: 16) {      // NEW: left-aligns and spaces the children
                   AsyncImage(url: viewModel.movie?.backdropURL) { image in
                       image
                           .resizable()
                           .scaledToFill()
                           .frame(maxWidth: .infinity, minHeight: 200)
                   } placeholder: {
                       Rectangle()                              // grey block reads better as a skeleton than a spinner
                           .foreground(.border)
                           .frame(maxWidth: .infinity, minHeight: 200)
                   }

                   basicDetail

                   if let tagline = viewModel.movie?.tagline, !tagline.isEmpty {
                       Text("“\(tagline)”").font(.medium, 14).italic().foreground(.textSecondary)
                   }

                   if let key = viewModel.movie?.trailerKey,
                      let url = URL(string: "https://www.youtube.com/watch?v=\(key)") {
                       AppButton("Watch Trailer", kind: .secondary, icon: "play.fill") { openURL(url) }
                   }

                   // show while loading (placeholder text) or when the movie has an overview
                   if viewModel.movie == nil || !(viewModel.movie?.overview ?? "").isEmpty { OverView }

                   if let cast = viewModel.movie?.credits?.cast, !cast.isEmpty { castRow(cast) }
               }
               .padding(.md)
           }
       }
}

#Preview {
    MovieDetailView(id: 10)
}


//MARK: - Genre section

extension MovieDetailView {
    private var basicDetail : some View {
        VStack(alignment: .leading,spacing: 12  ) {

            Text(viewModel.movie?.title ?? "Movie Title")
                .font(.bold,26)
                .foreground(.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(1)

            HStack(spacing: 8) {
                Text("(\(viewModel.movie?.year ?? "Year"))")
                    .font(.regular,12)
                    .foreground(.textSecondary)

                Image(systemName: "star.fill")
                    .font(Font.caption)
                    .foreground(.textSecondary)

                Text("\(viewModel.movie?.rating ?? "Rating")")
                    .font(.regular,12)
                    .foreground(.textSecondary)


            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(viewModel.movie?.genres ?? [], id: \.self) { genre in
                        Text(genre.name)
                            .font(.regular,12)
                            .foreground(.brand)
                            .padding()
                            .bgColor(.border)
                            .clipShape(.capsule)
                    }
                }
            }
        }
    }
}
//MARK: - OverView
extension MovieDetailView {
    private var OverView : some View {

        VStack(alignment: .leading) {
            Text( "OverView")
                .font(.semibold,16)
                .foreground(.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(1)

            Text( "\(viewModel.movie?.overview ?? "Movie Overview")")
                .font(.regular,13)
                .foreground(.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)

        }


    }
}


//MARK: - CastView
extension MovieDetailView {
    private func castRow(_ cast: [Cast]) -> some View {

        VStack(alignment: .leading, spacing: 12) {
            Text( "Cast")
                .font(.semibold,16)
                .foreground(.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(cast.prefix(15)) { member in
                        VStack(spacing: 4) {
                            Circle().fill(AppColor.surface.color)
                                .frame(width: 64, height: 64)
                                .overlay {
                                    AsyncImage(url: TMDB.image(member.profilePath, size: "w185")) { $0.resizable()
                                        .scaledToFill()
                                    }
                                    placeholder: { Image(systemName: "person.fill")
                                        .foreground(.textSecondary)
                                    }
                                }
                                .clipShape(Circle())
                            Text(member.name)
                                .font(.medium, 12)
                                .foreground(.textPrimary)
                                .lineLimit(1)
                            Text(member.character ?? "")
                                .font(.regular, 11)
                                .foreground(.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(width: 80)
                    }
                }
            }
        }
    }
}
// MARK: - Old code
extension MovieDetailView {
    //    var body: some View {
    //        ScrollView {
    //            AsyncImage(url: viewModel.movie?.backdropURL) { image in
    //                image
    //                    .resizable()
    //                    .scaledToFill()
    //                    .frame(maxWidth: .infinity, minHeight: 200)
    //                //                        .clipShape(.rect(cornerRadius: 16))
    //            } placeholder: {
    //                ProgressView()
    //                    .frame(maxWidth: .infinity, minHeight: 200)
    //            }
    //
    //            basicDetail
    //
    //            if let tagline = viewModel.movie?.tagline, !tagline.isEmpty {
    //                Text("“\(tagline)”").font(.medium, 14).italic().foreground(.textSecondary)
    //            }
    //
    //            if let key = viewModel.movie?.trailerKey, let url = URL(string: "https://www.youtube.com/watch?v=\(key)") {
    //                AppButton("Watch Trailer", kind: .secondary, icon: "play.fill") { openURL(url) }
    //            }
    //
    //
    //            if let overView = viewModel.movie?.overview, !overView.isEmpty { OverView }
    //
    //            if let cast = viewModel.movie?.credits?.cast, !cast.isEmpty { castRow(cast) }
    //
    //
    //
    //        }
    //        .padding(.md)
    //        .bgColor(.bg)
    //        .navigationBarTitleDisplayMode(.large)
    //        .toolbar {
    //            if let movie = viewModel.movie {
    //                ToolbarItem(placement: .topBarTrailing) {
    //                    let isFav = DatabaseManager.shared.isFavourite(movie.id)
    //                    Button {
    //                        Haptic.impact()
    //                        DatabaseManager.shared.toggleFavourite(movie)
    //                    } label: {
    //                        Image(systemName: isFav ? "heart.fill" : "heart")
    //                            .foregroundStyle(isFav ? Color.red : AppColor.brand.color)
    //                    }
    //                }
    //            }
    //        }
    //
    //    }
}
