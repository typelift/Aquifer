//
//  ProxyTests.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/14/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Aquifer
import SwiftCheck
import XCTest
import func Swiftz.const
import func Swiftz.identity
import func Swiftz.curry
import func Swiftz.•
import func Swiftz.<*>
import func Swiftz.<^>

class ProxySpec : XCTestCase {
    func testProperties() {
        property("Proxy obeys the Functor identity law") <- forAll { (p2 : AProxy, s : AServer, c : AClient) in
            let p = aProxy(p2)
            return (identity <^> p, p) ==== (s, c)
        }
        
        /// Functor composition law follows from Arrow composition laws in Swiftz.
        
        property("Proxy obeys the Applicative identity law") <- forAll { (p2 : AProxy, s : AServer, c : AClient) in
            let p = aProxy(p2)
            return (const(identity) <*> p, p) ==== (s, c)
        }
        
        property("Respond distributes over composition") <- forAll { (f2 : AProxy, g2 : AProxy, h2 : AProxy, s : AServer, c : AClient) in
            let f = aProxy(f2)
            let g = aProxy(g2)
            let h = aProxy(h2)

            return ((f >-> g) |>| h, (f |>| h) >-> (g |>| h)) ==== (s, c)
        }

        property("Request distributes over composition") <- forAll { (f2 : AProxy, g2 : AProxy, h2 : AProxy, s : AServer, c : AClient) in
            let f = aProxy(f2)
            let g = aProxy(g2)
            let h = aProxy(h2)

            return ((f >-> g) >|> h, (f >|> h) >-> (g >|> h)) ==== (s, c)
        }
        
        /// Need closures here.  Autoclosures crash Swiftc.
        property("Request-Respond duality") <- forAll { (s : AServer, c : AClient) in
            return
                ({ $0.reflect() } • { respond($0) }, { request($0) }) ==== (s, c)
                ^&&^
                ({ $0.reflect() } • { request($0) }, { respond($0) }) ==== (s, c)
        }

        property("Request Zero Law") <- forAll { (p2 : AProxy, s : AServer, c : AClient) in
            let p = aProxy(p2)
            return (p >|> Proxy.pure, Proxy.pure) ==== (s, c)
        }
        
        property("Push-Pull respect associativity") <- forAll { (f2 : AProxy, g2 : AProxy, h2 : AProxy, s : AServer, c : AClient) in
            let f = aProxy(f2)
            let g = aProxy(g2)
            let h = aProxy(h2)
            
            return ((f >+> g) >~> h, f >+> (g >~> h)) ==== (s, c)
        }
        
        property("Request Composition Reflection") <- forAll { (f2 : AProxy, g2 : AProxy, s : AServer, c : AClient) in
            let f = aProxy(f2)
            let g = aProxy(g2)
            
            return ({ $0.reflect() } • (f >|> g), ({ $0.reflect() } • f) |>| ({ $0.reflect() } • g)) ==== (s, c)
        }
        
        property("Involution") <- forAll { (p2 : AProxy, s : AServer, c : AClient) in
            let p = aProxy(p2)
            return ({ $0.reflect() } • { $0.reflect() } • p >-> Proxy.pure, p) ==== (s, c)
        }
    }
    
    func testCategoricalProperties() {
        property("Kleisli Category") <- self.testCategory(>->)(Proxy<Int, Int, Int, Int, Int>.pure)
        property("Respond Category") <- self.testCategory(|>|)({ respond($0) })
        property("Request Category") <- self.testCategory(>|>)({ request($0) })
        property("Pull Category") <- self.testCategory(>+>)({ pull($0) })
        property("Push Category") <- self.testCategory(>~>)({ push($0) })
    }
    
    private func testCategory(op : Operation.T)(_ idt : ProxyK.T) -> Testable {
        let rId = forAll { (f2 : AProxy, s : AServer, c : AClient) in
            return self.rightIdentity(op, idt)(f2, s, c)
        }
        let lId = forAll { (f2 : AProxy, s : AServer, c : AClient) in
            return self.leftIdentity(op, idt)(f2, s, c)
        }
        let assoc = forAll { (f2 : AProxy, g2 : AProxy, h2 : AProxy, s : AServer, c : AClient) in
            return self.associativity(op)(f2, g2, h2, s, c)
        }
        
        return rId ^&&^ lId ^&&^ assoc
    }
    
    private func rightIdentity(op : Operation.T, _ idt : ProxyK.T)(_ f2 : AProxy, _ s : AServer, _ c : AClient) -> Bool {
        let f = aProxy(f2)
        return (f, op(f, idt)) ==== (s, c)
    }

    private func leftIdentity(op : Operation.T, _ idt : ProxyK.T)(_ f2 : AProxy, _ s : AServer, _ c : AClient) -> Bool {
        let f = aProxy(f2)
        return (op(f, idt), f) ==== (s, c)
    }

    
    private func associativity(op : Operation.T)(_ f2 : AProxy, _ g2 : AProxy, _ h2 : AProxy, _ s : AServer, _ c : AClient) -> Bool {
        let f = aProxy(f2)
        let g = aProxy(g2)
        let h = aProxy(h2)
        return (op(f, op(g, h)), op(op(f, g), h)) ==== (s, c)
    }
}
