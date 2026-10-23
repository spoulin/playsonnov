import SwiftUI

@main
struct SonnovApp: App {
    @StateObject private var player = Player()

    var body: some Scene {
        MenuBarExtra {
            VStack(spacing: 10) {
                // Fixed-size slot: the menu bar window does not reliably resize with its content.
                ZStack {
                    RoundedRectangle(cornerRadius: 6).fill(.quaternary)
                    if let url = player.artURL {
                        AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { Color.clear }
                    }
                }
                .frame(width: 192, height: 192)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                HStack(spacing: 22) {
                    Button { player.nextAlbum() } label: {
                        Image(systemName: "shuffle").font(.system(size: 18))
                    }
                    .help("Random album")

                    Button { player.toggle() } label: {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                    }

                    Button { player.nextTrack() } label: {
                        Image(systemName: "forward.fill").font(.system(size: 18))
                    }
                    .help("Next track")
                    .disabled(player.nowPlaying == nil)
                }
                .buttonStyle(.plain)
                .disabled(player.isLoading)

                Group {
                    if player.isLoading {
                        Text("Loading…")
                    } else if player.failed {
                        Text("Couldn't reach Bandcamp").foregroundStyle(.red)
                    } else {
                        Text(player.nowPlaying ?? " ")
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)

                Divider()
                HStack {
                    Button("Open on Bandcamp") {
                        if let url = player.pageURL { NSWorkspace.shared.open(url) }
                    }
                    .disabled(player.pageURL == nil)
                    Spacer()
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                }
                .buttonStyle(.plain).font(.caption)
            }
            .padding(14)
            .frame(width: 220)
        } label: {
            Image(systemName: player.isPlaying ? "waveform" : "play.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
