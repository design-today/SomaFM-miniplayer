//
//  SomaAPI.swift
//
//  Copyright © 2017 Evgeny Aleksandrov. All rights reserved.

import Foundation

public extension Notification.Name {
    static let somaApiChannelsUpdated = Notification.Name("SomaAPI.Channels.Updated")
}

public struct SomaAPI {
    static var channels: [Channel]? {
        didSet {
            NotificationCenter.default.post(name: .somaApiChannelsUpdated, object: nil)
        }
    }

    static func loadChannels() {
        getChannelsFromDisk()
        loadChannelsFromAPI()
    }
}

private extension SomaAPI {
    // MARK: - Networking

    struct ChannelList: Codable {
        let channels: [Channel]
    }

    static let channelsURL = URL(string: "https://api.somafm.com/channels.json")!

    static func loadChannelsFromAPI() {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let request = URLRequest(url: channelsURL)

        session.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }

            do {
                let channelList = try JSONDecoder().decode(ChannelList.self, from: data)
                self.channels = channelList.channels
                SomaAPI.saveChannelsToDisk()
            } catch {
                print("SomaAPI: Error loading channels from API")
            }
        }.resume()
    }

    // MARK: - Persistence

    static func fileCacheURL() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("somafm_channels.json")
    }

    static func saveChannelsToDisk() {
        guard let channelsToSave = self.channels,
            let url = fileCacheURL() else { return }

        do {
            let data = try JSONEncoder().encode(channelsToSave)
            try data.write(to: url, options: [])
            UserDefaults.standard.set(1, forKey: "key")
        } catch {
            print("SomaAPI: Error saving channels to disk")
        }
    }

    static func getChannelsFromDisk() {
        guard let url = fileCacheURL() else { return }

        do {
            let data = try Data(contentsOf: url, options: [])
            let channelsToLoad = try JSONDecoder().decode([Channel].self, from: data)
            self.channels = channelsToLoad
        } catch {
            print("SomaAPI: Error loading channels from disk")
        }
    }
}
