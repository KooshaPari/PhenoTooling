// Phinbox — Root View

import SwiftUI

struct RootView: View {
    @ObservedObject var mgr: InboxManager
    @State private var appeared = false

    var body: some View {
        Group {
            if !appeared { splash } else { mainContent }
        }
        .onAppear { appeared = true }
    }

    private var splash: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            VStack(spacing: 20) {
                EnvelopeIcon(size: 40)
                Text("Phinbox").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("Connecting to daemon...").font(.subheadline).foregroundStyle(.white.opacity(0.5))
                ProgressView().tint(Color.teal)
            }
        }
    }

    private var mainContent: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let r = mgr.selected { DetailView(request: r, mgr: mgr) }
            else {
                VStack(spacing: 16) {
                    EnvelopeIcon(size: 48).opacity(0.3)
                    Text("Select a request").font(.title3).foregroundStyle(.white.opacity(0.5))
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.appBG)
            }
        }
        .background(Color.appBG.ignoresSafeArea())
        .tint(Color.teal)
    }

    private var sidebar: some View {
        Group {
            if mgr.requests.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    EnvelopeIcon(size: 48).opacity(0.3)
                    Text("Inbox Empty").font(.title2).fontWeight(.medium).foregroundStyle(.white)
                    Text("Requests from AI agents\nwill appear here.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center)
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $mgr.selected) {
                    ForEach(mgr.requests) { RowView(request: $0, mgr: mgr).tag($0) }
                }
                .listStyle(.sidebar).scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Inbox")
        .toolbar { ToolbarItem(placement: .automatic) {
            Button { mgr.refresh() } label: { Image(systemName: "arrow.clockwise") }
        }}
    }
}
