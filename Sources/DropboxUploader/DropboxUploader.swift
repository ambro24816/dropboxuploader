import AsyncHTTPClient
import NIOHTTP1
import NIOCore
import NIOFoundationCompat
import Foundation

public struct DropboxUploader {
    public init(refreshToken: String, clientId: String, clientSecret: String) {
        self.refreshToken = refreshToken
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    public func upload(path: String, data: Data) async throws {
        let params = UploadParams(path: path)
        let paramsData = try JSONEncoder().encode(params)
        
        let accessToken = try await token()
        
        var headers = HTTPHeaders()
        headers.add(
            name: "Authorization",
            value: "Bearer \(accessToken)")
        headers.add(
            name: "Dropbox-API-Arg",
            value: String(data: paramsData, encoding: .utf8)!)
        headers.add(
            name: "Content-Type",
            value: "application/octet-stream")
        
        var request = HTTPClientRequest(url: "https://content.dropboxapi.com/2/files/upload")
        request.headers = headers
        request.method = .POST
        request.body = .bytes(.init(data: data))
        
        let client = HTTPClient(eventLoopGroupProvider: .createNew)
        let response = try await client.execute(request, timeout: .minutes(3))
        let data = try await response.body.collect(upTo: 1024 * 1024)
        
        try await client.shutdown()
        
        guard response.status.code == 200 else {
            throw DropboxUploaderError.unexpected(String(buffer: data))
        }
    }
    
    private let refreshToken: String
    private let clientId: String
    private let clientSecret: String

    private func token() async throws -> String {
        let params = "client_id=\(clientId)&client_secret=\(clientSecret)&refresh_token=\(refreshToken)&grant_type=refresh_token"
        guard let paramsData = params.data(using: .utf8) else {
            throw DropboxUploaderError.invalidTokenParams
        }
        
        var headers = HTTPHeaders()
        headers.add(
            name: "Content-Type",
            value: "application/x-www-form-urlencoded; charset=utf-8")
        
        var request = HTTPClientRequest(url: "https://api.dropbox.com/oauth2/token")
        request.headers = headers
        request.method = .POST
        request.body = .bytes(ByteBuffer(data: paramsData))
        
        let client = HTTPClient(eventLoopGroupProvider: .createNew)
        let response = try await client.execute(request, timeout: .minutes(3))
        let data = try await response.body.collect(upTo: 1024 * 1024)
        
        try await client.shutdown()
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let tokenResponse = try decoder.decode(TokenResponse.self, from: data)
        
        return tokenResponse.accessToken
    }

    private struct UploadParams: Codable {
        let path: String
    }
    
    private struct TokenResponse: Decodable {
        let accessToken: String
    }
}

enum DropboxUploaderError: Error {
    case invalidTokenParams
    case unexpected(String)
}
