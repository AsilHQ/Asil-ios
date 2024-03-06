//
//  Api.swift
//  KahfDNS InstantConnect
//
//  Created by Mehdi with ♥ / hi@mehssi.com
//

import Foundation

// resposne structs
struct ResponseTotalBlacklistHosts: Codable {
    let total: String // it can be 'N/A' that's why we can't cast to int/int64
    let lastUpdated: String
}

public struct ResponseBanners: Codable {
    let osxBottom: Banner
}
public struct Banner: Codable {
    let image: String
    let link: String
}

public class KahfDNSApi {
    struct ApiDetailsStruct {
        let urlGetTotalBlacklistHosts: String
        let urlGetBanners: String
    }
    
    let apiDetails = ApiDetailsStruct(
        urlGetTotalBlacklistHosts: "https://api.kahfdns.com/totalBlacklistHosts",
        urlGetBanners: "https://adm.kahfdns.com/Public/App_Banners/banners.json"
    )
    
    /**
        completion: (success: Bool, errorMessage: String?, total: String = "0")
     */
    public func getTotalBlacklistHosts(completion: @escaping (_ success: Bool, _ errorMessage: String?, _ total: String) -> Void) {
        let url = URL(string: apiDetails.urlGetTotalBlacklistHosts)!
        print("Api: getTotalBlacklistHosts: \(url)")

        URLSession.shared.dataTask(with: url) { data, _, error  in
            do {
                if error != nil {
                    print("Api: getTotalBlacklistHosts: Error: \(error!.localizedDescription)")
                    completion(false, error!.localizedDescription, "0")
                } else if data == nil {
                    print("Api: getTotalBlacklistHosts: Error: No data")
                    completion(false, "No data from API.", "0")
                } else {
                    let json = try JSONDecoder().decode(ResponseTotalBlacklistHosts.self, from: data!)
                    
                    // send to main queue so ui can be updated.
                    DispatchQueue.main.async {
                        print("Api: getTotalBlacklistHosts: Results")
                        print(json)
                        
                        let total: Int64? = Int64(json.total)
                        completion(true, nil, total?.formatted() ?? "N/A")
                    }
                }
            } catch {
                print("Api: getTotalBlacklistHosts: Exception:")
                print(error)
                completion(false, error.localizedDescription, "0")
            }
        }
        .resume()
    }
    
    /**
        completion: (success: Bool, errorMessage: String?, total: String = "0")
     */
    public func getBottomBanner(completion: @escaping (_ success: Bool, _ errorMessage: String?, _ banner: Banner?) -> Void) {
        let url = URL(string: apiDetails.urlGetBanners)!
        print("Api: getBanners: \(url)")

        URLSession.shared.dataTask(with: url) { data, _, error  in
            do {
                if error != nil {
                    print("Api: getBanners: Error: \(error!.localizedDescription)")
                    completion(false, error!.localizedDescription, nil)
                } else if data == nil {
                    print("Api: getBanners: Error: No data")
                    completion(false, "No data from API.", nil)
                } else {
                    let json = try JSONDecoder().decode(ResponseBanners.self, from: data!)
                    
                    // send to main queue so ui can be updated.
                    DispatchQueue.main.async {
                        print("Api: getBanners: Results")
                        print(json)
                        
                        completion(true, nil, json.osxBottom)
                    }
                }
            } catch {
                print("Api: getBanners: Exception:")
                print(error)
                completion(false, error.localizedDescription, nil)
            }
        }
        .resume()
    }
}
