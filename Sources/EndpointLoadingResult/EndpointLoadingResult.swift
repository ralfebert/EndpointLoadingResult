// MIT License
//
// Copyright (c) 2020 Ralf Ebert
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Combine
@_exported import Endpoint
import os
import SwiftUI

public enum LoadingResult<T> {
    case empty
    case loading(Cancellable)
    case loaded(T)
    case error(Error)

    public var value: T? {
        switch self {
            case let .loaded(value):
                return value
            default:
                return nil
        }
    }

    public var isLoading: Bool {
        switch self {
            case .loading:
                return true
            default:
                return false
        }
    }

    public var isError: Bool {
        switch self {
            case .error:
                return true
            default:
                return false
        }
    }
}

public extension Binding {

    init<A>(keyPath: ReferenceWritableKeyPath<A, Value>, on obj: A) {
        self.init(
            get: { obj[keyPath: keyPath] },
            set: { obj[keyPath: keyPath] = $0 }
        )
    }
}

public extension Endpoint {

    func load(result: Binding<LoadingResult<A>>) {
        assert(Thread.isMainThread)
        if case .loading = result.wrappedValue {
            os_log("Already loading: %s", log: EndpointLogging.log, type: .debug, String(describing: self))
            return
        }
        result.wrappedValue = .loading(
            self.load()
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .finished:
                                break
                            case let .failure(error):
                                result.wrappedValue = .error(error)
                        }
                    },
                    receiveValue: { value in
                        result.wrappedValue = .loaded(value)
                    }
                ))
    }

}
