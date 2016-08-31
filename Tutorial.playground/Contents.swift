// Copyright (c) 2012-2014 Gabriel Gonzalez
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
// * Neither the name of Gabriel Gonzalez nor the names of other contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

//: # Introduction

//: The `Aquifer` library decouples stream processing stages from each other so
//: that you can mix and match diverse stages to produce useful streaming
//: programs.  If you are a library writer, `Aquifer` lets you package up
//: streaming components into a reusable interface.  If you are an application
//: writer, `Aquifer` lets you connect pre-made streaming components with minimal
//: effort to produce a highly declarative program.
//:
//: To enforce loose coupling, components can only communicate using two
//: commands:
//:
//: * `yield`: Send output data
//:
//: * `await`: Receive input data
//:
//: `Aquifer` has four types of components built around these two commands:
//:
//: * `Producer`s can only `yield` values and they model streaming sources
//:
//: * `Consumer`s can only `await` values and they model streaming sinks
//:
//: * `Pipe`s can both `yield` and `await` values and they model stream
//: transformations
//:
//: * `Effect`s can neither `yield` nor `await` and they model non-streaming
//: components
//:
//: You can connect these components together in four separate ways which
//: parallel the four above types:
//:
//: * `for_` handles `yield`s
//:
//: * `>~~` handles `await`s
//:
//: * `>->` handles both `yield`s and `await`s
//:
//: * `>>-` handles return values
//:
//: As you connect components their types will change to reflect inputs and
//: outputs that you've fused away.  You know that you're done connecting things
//: when you get an `Effect`, meaning that you have handled all inputs and
//: outputs.  You run this final `Effect` to begin streaming.

import Swiftz
import Aquifer

//: # Producers

//: `Producer`s are effectful streams of input.  Specifically, a `Producer` is a
//: Type that extends any other type with a new `yield` command. This `yield`
//: command lets you send output downstream to an anonymous handler, decoupling
//: how you generate values from how you consume them.

//: As an aside: Swift does not *technically* allow for the definition of polymorphic
//: typealiases like `Producer`.  Instead, `Aquifer` uses a number of polymorphic enums
//: with typealiases inside.  We specifically chose to use enums with no cases so there
//: would be no option to instantiate them.  This way, they are markers and nothing more.

//: The following `stdinByLine` `Producer` shows how to incrementally read in
//: `String`s from standard input and `yield` them downstream, terminating
//: gracefully when reaching the end of the input:

import class Foundation.NSFileHandle

//                                   +----------  A `Producer` that yields `String`s
//                                   |
//                                   |        +-- Every action has a return value.
//                                   |        |   This action returns `()` when finished
//                                   v        v
public func stdinByLine() -> Producer<String, ()> {
	let handle = FileHandle.standardInput // Grab the handle
	if handle.aqu_isAtEndOfFile { // If we're at the end of the line, stop.
		return pure(())
	} else {
		return yield(handle.aqu_readLine()) >>- { _ in fromHandle(handle) } // Otherwise `yield` the line and loop.
	}
}

//: `yield` emits a value, suspending the current `Producer` until the value is
//: consumed.  If nobody consumes the value (which is possible) then `yield`
//: never returns.  You can think of `yield` as having the following type:
//:
//:     func yield<A>(value : A) -> Producer<A, ()>
//:
//: The true type of `yield` is actually more general and powerful.  Throughout
//: the tutorial we will present type signatures like this that are simplified at
//: first and then later reveal more general versions.  So read the above type
//: signature as simply saying: "You can use `yield` within a `Producer`, but
//: you may be able to use `yield` in other contexts, too."
//:
//: Jump to the definition of `yield` to navigate to its documentation.  There you
//: will see that `yield` actually uses the `Producer` enum and its underlying
//: typealias `T` which hides a lot of polymorphism behind a simple veneer.  The
//: documentation for `yield` says that you can also use `yield` within a
//: `Pipe`, too, because of this polymorphism:
//:
//     func yield<UO, UI, DO>(@autoclosure(escaping) value : () -> DO) -> Proxy<UO, UI, (), DO, ()>
//:
//: Use simpler types like these to guide you until you understand the fully
//: general type.

