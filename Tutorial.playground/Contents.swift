// MARK: - Introduction

//: The `Aquifer` library decouples stream processing stages from each other so
//: that you can mix and match diverse stages to produce useful streaming
//: programs.  If you are a library writer, `Aquifer` lets you package up
//: streaming components into a reusable interface.  If you are an application
//: writer, `Aquifer` lets you connect pre-made streaming components with minimal
//: effort to produce a highly-efficient program that streams data in constant
//: memory.
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
//: * `>~` handles `await`s
//:
//: * `>->` handles both `yield`s and `await`s
//:
//: * `>>-` handles return values
//:
//: As you connect components their types will change to reflect inputs and
//: outputs that you`ve fused away.  You know that you`re done connecting things
//: when you get an `Effect`, meaning that you have handled all inputs and
//: outputs.  You run this final `Effect` to begin streaming.

import Swiftz
import Aquifer

// MARK: - Producers

//: `Producer`s are effectful streams of input.  Specifically, a `Producer` is a
//: Type that extends any other type with a new `yield` command. This `yield` 
//: command lets you send output downstream to an anonymous handler, decoupling
//: how you generate values from how you consume them.

//: As an aside: Swift does not *technically* allow for the definition of polymorphic
//: typealiases like `Producer`.  Instead, `Aquifer` uses a number of polymorphic enums
//: with typealiases inside (the `.T` in all of the types presented hereafter).  We 
//: specifically chose to use enums with no cases so there would be no option to instantiate
//: them.  This way, they are markers and nothing more.
 
//: The following `stdinByLine` `Producer` shows how to incrementally read in
//: `String`s from standard input and `yield` them downstream, terminating
//: gracefully when reaching the end of the input:

import class Foundation.NSFileHandle

//                                   +----------  A `Producer` that yields `String`s
//                                   |
//                                   |        +-- Every action has a return value.
//                                   |        |   This action returns `()` when finished
//                                   v        v
public func stdinByLine() -> Producer<String, ()>.T {
	let handle = NSFileHandle.fileHandleWithStandardInput() // Grab the handle
	if handle.isAtEndOfFile { // If we`re at the end of the line, stop.
		return pure(())
	} else {
		return yield(handle.readLine) >>- { _ in fromHandle(handle) } // Otherwise `yield` the line and loop.
	}
}

//: `yield` emits a value, suspending the current `Producer` until the value is
//: consumed.  If nobody consumes the value (which is possible) then `yield`
//: never returns.  You can think of `yield` as having the following type:
//:
//:     func yield<A>(value : A) -> Producer<A, ()>.T
//:
//: The true type of `yield` is actually more general and powerful.  Throughout
//: the tutorial I will present type signatures like this that are simplified at
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
//     func yield<UO, UI, DO>(@autoclosure(escaping) value: () -> DO) -> Proxy<UO, UI, (), DO, ()>
//:
//: Use simpler types like these to guide you until you understand the fully
//: general type.

//: `for_` loops are the simplest way to consume a `Producer` like `stdinByLine`.
//: `for_` has the following type:
//:
//                        +-- Producer      +-- The body of the   +-- Result
//                        |   to loop       |   loop              |
//                        v   over          v                     v
//                        --------------       ---------------     ---------
//     func for_<A, R>(p: Producer<A, R>.T, _ f: A -> Effect<()>.T) -> Effect<R>.T
//
//: `for_(producer, body)` loops over `producer`, substituting each `yield` in
//: `producer` with `body`.
//:
//: You can also deduce that behavior purely from the type signature:
//:
//: * The body of the loop takes exactly one argument of type @(a)@, which is
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
//     func for_<UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, _ f: DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, NI, NO, FR>
//:
//: The first type signature I showed for `for_` was a special case of this
//: slightly more general signature because a `Producer` that never `yield`s is
//: also an `Effect`:
//:
//     `X` is an "uninhabited" type.  Practically, this means all attempts to
//     construct an `X` will fail catastrophically.
//     struct X { //... }
//
//: This is why `for` permits two different type signatures.  The first type
//: signature is just a special case of the second one:
//
//     func for_<A, B, R>(p : Producer<A, R>, f : (A -> Producer<B, ()>) -> Producer<B, R> 
//
//     Specialize `B` to `X`
//     func for_<A, R>(p : Producer<A, R>, f : (A -> Producer<X, ()>) -> Producer<X, R>
//
//     Producer<X, ?> == Effect
//     func for_<A, R>(p : Producer<A, R>, f : (A -> Effect<()>) -> Effect<R>
//
//: This is the same trick that all `Aquifer` functions use to work with various
//: combinations of `Producer`s, `Consumer`s, `Pipe`s, and `Effect`s.  Each
//: function really has just one general type, which you can then simplify
//: down to multiple useful alternative types.
//:
//: Here`s an example use of a `for` `loop`, where the second
//: argument (the loop body) is an `Effect`:
//:

// more concise: `return for_(stdinByLine(), Effect.T.pure • print)`
let stdinLoop = for_(stdinByLine()) { str in
	return Effect.T.pure(print(str))
}

//: In this example, `for` loops over `stdinByLine` and replaces every `yield` in
//: `stdinByLine` with the body of the loop, printing each line.

