//
//  Router.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import SwiftUI
import Observation

// MARK: - 1. EDIT THESE: your tabs and routes
enum AppTab: Hashable, CaseIterable {
    case home, favourite

    var title: String {
        switch self {
        case .home: "Home"
        case .favourite: "favourite"
        }
    }
    var icon: String {
        switch self {
        case .home: "house"
        case .favourite: "heart.fill"
        }
    }
}

// One enum for push, sheet and fullScreenCover.
// Associated values must be Hashable (pass IDs, not whole objects, when possible).
enum Route: Hashable, Identifiable {
    case movieList(MovieSection)
    case movieDetail(id: Int)

    var id: Self { self }   // needed for .sheet(item:)
}

// MARK: - 2. Router
@MainActor
@Observable
final class Router {
    var selectedTab: AppTab = .home
    var paths: [AppTab: NavigationPath] = [:]   // one stack per tab
    var sheetPath = NavigationPath()            // stack inside a sheet
    var fullScreenPath = NavigationPath()       // stack inside a full screen cover
    var sheet: Route?
    var fullScreen: Route?

    // MARK: Destinations (map Route -> View here, the only place you edit when adding screens)
    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case .movieList(let section):
            MovieListView(section: section)
        case .movieDetail(let id):
            MovieDetailView(id: id)
        }
    }

    // Root screen of each tab
    @ViewBuilder
    func rootView(for tab: AppTab) -> some View {
        switch tab {
        case .home: HomeView()
        case .favourite: FavouritesView()
        }
    }

    // MARK: Push / Pop (auto-targets the top-most context: fullScreen > sheet > current tab)
    func push(_ route: Route) {
        if fullScreen != nil { fullScreenPath.append(route) }
        else if sheet != nil { sheetPath.append(route) }
        else { paths[selectedTab, default: NavigationPath()].append(route) }
    }

    func pop(_ count: Int = 1) {
        if fullScreen != nil { fullScreenPath.safeRemoveLast(count) }
        else if sheet != nil { sheetPath.safeRemoveLast(count) }
        else { paths[selectedTab, default: NavigationPath()].safeRemoveLast(count) }
    }

    func popToRoot() {
        if fullScreen != nil { fullScreenPath = NavigationPath() }
        else if sheet != nil { sheetPath = NavigationPath() }
        else { paths[selectedTab] = NavigationPath() }
    }

    // MARK: Modals
    func present(sheet route: Route) { sheet = route }
    func present(fullScreen route: Route) { fullScreen = route }

    /// Dismisses the top-most modal (fullScreen first, then sheet)
    func dismiss() {
        if fullScreen != nil { fullScreen = nil }
        else if sheet != nil { sheet = nil }
    }

    func dismissAll() { fullScreen = nil; sheet = nil }

    // MARK: Tabs
    func select(_ tab: AppTab) {
        if tab == selectedTab { paths[tab] = NavigationPath() }  // tapping same tab pops to root
        selectedTab = tab
    }

    /// Deep link style: switch tab (+ optionally reset it) and push a route
    func navigate(to route: Route, in tab: AppTab, resetStack: Bool = false) {
        dismissAll()
        selectedTab = tab
        if resetStack { paths[tab] = NavigationPath() }
        paths[tab, default: NavigationPath()].append(route)
    }

    // MARK: Internal helpers used by the views
    func pathBinding(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(get: { self.paths[tab] ?? NavigationPath() },
                set: { self.paths[tab] = $0 })
    }
    func resetSheet() { sheetPath = NavigationPath() }
    func resetFullScreen() { fullScreenPath = NavigationPath() }
}

private extension NavigationPath {
    mutating func safeRemoveLast(_ k: Int) {
        guard count > 0 else { return }
        removeLast(Swift.min(k, count))
    }
}

// MARK: - 3. Per-tab stack
struct RouterStack: View {
    @Environment(Router.self) private var router
    let tab: AppTab

    var body: some View {
        NavigationStack(path: router.pathBinding(for: tab)) {
            router.rootView(for: tab)
                .navigationDestination(for: Route.self) { router.destination(for: $0) }
        }
    }
}

// MARK: - 4. Root view (TabView + sheet + fullScreenCover)
struct RootView: View {
    @State private var router = Router()

    var body: some View {
        @Bindable var b = router

        TabView(selection: Binding(get: { router.selectedTab },
                                   set: { router.select($0) })) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                RouterStack(tab: tab)
                    .tabItem { Label(tab.title, systemImage: tab.icon) }
                    .tag(tab)
            }
        }
        .sheet(item: $b.sheet, onDismiss: router.resetSheet) { route in
            NavigationStack(path: $b.sheetPath) {
                router.destination(for: route)
                    .navigationDestination(for: Route.self) { router.destination(for: $0) }
            }
            .environment(router)
        }
        .fullScreenCover(item: $b.fullScreen, onDismiss: router.resetFullScreen) { route in
            NavigationStack(path: $b.fullScreenPath) {
                router.destination(for: route)
                    .navigationDestination(for: Route.self) { router.destination(for: $0) }
            }
            .environment(router)
        }
        .environment(router)
    }
}
