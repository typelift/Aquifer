//
//  PipesOperators.swift
//  Aquifer
//
//  Created by Robert Widmann on 8/16/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

import Swiftz

// MARK: - Combinators

infix operator ~~> : RightAssociativeCombinatorPrecedence

infix operator <~~ : LeftAssociativeCombinatorPrecedence

infix operator ~~< : LeftAssociativeCombinatorPrecedence

infix operator >~~ : RightAssociativeCombinatorPrecedence

infix operator >-> : MonadPrecedenceLeft

infix operator <-< : MonadPrecedenceRight

// MARK: - Request Category

infix operator |>| : RightAssociativeCombinatorPrecedence

infix operator |<| : LeftAssociativeCombinatorPrecedence

infix operator >>| : RightAssociativeCombinatorPrecedence

infix operator |<< : LeftAssociativeCombinatorPrecedence

// MARK: - Respond Category

infix operator <|< : LeftAssociativeCombinatorPrecedence

infix operator >|> : RightAssociativeCombinatorPrecedence

infix operator |>> : LeftAssociativeCombinatorPrecedence

infix operator <<| : RightAssociativeCombinatorPrecedence


// MARK: - Push Category

infix operator >~> : MonadPrecedenceRight

infix operator <~< : MonadPrecedenceLeft

infix operator >>~ : MonadPrecedenceLeft

infix operator ~<< : MonadPrecedenceRight

// MARK: - Pull Category

infix operator >+> : MonadPrecedenceLeft

infix operator <+< : MonadPrecedenceRight

infix operator +>> : MonadPrecedenceRight

infix operator <<+ : MonadPrecedenceLeft