//: You can think of `yield` as creating a hole and a `for` loop is one way
//: to fill that hole.
//;
//: Notice how the final `stdinLoop` only lifts actions and does nothing else.  This 
//: property is true for all `Effect`s, which are just glorified wrappers around 
//: actions. This means we can run these `Effect`s to remove the lifting and lower
//: them back to the equivalent computation:
//
//     func runEffect<R>(eff : Effect<R>) -> R
//
//: This is the real type signature of `runEffect`, which refuses to accept
//: anything other than an `Effect`. This ensures that we handle all
//: inputs and outputs before streaming data:

runEffect(stdinLoop)

//: ... or you could inline the entire `stdinLoop` into the following one-liner:
    
runEffect <| for_(stdinLn(), Effect.T.pure • print)

//: Our final program loops over standard input and echoes every line to
//: standard output until we hit `Ctrl-D` to end the input stream:

//: You can also use `for_` to loop over lists, too.  To do so, convert the list
//: to a `Producer` using `each`, which is exported by default from `Aquifer`:
//:
//
//     public func each<T>(xs : [T]) -> Producer<T, ()>
//
//: Combine `for` and `each` to iterate over lists using a "foreach" loop:

runEffect <| for_(each([1...4]), Effect.T.pure • print)

//: `each` is actually more general and works for any `SequenceType`
//
//  public func each<S : SequenceType>(xs : S) -> Producer<S.Generator.Element, ()> {
//

// MARK: - Composability

//: You might wonder why the body of a `for_` loop can be a `Producer`.  Let`s
//: test out this feature by defining a new loop body that `duplicate`s every
//: value:

func duplicate<A>(x : A) -> Producer<A, ()>.T {
	return yield(x) >>- { _ in  yield(x) }
}

let loop = for_(stdinLn(), duplicate)

//: Which is the exact same as:

let loop2 = for_(stdinLn()) { x in
	return yield(x) >>- { _ in  yield(x) }
}

//: This time our @loop@ is a `Producer` that outputs `String`s, specifically
//: two copies of each line that we read from standard input.  Since @loop@ is a
//: `Producer` we cannot run it because there is still unhandled output.
//: However, we can use yet another `for` to handle this new duplicated stream:

runEffect <| for_(loop, Effect<()>.T.pure • print)

//: This creates a program which echoes every line from standard input to
//: standard output twice:
//:
//: But is this really necessary?  Couldn`t we have instead written this using a
//: nested for loop?
	
runEffect <|
	for_(stdinLn()) { str1 in
		return for_(duplicate(str1)) { str2 in
			return Effect<()>.T.pure(print(str2))
		}
	}

//: Yes, we could have!  In fact, this is a special case of the following
//: equality, which always holds no matter what:
//
// let s :      Producer<A, ()>  // i.e. `stdinLn()`
// let f : A -> Producer<B, ()>  // i.e. `duplicate`
// let g : B -> Producer<C, ()>  // i.e. `(Effect<()>.T • print)`
//
// for_(for_(s, f), g) == for_(s, { x in for_(f(x), g) })
//
//: We can understand the rationale behind this equality if we first define the
//: following operator that is the point-free counterpart to `for`:
//
//     func ~> <A, B, C, R>(f : A -> Producer<B, R>.T, g : B -> Producer<C, R>.T) -> (A -> Producer<C, R>.T) {
// 	       return { x in for_(f(x), g) }
//     }
//
//: Using (`~>`) (pronounced "into"), we can transform our original equality
//: into the following more symmetric equation:
//
// let f : A -> Producer<B, R>
// let g : B -> Producer<C, R>
// let h : C -> Producer<D, R>
//
// (f ~> g) ~> h == f ~> (g ~> h)
//
//: This looks just like an associativity law.  In fact, (`~>`) has another nice
//: property, which is that `yield` is its left and right identity:
//
// Left Identity
//     yield ~> f == f
//
// Right Identity
//     f ~> yield == f
//

//: In other words, `yield` and (`~>`) form a `Category`, specifically the
//: generator category, where (`~>`) plays the role of the composition operator
//: and `yield` is the identity.  If you don`t know what a `Category` is, that`s
//: okay, and category theory is not a prerequisite for using @pipes@.  All you
//: really need to know is that @pipes@ uses some simple category theory to keep
//: the API intuitive and easy to use.
//:
//: Notice that if we translate the left identity law to use `for` instead of
//: (`~>`) we get:
//
//     for_(yield(x), f) == f(x)
//
//: This just says that if you iterate over a pure single-element `Producer`,
//: then you could instead cut out the middle man and directly apply the body of
//: the loop to that single element.
//:
//: If we translate the right identity law to use `for` instead of (`~>`) we
//: get:
//
//     for_(s, yield) == s
//
//: This just says that if the only thing you do is re-`yield` every element of
//: a stream, you get back your original stream.

//: These three "for loop" laws summarize our intuition for how `for` loops
//: should behave and because these are `Category` laws in disguise that means
//: that `Producer`s are composable in a rigorous sense of the word.
//:
//: In fact, we get more out of this than just a bunch of equations.  We also
//: get a useful operator: (`~>`).  We can use this operator to condense
//: our original code into the following more succinct form that composes two
//: transformations:

runEffect <| for_(stdinLn(), (duplicate ~> (Effect<()>.T.pure • print)))

//: This means that we can also choose to program in a more functional style and
//: think of stream processing in terms of composing transformations using
//: (`~>`) instead of nesting a bunch of `for` loops.
//:
//: The above example is a microcosm of the design philosophy behind the @pipes@
//: library:
//:
//: * Define the API in terms of categories
//:
//: * Specify expected behavior in terms of category laws
//:
//: * Think compositionally instead of sequentially

