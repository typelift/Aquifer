//
//  TestDefs.swift
//  Aquifer
//
//  Created by Robert Widmann on 8/15/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

import func Swiftz.on
import func Swiftz.•
import func Swiftz.const
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
		return Gen.sized { n in
			switch (n % 3) {
			case 0:
				return Gen.pure(.ClientInc)
			case 1:
				return Gen.pure(.ClientLog)
			default:
				return Gen.pure(.ClientRequest)
			}
		}
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
		return Gen.sized { n in
			switch (n % 3) {
			case 0:
				return Gen.pure(.ServerInc)
			case 1:
				return Gen.pure(.ServerLog)
			default:
				return Gen.pure(.ServerRespond)
			}
		}
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
		return Gen.sized { n in
			switch (n % 4) {
			case 0:
				return Gen.pure(.ProxyRequest)
			case 1:
				return Gen.pure(.ProxyRespond)
			case 2:
				return Gen.pure(.ProxyLog)
			default:
				return Gen.pure(.ProxyInc)
			}
		}
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
	let p = client.unAClient.map({ (x : ClientStep) -> (Int -> Proxy<Int, Int, (), X, Int>) in
		switch x {
		case .ClientRequest:
			return { request($0) }
		case .ClientLog:
			return log
		case .ClientInc:
			return inc
		}
	})
	return p.reduce(Proxy.pure, combine: >->)
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
	}).reduce(Proxy.pure, combine: >->)
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
	}).reduce(Proxy.pure, combine: >->)
}

struct ProxyK {
	typealias T = (Int -> Proxy<Int, Int, Int, Int, Int>)
}

struct Operation {
	typealias T = (ProxyK.T, ProxyK.T) -> ProxyK.T
}

infix operator ==== {}

func ==== (l : (ProxyK.T, ProxyK.T), r : (AServer, AClient)) -> Bool {
	let (pl, pr) = l
	let (p0, p1) = r
	
	let sv  = aServer(p0)
	let cl  = aClient(p1)
	return on(==)({ p in runEffect(p(0)) })(sv >+> pl >+> cl)(sv >+> pr >+> cl)
}


func >>-<A, B, C>(f : (C -> A), k : (A -> C -> B)) -> (C -> B) {
	return { (let r) in
		return k(f(r))(r)
	}
}

/// Kleisli Composition of Arrows.
func >-> <A, B, C, UI, UO, DI, DO>(m1 : A -> Proxy<UI, UO, DI, DO, B>, m2 : B -> Proxy<UI, UO, DI, DO, C>) -> (A -> Proxy<UI, UO, DI, DO, C>) {
	return { r in
		return m1(r) >>- m2
	}
}