//: `for_` loops are the simplest way to consume a `Producer` like `stdinByLine`.
//: `for_` has the following type:
//:
//                        +-- Producer           +-- The body of the   +-- Result
//                        |   to loop            |   loop              |
//                        v   over               v                     v
//                        --------------         ---------------       ---------
//     func for_<A, R>(p : Producer<A, >, _ f : A -> Effect<()>) -> Effect<>
//
//: `for_(producer, body)` loops over `producer`, substituting each `yield` in
//: `producer` with `body`.
//:
//: You can also deduce that behavior purely from the type signature:
//:
//: * The body of the loop takes exactly one argument of type `A`, which is
//: the same as the output type of the `Producer`.  Therefore, the body of the
//: loop must get its input from that `Producer` and nowhere else.
//:
//: * The return value of the input `Producer` matches the return value of the
//: result, therefore `for_` must loop over the entire `Producer` and not skip
//: anything.
//:
//: The above type signature is not the true type of `for_`, which is actually
//: more general.  Think of the above type signature as saying: "If the first
//: argument of `for_` is a `Producer` and the second argument returns an
//: `Effect`, then the final result must be an `Effect`."
//:
//: Jump to the definition of (⌘+Click) `for_` to navigate to its documentation.
//: There you will see the fully general type and underneath you will see equivalent
//: simpler types.  One of these says that if the body of the loop is a `Producer`,
//: then the result is a `Producer`, too:
//:
//     func for_<UO, UI, DI, DO, NI, NO, FR>(p : Proxy<UO, UI, DI, DO, FR>, _ f : DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, NI, NO, FR>
//:
//: The first type signature we showed for `for_` was a special case of this
//: slightly more general signature because a `Producer` that never `yield`s is
//: also an `Effect`:
//:
//     `X` is an "uninhabited" type.  Practically, this means all attempts to
//     construct an `X` will fail catastrophically.
//     struct X { //... }
//
//: This is why `for_` permits two different type signatures.  The first type
//: signature is just a special case of the second one:
//
//     func for_<A, B, R>(p : Producer<A, >, f : (A -> Producer<B, ()>) -> Producer<B, >
//
//     Specialize `B` to `X`
//     func for_<A, R>(p : Producer<A, >, f : (A -> Producer<Never, ()>) -> Producer<Never, >
//
//     Producer<Never, > == Effect<>
//     func for_<A, R>(p : Producer<A, >, f : (A -> Effect<()>) -> Effect<>
//
//: This is the same trick that all `Aquifer` functions use to work with various
//: combinations of `Producer`s, `Consumer`s, `Pipe`s, and `Effect`s.  Each
//: function really has just one general type, which you can then simplify
//: down to multiple useful alternative types.
//:
//: Here`s an example use of a `for_` `loop`, where the second
//: argument (the loop body) is an `Effect`:
//:

// more concise: `return for_(stdinByLine(), Effect.pure • print)`
let stdinLoop = for_(stdinByLine()) { str in
	return Effect.pure(print(str))
}

//: In this example, `for_` loops over `stdinByLine` and replaces every `yield` in
//: `stdinByLine` with the body of the loop, printing each line.

//: You can think of `yield` as creating a hole and a `for_` loop is one way
//: to fill that hole.
//;
//: Notice how the final `stdinLoop` only lifts actions and does nothing else.  This
//: property is true for all `Effect`s, which are just glorified wrappers around
//: actions. This means we can run these `Effect`s to remove the lifting and lower
//: them back to the equivalent computation:
//
//     func runEffect<R>(eff : Effect<>) -> R
//
//: This is the real type signature of `runEffect`, which refuses to accept
//: anything other than an `Effect`. This ensures that we handle all
//: inputs and outputs before streaming data:

runEffect(stdinLoop)

//: ... or you could inline the entire `stdinLoop` into the following one-liner:

runEffect <| for_(stdinLn(), { Effect<()>.pure(print($0)) })

//: Our final program loops over standard input and echoes every line to
//: standard output until we hit `Ctrl-D` to end the input stream:

//: You can also use `for_` to loop over lists, too.  To do so, convert the list
//: to a `Producer` using `each`, which is exported by default from `Aquifer`:
//:
//
//     public func each<T>(xs : [T]) -> Producer<T, ()>
//
//: Combine `for_` and `each` to iterate over lists using a "foreach" loop:

runEffect <| for_(each([1...4]), { Effect.pure(print($0)) })

//: `each` is actually more general and works for any `SequenceType`
//
//  public func each<S : SequenceType>(xs : S) -> Producer<S.Generator.Element, ()> {
//

//: # Composability

//: You might wonder why the body of a `for_` loop can be a `Producer`.  Let`s
//: test out this feature by defining a new loop body that `duplicate`s every
//: value:

func duplicate<A>(_ x : A) -> Producer<A, ()> {
	return yield(x) >>- { _ in  yield(x) }
}

let loop = for_(stdinLn(), duplicate)

//: Which is the exact same as:

let loop2 = for_(stdinLn()) { x in
	return yield(x) >>- { _ in  yield(x) }
}

//: This time our `loop` is a `Producer` that outputs `String`s, specifically
//: two copies of each line that we read from standard input.  Since `loop` is a
//: `Producer` we cannot run it because there is still unhandled output.
//: However, we can use yet another `for_` to handle this new duplicated stream:

runEffect <| for_(loop, { Effect<()>.pure(print($0)) })

//: This creates a program which echoes every line from standard input to
//: standard output twice:
//:
//: But is this really necessary?  Couldn`t we have instead written this using a
//: nested for loop?

runEffect <|
	for_(stdinLn()) { str1 in
		return for_(duplicate(str1)) { str2 in
			return Effect.pure(print(str2))
		}
	}

//: Yes, we could have!  In fact, this is a special case of the following
//: equality, which always holds no matter what:
//
// let s :      Producer<A, ()>  // i.e. `stdinLn()`
// let f : A -> Producer<B, ()>  // i.e. `duplicate()`
// let g : B -> Producer<C, ()>  // i.e. `(Effect<()> • print)`
//
// for_(for_(s, f), g) == for_(s, { x in for_(f(x), g) })
//
//: We can understand the rationale behind this equality if we first define the
//: following operator that is the point-free counterpart to `for_`:
//
//     func ~~> <A, B, C, R>(f : A -> Producer<B, >, g : B -> Producer<C, >) -> (A -> Producer<C, >) {
// 	       return { x in for_(f(x), g) }
//     }
//
//: Using `~~>` (pronounced "into"), we can transform our original equality
//: into the following more symmetric equation:
//
// let f : A -> Producer<B, >
// let g : B -> Producer<C, >
// let h : C -> Producer<D, >
//
// (f ~~> g) ~~> h == f ~~> (g ~~> h)
//
//: This looks just like an associativity law.  In fact, `~~>` has another nice
//: property, which is that `yield` is its left and right identity:
//
// Left Identity
//     yield ~~> f == f
//
// Right Identity
//     f ~~> yield == f
//

//: In other words, `yield` and `~~>` form a `Category`, specifically the
//: generator category, where `~~>` plays the role of the composition operator
//: and `yield` is the identity.  If you don`t know what a `Category` is, that`s
//: okay, and category theory is not a prerequisite for using `Aquifer`.  All you
//: really need to know is that `Aquifer` uses some simple category theory to keep
//: the API intuitive and easy to use.
//:
//: Notice that if we translate the left identity law to use `for_` instead of
//: `~~>` we get:
//
//     for_(yield(x), f) == f(x)
//
//: This just says that if you iterate over a pure single-element `Producer`,
//: then you could instead cut out the middle man and directly apply the body of
//: the loop to that single element.
//:
//: If we translate the right identity law to use `for_` instead of `~~>` we
//: get:
//
//     for_(s, yield) == s
//
//: This just says that if the only thing you do is re-`yield` every element of
//: a stream, you get back your original stream.

//: These three "for loop" laws summarize our intuition for how `for_` loops
//: should behave and because these are `Category` laws in disguise that means
//: that `Producer`s are composable in a rigorous sense of the word.
//:
//: In fact, we get more out of this than just a bunch of equations.  We also
//: get a useful operator: `~~>`.  We can use this operator to condense
//: our original code into the following more succinct form that composes two
//: transformations:

