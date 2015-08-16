//
//  ProxyTests.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/14/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Aquifer
import SwiftCheck

enum ClientStep : CustomStringConvertible {
    case ClientRequest
    case ClientLog
    case ClientInc
    
    var description : String {
        switch self {
        case .ClientInc:
            return "inc"
        case .ClientLog:
            return "log"
        case .ClientRequest:
            return "request"
        }
    }
}

extension ClientStep : Arbitrary {
    static var arbitrary : Gen<ClientStep> {
        fatalError()
    }
}

enum ServerStep : CustomStringConvertible {
    case ServerRespond
    case ServerLog
    case ServerInc
    
    var description : String {
        switch self {
        case .ServerInc:
            return "inc"
        case .ServerLog:
            return "log"
        case .ServerRespond:
            return "respond"
        }
    }
}

extension ServerStep : Arbitrary {
    static var arbitrary : Gen<ServerStep> {
        fatalError()
    }
}

enum ProxyStep : CustomStringConvertible {
    case ProxyRequest
    case ProxyRespond
    case ProxyLog
    case ProxyInc
    
    var description : String {
        switch self {
        case .ProxyRequest:
            return "request"
        case .ProxyRespond:
            return "respond"
        case .ProxyLog:
            return "log"
        case .ProxyInc:
            return "inc"
        }
    }
}

extension ProxyStep : Arbitrary {
    static var arbitrary : Gen<ProxyStep> {
        fatalError()
    }
}


func log<UO, UI, DI, DO>(n : Int) -> Proxy<UO, UI, DI, DO, Int> {
    /// lift (tell [n]) >>
    return Proxy.pure(n)
}

func inc<UO, UI, DI, DO>(n : Int) -> Proxy<UO, UI, DI, DO, Int> {
    return Proxy.pure(n + 1)
}

func correct(str : String) -> String {
    if str.isEmpty {
        return "return"
    }
    return str
}

struct AClient : CustomStringConvertible {
   let unAClient : [ClientStep]
    
    var description : String {
        return correct(self.unAClient.map({ $0.description }).intersperse(" >-> ").reduce("", combine: +))
    }
}

extension AClient : Arbitrary {
    static var arbitrary : Gen<AClient> {
        return [ClientStep].arbitrary.fmap(AClient.init)
    }
    
    // shrink = map AClient . shrink . unAClient
}

func aClient(client : AClient) -> (Int -> Proxy<Int, Int, (), X, Int> /* Client<Int, Int, Int> */) {
    return client.unAClient.map({ (x : ClientStep) -> (Int -> Proxy<Int, Int, (), X, Int>) in
        switch x {
        case .ClientRequest:
            return { request($0) }
        case .ClientLog:
            return log
        case .ClientInc:
            return inc
        }
    }).reduce(Proxy<Int, Int, (), X, Int>.pure, combine: (>->))
}

struct AServer : CustomStringConvertible {
    let unAServer : [ServerStep]
    
    var description : String {
        return correct(self.unAServer.map({ $0.description }).intersperse(" >-> ").reduce("", combine: +))
    }
}

extension AServer : Arbitrary {
    static var arbitrary : Gen<AServer> {
        return [ServerStep].arbitrary.fmap(AServer.init)
    }
    
    // shrink = map AServer . shrink . unAServer
}

func aServer(server : AServer) -> (Int -> Proxy<X, (), Int, Int, Int> /* Server<Int, Int, Int> */) {
    return server.unAServer.map({ (x : ServerStep) -> (Int -> Proxy<X, (), Int, Int, Int>) in
        switch x {
        case .ServerRespond:
            return { respond($0) }
        case .ServerLog:
            return log
        case .ServerInc:
            return inc
        }
    }).reduce(Proxy<Int, Int, (), X, Int>.pure, combine: (>->))
}

struct AProxy : CustomStringConvertible {
    let unAProxy : [ProxyStep]
    
    var description : String {
        return correct(self.unAProxy.map({ $0.description }).intersperse(" >-> ").reduce("", combine: +))
    }
}

extension AProxy : Arbitrary {
    static var arbitrary : Gen<AProxy> {
        return [ProxyStep].arbitrary.fmap(AProxy.init)
    }
    
    // shrink = map AProxy . shrink . unAProxy
}

func aProxy(proxy : AProxy) -> (Int -> Proxy<Int, Int, Int, Int, Int>) {
    return proxy.unAProxy.map({ (x : ProxyStep) -> (Int -> Proxy<Int, Int, Int, Int, Int>) in
        switch x {
        case .ProxyRequest:
            return { request($0) }
        case .ProxyRespond:
            return { respond($0) }
        case .ProxyLog:
            return log
        case .ProxyInc:
            return inc
        }
    }).reduce(Proxy<Int, Int, (), X, Int>.pure, combine: (>->))
}

struct ProxyK {
    typealias T = (Int -> Proxy<Int, Int, Int, Int, Int>)
}

struct Operation {
    typealias T = (ProxyK -> ProxyK -> ProxyK)
}

infix operator ==== {}

func ==== (_ : (pl : ProxyK.T, pr : ProxyK.T), _ : (p0 : AServer, p1 : AClient)) -> Bool {
    
}



