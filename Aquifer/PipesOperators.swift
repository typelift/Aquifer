//
//  PipesOperators.swift
//  Aquifer
//
//  Created by Robert Widmann on 8/16/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

// MARK: - Request Category

infix operator |>| {
	associativity right
	precedence 130
}

infix operator |<| {
	associativity left
	precedence 140
}

infix operator >>| {
	associativity right
	precedence 130
}

infix operator |<< {
	associativity left
	precedence 130
}

// MARK: - Respond Category

infix operator >|> {
	associativity right
	precedence 140
}

infix operator <|< {
	associativity left
	precedence 130
}

infix operator |>> {
	associativity left
	precedence 120
}

infix operator <<| {
	associativity right
	precedence 120
}


// MARK: - Push Category

infix operator >~> {
	associativity right
	precedence 170
}

infix operator <~< {
	associativity left
	precedence 170
}

infix operator >>~ {
	associativity left
	precedence 160
}

infix operator ~<< {
	associativity right
	precedence 160
}

// MARK: - Pull Category

infix operator >+> {
	associativity left
	precedence 160
}

infix operator <+< {
	associativity right
	precedence 160
}

infix operator +>> {
	associativity right
	precedence 150
}

infix operator <<+ {
	associativity left
	precedence 150
}