runEffect <| for_(stdinLn(), ({ (x : String) in duplicate(x) } ~~> { x in
	return Effect<()>.pure(print(x))
}))

//: This means that we can also choose to program in a more functional style and
//: think of stream processing in terms of composing transformations using
//: `~~>` instead of nesting a bunch of `for_` loops.
//:
//: The above example is a microcosm of the design philosophy behind the `Aquifer`
//: library:
//:
//: * Define the API in terms of categories
//:
//: * Specify expected behavior in terms of category laws
//:
//: * Think compositionally instead of sequentially

//: # Consumers

//: Sometimes you don`t want to use a `for_` loop because you don`t want to consume
//: every element of a `Producer` or because you don`t want to process every
//: value of a `Producer` the exact same way.
//:
//: The most general solution is to externally iterate over the `Producer` using
//: the `next` command:
//
//     func next(p : Producer<A, >) -> Either<R, (A, Producer<A, >)>
//
//: Think of `next` as pattern matching on the head of the `Producer`.  This
//: `Either` returns a `Left` if the `Producer` is done or it returns a `Right`
//: containing the next value, `A`, along with the remainder of the `Producer`.
//:
//: However, sometimes we can get away with something a little more simple and
//: elegant, like a `Consumer`, which represents an effectful sink of values.  A
//: `Consumer` is a wrapper type that extends a base type with a new
//: `await` command. This `await` command lets you receive input from an
//: anonymous upstream source.
//:
//: The following `stdoutByLine` `Consumer` shows how to incrementally `await`
//: `String`s and print them to standard output, terminating gracefully when
//: receiving a broken pipe error:

//                     +--------+-- A `Consumer` that awaits `String`s
//                     |        |
//                     v        v
func stdoutByLine() -> Consumer<String, ()> {
	let handle = FileHandle.standardOutput
	return for_(cat()) { handle.aqu_writeLine($0); return pure(()) }
}

//: `await` is the dual of `yield`: we suspend our `Consumer` until we receive a
//: new value.  If nobody provides a value (which is possible) then `await`
//: never returns.  You can think of `await` as having the following type:
//
//     await() -> Consumer<A, A>
//
//: One way to feed a `Consumer` is to repeatedly feed the same input using
//: using `>~~` (pronounced "feed"):
//
//                          +- Feed               +- Consumer to    +- Returns new
//				            |  action             |  feed           |  Effect
//				            v                     v                 v
//				            ---------             --------------     ---------
//     func >~~ <B, C>(eff : Effect<>, consumer : Consumer<B, C>) -> Effect<>
//
//: `draw >~~ consumer` loops over `consumer`, substituting each `await` in
//: `consumer` with `draw`.
//:
//: So the following code replaces every `await` in `stdoutLn` with
//: `Consumer.pure(getLine)`and then removes all the `lift`s:
//:

runEffect <| Effect.pure(readLine()!) >~~ (stdoutLn() as Aquifer.Proxy<(), String, (), Never, ()>)

//: You might wonder why `>~~` uses an `Effect` instead of a raw value.  The reason why
//: is that `>~~` actually permits the following more general type:
//
//     func >~~ <A, B, C>(eff : Consumer<A, B>, consumer : Consumer<B, C>) -> Consumer<A, C>
//
//: `>~~` is the dual of `~~>`, composing `Consumer`s instead of `Producer`s.
//:
//: This means that you can feed a `Consumer` with yet another `Consumer` so
//: that you can `await` while you `await`.  For example, we could define the
//: following intermediate `Consumer` that requests two `String`s and returns
//: them concatenated:

let doubleUp : Consumer<String, String> = await() >>- { str1 in
	await() >>- { str2 in
		return Consumer.pure(str1 + str2)
	}
}

//: more concise:

let doubleUp2 : Consumer<String, String> = curry(+) <^> await() <*> await()

//: We can now insert this in between `Consumer<String, String>.pure(readLine()!)` and `stdoutByLine` and see
//: what happens:

runEffect <| Effect<String>.pure(readLine()!) >~~ doubleUp >~~ (stdoutLn() as Aquifer.Proxy<(), String, (), Never, ()>)

