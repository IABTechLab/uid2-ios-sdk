//
//  HTTPStub.swift
//
//
//  Created by Dave Snabel-Caunt on 18/04/2024.
//

import Foundation

public final class HTTPStub {
    public static let shared: HTTPStub = {
        let stub = HTTPStub()
        URLProtocol.registerClass(HTTPStubProtocol.self)
        return stub
    }()

    private init() {}

    // Provides stubs in response to requests
    public var stubs: ((URLRequest) -> Result<(data: Data, response: HTTPURLResponse), Error>)!

    // Stub for the current request
    private var stub: Result<(data: Data, response: HTTPURLResponse), Error>!

    private class HTTPStubProtocol: URLProtocol {
        private var isCancelled = false

        override class func canInit(with: URLRequest) -> Bool {
            true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            // Set the active stub
            HTTPStub.shared.stub = HTTPStub.shared.stubs(request)
            return request
        }

        override func startLoading() {
            let stub = HTTPStub.shared.stub!

            let queue = DispatchQueue.global(qos: .default)
            queue.asyncAfter(deadline: .now() + 0.01) {
                guard !self.isCancelled, let client = self.client else {
                    return
                }

                switch stub {
                case .success(let (data, response)):
                    client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client.urlProtocol(self, didLoad: data)
                case .failure(let error):
                    client.urlProtocol(self, didFailWithError: error)
                }

                client.urlProtocolDidFinishLoading(self)
            }
        }

        override func stopLoading() {
            isCancelled = true
        }
    }
}

internal extension HTTPURLResponse {
    convenience init(
        url: URL,
        statusCode: Int = 200,
        httpVersion: String = "1.1",
        headerFields: [String:String]? = nil
    ) {
        self.init(
            url: url,
            statusCode: statusCode,
            httpVersion: "1.1",
            headerFields: nil
        )!
    }
}

struct MissingFixtureError: Error, LocalizedError {
    var url: URL

    var errorDescription: String? {
        "No stub registered for path \(url.path)"
    }
}
