import UIKit

/// Extracts and fires the GAM click URL for a Bid.
/// Caches the extracted URL so extraction only happens once per bid.
@objcMembers
public class NativoGAMClickFetcher: NSObject {

    /// Extract (or use cached) click URL from the bid's proxy banner, then fire it.
    public static func extractAndFire(for bid: Bid) {
        if let url = bid.gamClickURL {
            Log.debug("NativoGAMClickFetcher: Using cached click URL")
            fire(url: url)
            return
        }

        guard let bannerView = bid.gamProxyBannerView else {
            Log.debug("NativoGAMClickFetcher: No proxy banner view on bid")
            return
        }

        NativoGAMClickExtractor.extractClickURL(from: bannerView) { url in
            guard let url = url else {
                Log.debug("NativoGAMClickFetcher: No click URL found")
                return
            }
            bid.gamClickURL = url
            Log.debug("NativoGAMClickFetcher: Extracted and firing click URL")
            fire(url: url)
        }
    }

    private static func fire(url: URL) {
        let delegate = NoRedirectDelegate()
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)

        session.dataTask(with: url) { _, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            Log.debug("NativoGAMClickFetcher: Fired — status: \(status)")
            session.invalidateAndCancel()
        }.resume()
    }
}

private class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
