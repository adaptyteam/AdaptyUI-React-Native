import Foundation
import Adapty

public enum RNAUIError: Error {
    case viewNotFound(String)
    case viewAlreadyPresented(String)
    case viewPresentationError(String)
    
}

extension RNAUIError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .viewNotFound(viewId): return "AdaptyUIError.viewNotFound(\(viewId))"
        case let .viewAlreadyPresented(viewId): return "AdaptyUIError.viewAlreadyPresented(\(viewId))"
        case let .viewPresentationError(viewId): return "AdaptyUIError.viewPresentationError(\(viewId))"
        }
    }
}

extension RNAUIError: CustomAdaptyError {
    public static let errorDomain = AdaptyError.AdaptyUIErrorDomain

    public var originalError: Error? { nil }

    public var adaptyErrorCode: AdaptyError.ErrorCode {
        switch self {
        case .viewNotFound: return AdaptyError.ErrorCode.wrongParam
        case .viewAlreadyPresented: return AdaptyError.ErrorCode.wrongParam
        case .viewPresentationError: return AdaptyError.ErrorCode.wrongParam
        }
    }

    public var errorCode: Int { adaptyErrorCode.rawValue }

    public var errorUserInfo: [String: Any] {
        var data: [String: Any] = [
            AdaptyError.UserInfoKey.description: debugDescription,
        ]

        if let originalError = originalError {
            data[NSUnderlyingErrorKey] = originalError as NSError
        }
        return data
    }

    public var description: String {
        switch self {
        case let .viewNotFound(viewId): return "AdaptyUIError.viewNotFound(\(viewId))"
        case let .viewAlreadyPresented(viewId): return "AdaptyUIError.viewAlreadyPresented(\(viewId))"
        case let .viewPresentationError(viewId): return "AdaptyUIError.viewPresentationError(\(viewId))"
        }
    }
}
