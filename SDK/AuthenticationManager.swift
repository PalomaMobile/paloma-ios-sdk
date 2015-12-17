//
// Created by karel herink on 11/12/2015.
// Copyright (c) 2015 Paloma Mobile Ltd. All rights reserved.
//

import Foundation
import Alamofire

//XXX this code is for experimenting with 401 handling in case we don't want to use tokens that never expire

class AuthenticationManager : Manager {
    public typealias NetworkSuccessHandler = (AnyObject?) -> Void
    public typealias NetworkFailureHandler = (NSHTTPURLResponse?, AnyObject?, NSError) -> Void

    private typealias CachedTask = (NSHTTPURLResponse?, AnyObject?, NSError?) -> Void

    private var cachedTasks = Array<CachedTask>()
    private var isRefreshing = false

//    public init(
//            configuration: NSURLSessionConfiguration,
//            delegate: SessionDelegate ,
//            serverTrustPolicyManager: ServerTrustPolicyManager? ) {
//        super.init(configuration, delegate, serverTrustPolicyManager)
//    }

    public func startRequest(
            method method: Alamofire.Method,
            URLString: URLStringConvertible,
            parameters: [String: AnyObject]?,
            encoding: ParameterEncoding,
            successHandler: NetworkSuccessHandler?,
            failureHandler: NetworkFailureHandler?)
            -> Request?
    {
        let cachedTask: CachedTask = {
            [weak self] URLResponse, data, error in
            if let strongSelf = self {
                if let error = error {
                    failureHandler?(URLResponse, data, error)
                }
                else {
                    strongSelf.startRequest(
                        method: method,
                        URLString: URLString,
                        parameters: parameters,
                        encoding: encoding,
                        successHandler: successHandler,
                        failureHandler: failureHandler
                    )
                }
            }
        }

        if self.isRefreshing {
            self.cachedTasks.append(cachedTask)
            return nil
        }

        // Append your auth tokens here to your parameters

        let request = self.request(method, URLString, parameters: parameters, encoding: encoding)

        request.response {
            [weak self] request, response, data, error in
            if let strongSelf = self {
                if let response = response {
                    if response.statusCode == 401 {
                        strongSelf.cachedTasks.append(cachedTask)
                        strongSelf.refreshTokens()
                        return
                    }
                }

                if let error = error {
                    failureHandler?(response, data, error)
                } else {
                    successHandler?(data)
                }
            }
        }
        return request
    }

    func refreshTokens() {
        self.isRefreshing = true

        // Make the refresh call and run the following in the success closure to restart the cached tasks

        let cachedTaskCopy = self.cachedTasks
        self.cachedTasks.removeAll()
        cachedTaskCopy.map {
            $0(nil, nil, nil)
        }

        self.isRefreshing = false
    }
}
