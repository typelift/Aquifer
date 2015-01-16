//
//  StringInput.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/15/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

private class DataProducerFromURLImpl<UO, UI>: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate {
    private let url: NSURL

    private init(_ u: NSURL) {
        url = u
    }

    private func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
    }

    private func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
    }
}

public func dataProducer<UO, UI>(fromURL url: NSURL, withConfiguration config: NSURLSessionConfiguration? = NSURLSessionConfiguration.defaultSessionConfiguration(), withDelegateQueue dQueue: NSOperationQueue? = nil) -> Proxy<UO, UI, (), NSData, ()> {
    let impl: DataProducerFromURLImpl<UO, UI> = DataProducerFromURLImpl(url)
    let session: NSURLSession = NSURLSession(configuration: config, delegate: impl, delegateQueue: dQueue)
}
