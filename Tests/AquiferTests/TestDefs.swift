//
//  TestDefs.swift
//  Aquifer
//
//  Created by Robert Widmann on 8/15/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

import func Swiftz.on
import func Swiftz.const
import Aquifer
import SwiftCheck

enum ClientStep : Int, CustomStringConvertible {
	case clientRequest
	case clientLog
	case clientInc

	var description : String {
		switch self {
		case .clientInc:
			return "inc"
		case .clientLog:
			return "log"
		case .clientRequest:
			return "request"
		}
	}
}

extension ClientStep : Arbitrary {
	static var arbitrary : Gen<ClientStep> {
		return Gen.sized { _ in
			return Gen<ClientStep>.fromElements(of: [
				.clientInc,
				.clientLog,
				.clientRequest,
			])
		}
	}
}

enum ServerStep : Int, CustomStringConvertible {
	case serverRespond
	case serverLog
	case serverInc

	var description : String {
		switch self {
		case .serverInc:
			return "inc"
		case .serverLog:
			return "log"
		case .serverRespond:
			return "respond"
		}
	}
}

extension ServerStep : Arbitrary {
	static var arbitrary : Gen<ServerStep> {
		return Gen.sized { _ in
			return Gen<ServerStep>.fromElements(of: [
				.serverInc,
				.serverLog,
				.serverRespond,
			])
		}
	}
}

enum ProxyStep : Int, CustomStringConvertible {
	case proxyRequest
	case proxyRespond
	case proxyLog
	case proxyInc

	var description : String {
		switch self {
		case .proxyRequest:
			return "request"
		case .proxyRespond:
			return "respond"
		case .proxyLog:
			return "log"
		case .proxyInc:
			return "inc"
		}
	}
}

extension ProxyStep : Arbitrary {
	static var arbitrary : Gen<ProxyStep> {
		return Gen.sized { _ in
			return Gen<ProxyStep>.fromElements(of: [
				.proxyRequest,
				.proxyRespond,
				.proxyLog,
				.proxyInc,
			])
		}
	}
}


func log<UO, UI, DI, DO>(_ n : Int) -> Proxy<UO, UI, DI, DO, Int> {
	/// lift (tell [n]) >>
	return Proxy.pure(n)
}

func inc<UO, UI, DI, DO>(_ n : Int) -> Proxy<UO, UI, DI, DO, Int> {
	return Proxy.pure(n + 1)
}

func correct(_ str : String) -> String {
	if str.isEmpty {
		return "pure"
	}
	return str
}

struct AClient : CustomStringConvertible {
	let unAClient : [ClientStep]

	var description : String {
		return correct(self.unAClient.map({ $0.description }).intersperse(" >>->> ").reduce("", +))
	}
}

extension AClient : Arbitrary {
	static var arbitrary : Gen<AClient> {
		return [ClientStep].arbitrary.map(AClient.init)
	}

	static func shrink(_ c : AClient) -> [AClient] {
		return [ClientStep].shrink(c.unAClient).map(AClient.init)
	}
}

func aClient(_ client : AClient) -> ((Int) -> Client<Int, Int, Int>) {
	let p = client.unAClient.map({ (x : ClientStep) -> ((Int) -> Proxy<Int, Int, (), Never, Int>) in
		switch x {
		case .clientRequest:
			return { request($0) }
		case .clientLog:
			return log
		case .clientInc:
			return inc
		}
	})
	return p.reduce(Proxy.pure, >>->>)
}

struct AServer : CustomStringConvertible {
	let unAServer : [ServerStep]

	var description : String {
		return correct(self.unAServer.map({ $0.description }).intersperse(" >>->> ").reduce("", +))
	}
}

extension AServer : Arbitrary {
	static var arbitrary : Gen<AServer> {
		return [ServerStep].arbitrary.map(AServer.init)
	}

	static func shrink(_ c : AServer) -> [AServer] {
		return [ServerStep].shrink(c.unAServer).map(AServer.init)
	}
}

func aServer(_ server : AServer) -> ((Int) -> Server<Int, Int, Int>) {
	return server.unAServer.map({ (x : ServerStep) -> ((Int) -> Proxy<Never, (), Int, Int, Int>) in
		switch x {
		case .serverRespond:
			return { respond($0) }
		case .serverLog:
			return log
		case .serverInc:
			return inc
		}
	}).reduce(Proxy.pure, >>->>)
}

struct AProxy : Hashable, CustomStringConvertible {
	let unAProxy : [ProxyStep]

	var description : String {
		return correct(self.unAProxy.map({ $0.description }).intersperse(" >>->> ").reduce("", +))
	}

	var hashValue : Int {
		return Set(self.unAProxy).hashValue
	}
}

func == (l : AProxy, r : AProxy) -> Bool {
	return l.unAProxy == r.unAProxy
}

extension AProxy : Arbitrary {
	static var arbitrary : Gen<AProxy> {
		return [ProxyStep].arbitrary.map(AProxy.init)
	}

	static func shrink(_ c : AProxy) -> [AProxy] {
		return [ProxyStep].shrink(c.unAProxy).map(AProxy.init)
	}
}

extension AProxy : CoArbitrary {
	static func coarbitrary<C>(_ x : AProxy) -> ((Gen<C>) -> Gen<C>) {
		return [ProxyStep].coarbitrary(x.unAProxy)
	}
}

func aProxy(_ proxy : AProxy) -> ((Int) -> Proxy<Int, Int, Int, Int, Int>) {
	return proxy.unAProxy.map({ (x : ProxyStep) -> ((Int) -> Proxy<Int, Int, Int, Int, Int>) in
		switch x {
		case .proxyRequest:
			return { request($0) }
		case .proxyRespond:
			return { respond($0) }
		case .proxyLog:
			return log
		case .proxyInc:
			return inc
		}
	}).reduce(Proxy.pure, >>->>)
}

typealias ProxyK = (Int) -> Proxy<Int, Int, Int, Int, Int>

typealias OperationK = (@escaping ProxyK, @escaping ProxyK) -> ProxyK

func formulate(_ pl : @escaping ProxyK, _ pr : @escaping ProxyK, _ p0 : AServer, _ p1 : AClient) -> Bool {
	let sv  = aServer(p0)
	let cl  = aClient(p1)
	return on(==)({ p in runEffect(p(0)) })(sv >+> pl >+> cl)(sv >+> pr >+> cl)
}
