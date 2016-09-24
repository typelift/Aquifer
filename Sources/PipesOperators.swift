//
//  PipesOperators.swift
//  Aquifer
//
//  Created by Robert Widmann on 8/16/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

// MARK: - Combinators

precedencegroup IntoRightPrecedence {
	associativity: right
 	higherThan: DefaultPrecedence
}

precedencegroup IntoLeftPrecedence {
	associativity: left
	higherThan: DefaultPrecedence
}

infix operator ~~> : IntoRightPrecedence

infix operator <~~ : IntoLeftPrecedence

precedencegroup ReplaceRightPrecedence {
	associativity: right
	higherThan: IntoRightPrecedence
}

precedencegroup ReplaceLeftPrecedence {
	associativity: left
	higherThan: IntoLeftPrecedence
}

infix operator ~~< : ReplaceLeftPrecedence

infix operator >~~ : ReplaceRightPrecedence

precedencegroup ComposeLeftPrecedence {
	associativity: left
	higherThan: ReplaceLeftPrecedence
}

precedencegroup ComposeRightPrecedence {
	associativity: right
	higherThan: ReplaceRightPrecedence
}

infix operator >-> : ComposeLeftPrecedence

infix operator <-< : ComposeRightPrecedence

// MARK: - Respond Category

precedencegroup RespondCategoryRightPrecedence {
	associativity: right
	higherThan: IntoRightPrecedence
}

precedencegroup RespondCategoryLeftPrecedence {
	associativity: left
	higherThan: IntoLeftPrecedence
}

infix operator <|< : RespondCategoryLeftPrecedence

infix operator >|> : RespondCategoryRightPrecedence

infix operator |>> : RespondCategoryLeftPrecedence

infix operator <<| : RespondCategoryRightPrecedence


// MARK: - Request Category

precedencegroup RequestCategoryRightPrecedence {
	associativity: right
	higherThan: RespondCategoryRightPrecedence
}

precedencegroup RequestCategoryLeftPrecedence {
	associativity: left
	higherThan: RespondCategoryLeftPrecedence
}

infix operator |>| : RequestCategoryRightPrecedence

infix operator |<| : RequestCategoryLeftPrecedence

infix operator >>| : RequestCategoryRightPrecedence

infix operator |<< : RequestCategoryLeftPrecedence

// MARK: - Pull Category

precedencegroup PullCategoryRightPrecedence {
	associativity: right
	higherThan: RequestCategoryRightPrecedence
}

precedencegroup PullCategoryLeftPrecedence {
	associativity: left
	higherThan: RequestCategoryLeftPrecedence
}

infix operator >+> : PullCategoryLeftPrecedence

infix operator <+< : PullCategoryRightPrecedence

infix operator <<+ : PullCategoryLeftPrecedence

infix operator +>> : PullCategoryRightPrecedence

// MARK: - Push Category

precedencegroup PushCategoryRightPrecedence {
	associativity: right
	higherThan: PullCategoryRightPrecedence
}

precedencegroup PushCategoryLeftPrecedence {
	associativity: left
	higherThan: PullCategoryLeftPrecedence
}

infix operator >~> : PushCategoryRightPrecedence

infix operator <~< : PushCategoryLeftPrecedence

infix operator ~<< : PushCategoryRightPrecedence

infix operator >>~ : PushCategoryLeftPrecedence
