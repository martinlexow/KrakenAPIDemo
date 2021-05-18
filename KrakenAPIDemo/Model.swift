

import Foundation
import os.log


fileprivate let logger = Logger(subsystem: "de.martinlexow", category: "KrakenAPIModel")


final class Model: ObservableObject {
    
    
    init() {
        self.requestData()
    }
    
    
    enum CurrencyCode: String, CaseIterable {
        case Euro = "EUR"
        case Doge = "DOGE"
        case Bitcoin = "BTC"
        case Lex = "LX" // Use this to test server error response
    }
    
    
    private let currencySigns: [String : String] = {
        var signs = [String : String]()
        signs[CurrencyCode.Euro.rawValue] = "€"
        signs[CurrencyCode.Doge.rawValue] = "\u{00d0}" // Ð
        signs[CurrencyCode.Bitcoin.rawValue] = "\u{20bf}" // ₿
        return signs
    }()
    
    
    func targetCurrencySign() -> String {
        return self.currencySigns[self.rightHandedCurrency.rawValue] ?? "???"
    }
    
    
    @Published var leftHandedCurrency: CurrencyCode = .Doge {
        didSet {
            self.requestData()
        }
    }
    
    
    @Published var rightHandedCurrency: CurrencyCode = .Euro {
        didSet {
            self.requestData()
        }
    }
    
    
    @Published var askPrice: String = "—"
    
    @Published var serverStatusCode: Int = 0
    @Published var serverResponseString: String = ""
    @Published var errorMessage: String = "" {
        didSet {
            self.askPrice = "—"
        }
    }
    
    
    func requestData() {
        
        // https://support.kraken.com/hc/en-us/articles/360000920306-Ticker-pairs
        
        let pair = "\(self.leftHandedCurrency.rawValue)\(self.rightHandedCurrency.rawValue)"
        let urlString = "https://api.kraken.com/0/public/Ticker?pair=\(pair)"
        guard let requestURL = URL(string: urlString) else {
            logger.fault("Unable to make 'requestURL' with String: '\(urlString)'")
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            // Server Response
            if let r = response as? HTTPURLResponse {
                DispatchQueue.main.sync {
                    self.serverStatusCode = r.statusCode
                }
            }
            
            // Interpret Data
            if let d = data {
                
                DispatchQueue.main.sync {
                    self.serverResponseString = String(data: d, encoding: .utf8) ?? ""
                }
                
                let decoder = JSONDecoder()
                do {
                    let krakenResponse = try decoder.decode(KrakenResponse.self, from: d)
                    
                    DispatchQueue.main.sync {
                        
                        if let errors = krakenResponse.error {
                            self.errorMessage = ""
                            if errors.count > 0 {
                                for e in errors {
                                    self.errorMessage += e
                                }
                                return
                            }
                        }
                        
                        if let a = krakenResponse.result?.XDGEUR?.a?.first {
                            self.askPrice = a
                            return
                        }
                        
                        if let a = krakenResponse.result?.XXDGXXBT?.a?.first {
                            self.askPrice = a
                            return
                        }
                        
                        if let a = krakenResponse.result?.XXBTZEUR?.a?.first {
                            self.askPrice = a
                            return
                        }
                        
                        self.askPrice = "—"
                        
                    }
                    
                } catch {
                    DispatchQueue.main.sync {
                        self.errorMessage = error.localizedDescription
                    }
                }
                
            }
            
            // Error
            if let e = error {
                self.errorMessage = e.localizedDescription
            }
            
        }
        task.resume()
    }
    
    
    // MARK: - Kraken Response
    struct KrakenResponse: Decodable {
        
        var error: [String]?
        
        var result: result?
        struct result: Decodable {
            
            var XDGEUR: PairResponse? // DOGE EUR
            var XXDGXXBT: PairResponse? // DOGE BTC
            var XXBTZEUR: PairResponse? // BTC EUR
            
            struct PairResponse: Decodable {
                var a: [String]?
                var b: [String]?
            }
            
        }
    }
    
    
    
}