//
// Associativity
//    (f >~~ g) >~~ h = f >~~ (g >~~ h)
//
//: ... so we can always omit the parentheses since the meaning is unambiguous:
//
//    f >~~ g >~~ h
//
//: Also, `>~~` has an identity, which is `await`!
//
// Left identity
//     await() >~~ f == f
//
// Right Identity
//     f >~~ await() == f
//
//: In other words, `>~~` and `await` form a `Category`, too, specifically the
//: iteratee category, and `Consumer`s are also composable.

//: Pipes

//: Our previous programs were unsatisfactory because they were biased either
//: towards the `Producer` end or the `Consumer` end.  As a result, we had to
//: choose between gracefully handling end of input (using `stdinLn`) or
//: gracefully handling end of output (using `stdoutLn`), but not both at the
//: same time.
//:
//: However, we don`t need to restrict ourselves to using `Producer`s
//: exclusively or `Consumer`s exclusively.  We can connect `Producer`s and
//: `Consumer`s directly together using `>->` (pronounced "pipe"):
//
//     func >-> (p : Producer<A, >, c : Consumer<A, R>) -> Effect<>
//
//: This returns an `Effect` which we can run:

runEffect <| stdinLn() >-> stdoutLn()

//: This program is more declarative of our intent: we want to stream values
//: from `stdinLn` to `stdoutLn`.  The above "pipeline" not only echoes
//: standard input to standard output, but also handles both end of input and
//: broken pipe errors:
//:
//: `>->` is "pull-based" meaning that control flow begins at the most
//: downstream component (i.e. `stdoutLn` in the above example).  Any time a
//: component `await`s a value it blocks and transfers control upstream and
//: every time a component `yield`s a value it blocks and restores control back
//: downstream, satisfying the `await`.  So in the above example, `>->`
//: matches every `await` from `stdoutLn` with a `yield` from `stdinLn`.
//:
//: Streaming stops when either `stdinLn` terminates (i.e. end of input) or
//: `stdoutLn` terminates (i.e. broken pipe).  This is why `>->` requires
//: that both the `Producer` and `Consumer` share the same type of return value:
//: whichever one terminates first provides the return value for the entire
//: `Effect`.
//:
//: Let`s test this by modifying our `Producer` and `Consumer` to each return a
//: diagnostic `String`:
//:

let str = runEffect <| (const("End of input!") <^> stdinLn()) >-> (const("Broken pipe!") <^> stdoutLn())

//:
//: You might wonder why `>->` returns an `Effect` that we have to run instead
//: of returning a value directly.  This is because you can connect things other
//: than `Producer`s and `Consumer`s, like `Pipe`s, which are effectful stream
//: transformations.
//:
//: A `Pipe` is a wrapper type that is a mix between a `Producer` and
//: `Consumer`, because a `Pipe` can both `await` and `yield`.  The following
//: example `Pipe` is analagous to the STL's notion of a slice, in that where slices
//: only allow a fixed number of values from the resulting collection, the pipe only
//: allows a fixed number of values to flow through:
//:

/// Returns a pipe that only allows a given number of values to pass through it.
//
//                               +--------- A `Pipe` that
//                               |    +---- `await`s `A`s and
//                               |    |  +-- `yield`s `A`s
//                               |    |  |
//                               v    v  v
public func take_<A>(_ n : Int) -> Pipe<A, A, ()> {
	if n <= 0 {
		return pure(())
	} else {
		return await() >>- { yield($0) >>- { _ in take(n - 1) } }
	}
}

//: You can use `Pipe`s to transform `Producer`s, `Consumer`s, or even other
//: `Pipe`s using the same `>->` operator:
//
//     func >-> <A, B, R>(Producer<A, >, Pipe<A, B, >) -> Producer<B, >
//     func >-> <A, B, R>(Pipe<A, B, >, Consumer<B, R>) -> Consumer<A, R>
//     func >-> <A, B, C, R>(Pipe<A, B, >, Pipe<B, C, >) -> Pipe<A, C, >
//
//: For example, you can compose `take` after `stdinLn` to limit the number
//: of lines drawn from standard input:

func maxInput(_ n : Int) -> Producer<String, ()> {
	return stdinLn() >-> take(n)
}

