//
//  SeasonalAnime.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import Alamofire
import Foundation

class AnilistServiceSeasonalAnime {
    
    func fetchSeasonalAnime(completion: @escaping ([Anime]?) -> Void) {
        let query = """
        query {
          Page(page: 1, perPage: 50) {
            media(season: SUMMER, seasonYear: 2024, type: ANIME, isAdult: false) {
              id
              title {
                romaji
                english
                native
              }
              coverImage {
                large
              }
            }
          }
        }
        """
        
        let parameters: [String: Any] = ["query": query]
        
        AF.request("https://graphql.anilist.co", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Response JSON: \(value)")
                    
                    if let json = value as? [String: Any],
                       let data = json["data"] as? [String: Any],
                       let page = data["Page"] as? [String: Any],
                       let media = page["media"] as? [[String: Any]] {
                        
                        let seasonalAnime: [Anime] = media.compactMap { item -> Anime? in
                            guard let id = item["id"] as? Int,
                                  let titleData = item["title"] as? [String: Any],
                                  let romaji = titleData["romaji"] as? String,
                                  let english = titleData["english"] as? String?,
                                  let native = titleData["native"] as? String?,
                                  let coverImageData = item["coverImage"] as? [String: Any],
                                  let largeImageUrl = coverImageData["large"] as? String,
                                  let imageUrl = URL(string: largeImageUrl) else {
                                return nil
                            }
                            
                            let anime = Anime(
                                id: id,
                                title: Title(romaji: romaji, english: english, native: native),
                                coverImage: CoverImage(large: imageUrl.absoluteString),
                                episodes: nil,
                                description: nil,
                                airingAt: nil
                            )
                            return anime
                        }
                        
                        completion(seasonalAnime)
                    } else {
                        print("Error parsing JSON or missing expected fields")
                        completion(nil)
                    }
                    
                case .failure(let error):
                    print("Error fetching seasonal anime: \(error.localizedDescription)")
                    completion(nil)
                }
            }
    }
}