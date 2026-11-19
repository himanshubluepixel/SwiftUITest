//
//  HomeView.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(Router.self) private var router


    var body: some View {
        Group {
            if let message = viewModel.error, viewModel.sections.isEmpty {
                // ERROR / EMPTY STATE: nothing loaded and nothing cached
                ContentUnavailableView {
                    Label("Can't load movies", systemImage: "wifi.slash")
                } description: {
                    Text(message)
                } actions: {
                    AppButton("Retry", fullWidth: false) {
                        viewModel.error = nil            // back to skeleton
                        viewModel.load()
                    }
                }
            } else {
                content
            }
        }
        .screenBackground()                              // replaces .padding(.md) + .bgColor(.bg)
        .navigationTitle("Discover")                     // moved out of the VStack to the screen level
        .navigationBarTitleDisplayMode(.large)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {   // leading alignment + spacing between rows
                if viewModel.isOffline { offlineBanner }

                ForEach(MovieSection.allCases, id: \.self) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeaders(section: section)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                if let movies = viewModel.sections[section] {
                                    ForEach(movies) { MovieCard(movie: $0) }
                                } else {
                                    // LOADING STATE: skeleton cards until this row arrives
                                    ForEach(0..<4, id: \.self) { _ in skeletonCard }
                                }
                            }
                            .padding(.horizontal, .md)   // inset inside the scroll, so cards scroll edge to edge
                        }
                    }
                }
            }
            .padding(.vertical, .md)
        }
    }

}

#Preview {
    HomeView()
        .environment(Router())
}

//MARK: Views
extension HomeView {
    private func sectionHeaders(section: MovieSection) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 6)
                .frame(width: 4, height: 20)
                .foreground(.brand)

            Text("\(section.title)")
                .font(.bold, 22)
                .foreground(.textPrimary)

            Spacer()

            Button("See all") {
                router.push(.movieList(section))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .foreground(.brand)
            .background {
                Capsule().foreground(.border)
            }
        }
        .padding(.horizontal, .md)                       // header lines up with the first card
    }

    // Same size and layout as MovieCard, so nothing jumps when real data arrives
    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 16)
                .foreground(.border)
                .frame(width: 150, height: 200)

            Text("Movie title here")
                .font(.medium, 16)
                .lineLimit(1)

            Text(" 0.0 (2024)")
                .font(.regular, 12)
        }
        .frame(width: 150)
        .redacted(reason: .placeholder)                  // text becomes grey bars
        .allowsHitTesting(false)
    }

    private var offlineBanner: some View {
        Label("Showing saved data", systemImage: "wifi.slash")
            .font(.medium, 13)
            .foreground(.warning)
            .padding(.sm)
            .frame(maxWidth: .infinity)
            .background(AppColor.warning.color.opacity(0.15))
            .rounded(.sm)
            .padding(.horizontal, .md)
    }
}

extension HomeView {
//    var body: some View {
//        ScrollView {
//            VStack {
//                ForEach(MovieSection.allCases,id: \.self) { section in
//                    sectionHeaders(section: section)
//
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        LazyHStack(spacing: 12) {
//                            if let movies = self.viewModel.sections[section] {
//                                ForEach(movies) { movie in
//                                    MovieCard(movie: movie)
//
//                                }
//                            } else {
//                                ForEach(0..<4, id: \.self) { _ in emptyMovieCard() }
//                            }
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Discover")
//            .navigationBarTitleDisplayMode(.large)
//        }
//        .padding(.md)
//        .bgColor(.bg)
//    }


}