runEffect <| maxInput(3) >-> stdoutLn()

//: ... or you can pre-compose `take` before `stdoutLn` to limit the number
//: of lines written to standard output:

func maxOutput(_ n : Int) -> Consumer<String, ()> {
	return take(n) >-> stdoutLn()
}

runEffect <| stdinLn() >-> maxOutput(3)

//: Those both gave the same behavior because `>->` is associative:
//
// (p1 >-> p2) >-> p3 = p1 >-> (p2 >-> p3)
//
//: Therefore we can just leave out the parentheses:

runEffect <| stdinLn() >-> take(3) >-> stdoutLn()

//: `>->` is designed to behave like the Unix pipe operator, except with less
//: quirks.  In fact, we can continue the analogy to Unix by defining `cat`
//: (named after the Unix `cat` utility), which reforwards elements endlessly:

func cat_<A, R>() -> Pipe<A, A, R> {
	return await() >>- { x in yield(x) } >>- {  _ in cat_() }
}


//: `cat` is the identity of `>->`, meaning that `cat` satisfies the
//: following two laws:
//:
//: Useless use of `cat`
//:     cat >-> p = p
//:
//: Forwarding output to `cat` does nothing
//:     p >-> cat = p
//:
//: Therefore, `>->` and `cat` form a `Category`, specifically the category of
//: Unix pipes, and `Pipe`s are also composable.
//:
//: A lot of Unix tools have very simple definitions when written using `pipes`:

func head<A>(_ n : Int) -> Pipe<A, A, ()>  {
	return take(n)
}

func yes<R>() -> Producer<String, R> {
	return yield("y") >>- { _ in yes() }
}

//: This prints out 3 `y`s, just like the equivalent Unix pipeline:
//:     `yes | head -3`

runEffect <| yes() >-> head(3) >-> stdoutLn()

//: This lets us write "Swift pipes" instead of Unix pipes.  These are much
//: easier to build than Unix pipes and we can connect them directly within
//: Swift for interoperability with the Swift language and ecosystem.

//: Tricks

//: `Aquifer` is more powerful than meets the eye so this section presents some
//: non-obvious tricks you may find useful.
//:
//: Many `Aquifer` combinators will work on unusual `Aquifer` types. and the
//: next few examples will use the `cat` pipe to demonstrate this.
//:
//: For example, you can loop over the output of a `Pipe` using `for_`, which is
//: how `map` is defined:

// Read this as: "For all values flowing downstream, apply `f`"
public func map_<A, B, R>(f : @escaping (A) -> B) -> Pipe<A, B, R> {
	return for_(cat()) { v in yield(f(v)) }
}

//: You can also feed a `Pipe` input using `>~~`.  This means we could have
//: instead defined the `yes`pipe like this:

// Read this as: Keep feeding "y" downstream
func yesAgain<R>() -> Producer<String, R> {
	return Producer.pure("y") >~~ cat()
}

//: You can even compose pipes inside of another pipe:

func customerService() -> Producer<String, ()> {
	return each(["Hello, how can I help you?", "Hold for one second."]) >>- { _ in stdinLn() >-> takeWhile({ $0 != "Goodbye!" }) } // Now continue with a human
}

//: Also, you can often use `each` in conjunction with `~~>` to traverse nested
//: data structures.  For example, you can print all non-`Nothing` elements
//: from a doubly-nested list:

let testArray : [[[Int]]] = [[[1], []], [[2], [3]]]
let loopDeLoopDeLoop = (each ~~> each ~~> each ~~> { x in
	return Effect<()>.pure(print(x))
})(testArray)

//: Conclusion

//: This tutorial covers the concepts of connecting, building, and reading
//: `Aquifer` code.  The framework is still a work in progress that does not explore the
//: full potential of `pipes` functionality, which actually permits bidirectional
//: communication.  Advanced `pipes` and `Aquifer` users can explore this library in
//: greater detail by studying the documentation in the `Operators.swift` file to learn
//: about the symmetry of the underlying `Proxy` type and operators.

//: Copyright

//: This tutorial is licensed under a [Creative Commons Attribution 4.0 International License](http://creativecommons.org/licenses/by/4.0/)
