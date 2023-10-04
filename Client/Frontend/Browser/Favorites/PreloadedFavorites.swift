/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import BraveShared
import os.log

typealias FavoriteSite = (url: URL, title: String)

struct PreloadedFavorites {
  /// Returns a list of websites that should be preloaded for specific region. Currently all users get the same websites.
  static func getList() -> [FavoriteSite] {
    func appendPopularEnglishWebsites() -> [FavoriteSite] {
      var list = [FavoriteSite]()

      if let url = URL(string: "https://quran.com/") {
        list.append(FavoriteSite(url: url, title: "Quran"))
      }

      if let url = URL(string: "https://iou.edu.gm/") {
        list.append(FavoriteSite(url: url, title: "IEO"))
      }

      if let url = URL(string: "https://islamqa.info/en") {
        list.append(FavoriteSite(url: url, title: "Islamqa"))
      }

      if let url = URL(string: "https://www.youtube.com/") {
        list.append(FavoriteSite(url: url, title: "Youtube"))
      }

      if let url = URL(string: "https://www.wikipedia.org/") {
        list.append(FavoriteSite(url: url, title: "Wikipedia"))
      }
      return list
    }

      func appendPopularBangladeshWebsites() -> [FavoriteSite] {
        var list = [FavoriteSite]()

        if let url = URL(string: "https://www.rokomari.com/") {
          list.append(FavoriteSite(url: url, title: "Rokomari"))
        }

        if let url = URL(string: "https://quran.com/") {
          list.append(FavoriteSite(url: url, title: "Quran"))
        }

        if let url = URL(string: "https://iou.edu.gm/") {
          list.append(FavoriteSite(url: url, title: "IEO"))
        }

        if let url = URL(string: "https://www.youtube.com/") {
          list.append(FavoriteSite(url: url, title: "Youtube"))
        }

        if let url = URL(string: "https://www.wafilife.com/") {
          list.append(FavoriteSite(url: url, title: "Wafilife"))
        }
        return list
    }
      
    var preloadedFavorites = [FavoriteSite]()

    // Locale consists of language and region, region makes more sense when it comes to setting preloaded websites imo.
    let region = Locale.current.regionCode ?? ""  // Empty string will go to the default switch case
    Logger.module.debug("Preloading favorites, current region: \(region)")

    switch region {
    case "PL":
      // We don't do any per region preloaded favorites at the moment.
      // But if we would like to, it is as easy as adding a region switch case and adding websites to the list.

      // try? list.append(FavoriteSite(url: "https://allegro.pl/".asURL(), title: "Allegro"))
      preloadedFavorites += appendPopularEnglishWebsites()
      break
    case "BD":
      preloadedFavorites += appendPopularBangladeshWebsites()
    default:
      preloadedFavorites += appendPopularEnglishWebsites()
    }
    return preloadedFavorites
  }
}
