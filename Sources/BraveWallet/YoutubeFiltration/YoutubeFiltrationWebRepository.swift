//
//  YoutubeFiltrationWebRepository.swift
//  
//
//  Created by Cem Sertkaya on 23.03.2023.
//

import Foundation

public class YoutubeFiltrationWebRepository {
    
    public static var shared = YoutubeFiltrationWebRepository()
    
    func authSession(email: String, name: String, completion: @escaping ([String: String]?, Error?) -> Void) {
        register(email: email, name: name) { dict, error in
            if error != nil {
                self.login(email: email) { dict, error in
                    if let dict = dict {
                        completion(dict, nil)
                    } else {
                        completion(nil, nil)
                    }
                }
            } else if let dict = dict {
                completion(dict, nil)
            } else { // The email has already been taken.
                self.login(email: email) { dict, error in
                    if let dict = dict {
                        completion(dict, nil)
                    } else {
                        completion(nil, nil)
                    }
                }
            }
        }
    }
    
    func login(email: String, name: String? = nil, completion: @escaping ([String: String]?, Error?) -> Void) {
        let parameters = ["email": email]
        let url = URL(string: "https://api.kahf.ai/api/v1/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            do {
                if let dataDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    var responseDict = [String: String]()
                    if let token = dataDict["token"] as? String {
                        responseDict["token"] = token
                        if let data = dataDict["data"] as? [String: Any] {
                            if let name = data["name"] as? String {
                                responseDict["name"] = name
                            }
                            if let email = data["email"] as? String {
                                responseDict["email"] = email
                            }
                        }
                        completion(responseDict, nil)
                    } else {
                        completion(nil, nil)
                    }
                } else {
                    completion(nil, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    func register(email: String, name: String? = nil, completion: @escaping ([String: String]?, Error?) -> Void) {
        let parameters = ["email": email, "name": name]
        let url = URL(string: "https://api.kahf.ai/api/v1/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            do {
                if let dataDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    var responseDict = [String: String]()
                    if let token = dataDict["token"] as? String {
                        responseDict["token"] = token
                        if let data = dataDict["data"] as? [String: Any] {
                            if let name = data["name"] as? String {
                                responseDict["name"] = name
                            }
                            if let email = data["email"] as? String {
                                responseDict["email"] = email
                            }
                        }
                        completion(responseDict, nil)
                    } else {
                        completion(nil, nil)
                    }
                } else {
                    completion(nil, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
}
