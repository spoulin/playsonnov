import AVFoundation
import Foundation

@MainActor
final class Player: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var isLoading = false
    @Published private(set) var nowPlaying: String?
    @Published private(set) var artURL: URL?
    @Published private(set) var pageURL: URL?
    @Published private(set) var failed = false

    static let shared = Player()

    private let player = AVPlayer()
    private var album: Album?
    private var index = 0
    private var endObserver: NSObjectProtocol?

    init() {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.advance() }
        }
    }

    func toggle() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else if album != nil, player.currentItem != nil {
            player.play()
            isPlaying = true
        } else {
            Task { await startRandomAlbum() }
        }
    }

    func play() { if !isPlaying { toggle() } }
    func pause() { if isPlaying { toggle() } }

    func nextTrack() {
        guard album != nil else { return }
        advance()
    }

    func nextAlbum() {
        player.pause()
        Task { await startRandomAlbum() }
    }

    private func startRandomAlbum() async {
        guard !isLoading else { return }
        isLoading = true
        failed = false
        defer { isLoading = false }
        do {
            album = try await Bandcamp.randomAlbum()
            index = 0
            playCurrent()
        } catch {
            failed = true
        }
    }

    private func playCurrent() {
        guard let album, index < album.tracks.count else { return }
        let track = album.tracks[index]
        artURL = album.artURL
        pageURL = album.pageURL
        nowPlaying = "\(album.title) — \(index + 1). \(track.title)"
        player.replaceCurrentItem(with: AVPlayerItem(url: track.url))
        player.play()
        isPlaying = true
    }

    private func advance() {
        guard let album else { return }
        index += 1
        if index < album.tracks.count {
            playCurrent()
        } else {
            // Album finished: next press picks a new random album.
            self.album = nil
            player.replaceCurrentItem(with: nil)
            isPlaying = false
            nowPlaying = nil
            artURL = nil
            pageURL = nil
        }
    }
}
