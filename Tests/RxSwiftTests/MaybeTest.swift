//
//  MaybeTest.swift
//  Tests
//
//  Created by Krunoslav Zaher on 9/17/17.
//  Copyright © 2017 Krunoslav Zaher. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class MaybeTest : RxTest {

}

// maybe
extension MaybeTest {
    func testMaybe_Subscription_success() {
        let xs = Maybe.just(1)

        var events: [MaybeEvent<Int>] = []

        _ = xs.subscribe { event in
            events.append(event)
        }

        XCTAssertEqual(events, [.success(1)])
    }

    func testMaybe_Subscription_completed() {
        let xs = Maybe<Int>.empty()

        var events: [MaybeEvent<Int>] = []

        _ = xs.subscribe { event in
            events.append(event)
        }

        XCTAssertEqual(events, [.completed])
    }

    func testMaybe_Subscription_error() {
        let xs = Maybe<Int>.error(testError)

        var events: [MaybeEvent<Int>] = []

        _ = xs.subscribe { event in
            events.append(event)
        }

        XCTAssertEqual(events, [.error(testError)])
    }

    func testMaybe_create_success() {
        let scheduler = TestScheduler(initialClock: 0)

        var observer: ((MaybeEvent<Int>) -> ())! = nil

        var disposedTime: Int? = nil

        scheduler.scheduleAt(201, action: {
            observer(.success(1))
        })
        scheduler.scheduleAt(202, action: {
            observer(.success(1))
        })
        scheduler.scheduleAt(203, action: {
            observer(.error(testError))
        })
        scheduler.scheduleAt(204, action: {
            observer(.completed)
        })

        let res = scheduler.start {
            Maybe<Int>.create { _observer in
                observer = _observer
                return Disposables.create {
                    disposedTime = scheduler.clock
                }
                }.asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(201, 1),
            .completed(201)
            ])

        XCTAssertEqual(disposedTime, 201)
    }

    func testMaybe_create_completed() {
        let scheduler = TestScheduler(initialClock: 0)

        var observer: ((MaybeEvent<Int>) -> ())! = nil

        var disposedTime: Int? = nil

        scheduler.scheduleAt(201, action: {
            observer(.completed)
        })
        scheduler.scheduleAt(202, action: {
            observer(.success(1))
        })
        scheduler.scheduleAt(203, action: {
            observer(.error(testError))
        })
        scheduler.scheduleAt(204, action: {
            observer(.completed)
        })

        let res = scheduler.start {
            Maybe<Int>.create { _observer in
                observer = _observer
                return Disposables.create {
                    disposedTime = scheduler.clock
                }
                }.asObservable()
        }

        XCTAssertEqual(res.events, [
            .completed(201)
            ])

        XCTAssertEqual(disposedTime, 201)
    }

    func testMaybe_create_error() {
        let scheduler = TestScheduler(initialClock: 0)

        var observer: ((MaybeEvent<Int>) -> ())! = nil

        var disposedTime: Int? = nil

        scheduler.scheduleAt(201, action: {
            observer(.error(testError))
        })
        scheduler.scheduleAt(202, action: {
            observer(.success(1))
        })
        scheduler.scheduleAt(203, action: {
            observer(.error(testError))
        })

        let res = scheduler.start {
            Maybe<Int>.create { _observer in
                observer = _observer
                return Disposables.create {
                    disposedTime = scheduler.clock
                }
                }.asObservable()
        }

        XCTAssertEqual(res.events, [
            .error(201, testError)
            ])

        XCTAssertEqual(disposedTime, 201)
    }

    func testMaybe_create_disposing() {
        let scheduler = TestScheduler(initialClock: 0)

        var observer: ((MaybeEvent<Int>) -> ())! = nil
        var disposedTime: Int? = nil
        var subscription: Disposable! = nil
        let res = scheduler.createObserver(Int.self)

        scheduler.scheduleAt(201, action: {
            subscription = Maybe<Int>.create { _observer in
                observer = _observer
                return Disposables.create {
                    disposedTime = scheduler.clock
                }
                }
                .asObservable()
                .subscribe(res)
        })
        scheduler.scheduleAt(202, action: {
            subscription.dispose()
        })
        scheduler.scheduleAt(203, action: {
            observer(.success(1))
        })
        scheduler.scheduleAt(204, action: {
            observer(.error(testError))
        })

        scheduler.start()

        XCTAssertEqual(res.events, [
            ])

        XCTAssertEqual(disposedTime, 202)
    }
}

extension MaybeTest {
    func test_just_producesElement() {
        let result = try! (Maybe.just(1) as Maybe<Int>).toBlocking().first()!
        XCTAssertEqual(result, 1)
    }

    func test_just2_producesElement() {
        let result = try! (Maybe.just(1, scheduler: CurrentThreadScheduler.instance) as Maybe<Int>).toBlocking().first()!
        XCTAssertEqual(result, 1)
    }

    func test_error_fails() {
        do {
            _ = try (Maybe<Int>.error(testError) as Maybe<Int>).toBlocking().first()
            XCTFail()
        }
        catch let e {
            XCTAssertEqual(e as! TestError, testError)
        }
    }

    func test_never_producesElement() {
        var event: MaybeEvent<Int>? = nil
        let subscription = (Maybe<Int>.never() as Maybe<Int>).subscribe { _event in
            event = _event
        }

        XCTAssertNil(event)
        subscription.dispose()
    }

    func test_deferred() {
        let result = try! (Maybe.deferred { Maybe.just(1) } as Maybe<Int>).toBlocking().toArray()
        XCTAssertEqual(result, [1])
    }

    func test_delaySubscription() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe.just(1).delaySubscription(2.0, scheduler: scheduler) as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(202, 1),
            .completed(202)
            ])
    }

    func test_delay() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe.just(1).delay(2.0, scheduler: scheduler) as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(202, 1),
            .completed(203)
            ])
    }

    func test_observeOn() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe.just(1).observeOn(scheduler) as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(201, 1),
            .completed(202)
            ])
    }

    func test_subscribeOn() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe.just(1).subscribeOn(scheduler) as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(201, 1),
            .completed(201)
            ])
    }

    func test_catchError() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe.error(testError).catchError { _ in Maybe.just(2) } as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(200, 2),
            .completed(200)
            ])
    }

    func test_retry() {
        let scheduler = TestScheduler(initialClock: 0)

        var isFirst = true
        let res = scheduler.start {
            (Maybe.error(testError)
                .catchError { e in
                    defer {
                        isFirst = false
                    }
                    if isFirst {
                        return Maybe.error(e)
                    }

                    return Maybe.just(2)
                }
                .retry(2) as Maybe<Int>
            ).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(200, 2),
            .completed(200)
            ])
    }

    func test_retryWhen1() {
        let scheduler = TestScheduler(initialClock: 0)

        var isFirst = true
        let res = scheduler.start {
            (Maybe.error(testError)
                .catchError { e in
                    defer {
                        isFirst = false
                    }
                    if isFirst {
                        return Maybe.error(e)
                    }

                    return Maybe.just(2)
                }
                .retryWhen { (e: Observable<Error>) in
                    return e
                } as Maybe<Int>
            ).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(200, 2),
            .completed(200)
            ])
    }

    func test_retryWhen2() {
        let scheduler = TestScheduler(initialClock: 0)

        var isFirst = true
        let res = scheduler.start {
            (Maybe.error(testError)
                .catchError { e in
                    defer {
                        isFirst = false
                    }
                    if isFirst {
                        return Maybe.error(e)
                    }

                    return Maybe.just(2)
                }
                .retryWhen { (e: Observable<TestError>) in
                    return e
                } as Maybe<Int>
            ).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(200, 2),
            .completed(200)
            ])
    }

    func test_debug() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe.just(1).debug() as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(200, 1),
            .completed(200)
            ])
    }

    func test_using() {
        let scheduler = TestScheduler(initialClock: 0)

        var disposeInvoked = 0
        var createInvoked = 0

        var disposable: MockDisposable!
        var xs: TestableObservable<Int>!
        var _d: MockDisposable!

        let res = scheduler.start {
            Maybe.using({ () -> MockDisposable in
                disposeInvoked += 1
                disposable = MockDisposable(scheduler: scheduler)
                return disposable
            }, primitiveSequenceFactory: { (d: MockDisposable) -> Maybe<Int> in
                _d = d
                createInvoked += 1
                xs = scheduler.createColdObservable([
                    .next(100, scheduler.clock),
                    .completed(100)
                    ])
                return xs.asObservable().asMaybe()
            }).asObservable()
        }

        XCTAssert(disposable === _d)

        XCTAssertEqual(1, createInvoked)
        XCTAssertEqual(1, disposeInvoked)

        XCTAssertEqual(res.events, [
            .next(300, 200),
            .completed(300)
            ])

        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 300)
            ])

        XCTAssertEqual(disposable.ticks, [
            200,
            300
            ])
    }

    func test_timeout() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createColdObservable([
            .next(10, 1),
            .completed(20)
            ]).asMaybe()

        let res = scheduler.start {
            (xs.timeout(5.0, scheduler: scheduler) as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .error(205, RxError.timeout)
            ])
    }

    func test_timeout_other() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createColdObservable([
            .next(10, 1),
            .completed(20)
        ]).asMaybe()

        let xs2 = scheduler.createColdObservable([
            .next(20, 2),
            .completed(20)
        ]).asMaybe()

        let res = scheduler.start {
            (xs.timeout(5.0, other: xs2, scheduler: scheduler) as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(225, 2),
            .completed(225)
            ])
    }

    func test_timeout_succeeds() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createColdObservable([
            .next(10, 1),
            .completed(20)
        ]).asMaybe()

        let res = scheduler.start {
            (xs.timeout(30.0, scheduler: scheduler) as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(220, 1),
            .completed(220)
            ])
    }

    func test_timeout_other_succeeds() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createColdObservable([
            .next(10, 1),
            .completed(20)
        ]).asMaybe()

        let xs2 = scheduler.createColdObservable([
            .next(20, 2),
            .completed(20)
        ]).asMaybe()

        let res = scheduler.start {
            (xs.timeout(30.0, other: xs2, scheduler: scheduler) as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(220, 1),
            .completed(220)
            ])
    }
}

extension MaybeTest {
    func test_timer() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe<Int>.timer(2, scheduler: scheduler) as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(202, 0),
            .completed(202)
            ])
    }
}

extension MaybeTest {
    func test_do() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe<Int>.just(1).do(onNext: { _ in () }, onError: { _ in () }, onSubscribe: { () in () }, onSubscribed: { () in () }, onDispose: { () in () }) as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(200, 1),
            .completed(200)
            ])
    }

    func test_filter() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe<Int>.just(1).filter { _ in false } as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .completed(200)
            ])
    }

    func test_map() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe<Int>.just(1).map { $0 * 2 } as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(200, 2),
            .completed(200)
            ])
    }

    func test_flatMap() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe<Int>.just(1).flatMap { .just($0 * 2) } as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(200, 2),
            .completed(200)
            ])
    }
}

extension MaybeTest {
    func test_zip_tuple() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe.zip(Maybe.just(1), Maybe.just(2)) as Maybe<(Int, Int)>).map { $0.0 + $0.1 }.asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(200, 3),
            .completed(200)
            ])
    }

    func test_zip_resultSelector() {
        let scheduler = TestScheduler(initialClock: 0)

        let res = scheduler.start {
            (Maybe.zip(Maybe.just(1), Maybe.just(2)) { $0 + $1 } as Maybe<Int>).asObservable()
        }

        XCTAssertEqual(res.events, [
            .next(200, 3),
            .completed(200)
            ])
    }
}

extension MaybeTest {
    func testDefaultErrorHandler() {
        var loggedErrors = [TestError]()

        _ = Maybe<Int>.error(testError).subscribe()
        XCTAssertEqual(loggedErrors, [])

        let originalErrorHandler = Hooks.defaultErrorHandler

        Hooks.defaultErrorHandler = { _, error in
            loggedErrors.append(error as! TestError)
        }

        _ = Maybe<Int>.error(testError).subscribe()
        XCTAssertEqual(loggedErrors, [testError])

        Hooks.defaultErrorHandler = originalErrorHandler

        _ = Maybe<Int>.error(testError).subscribe()
        XCTAssertEqual(loggedErrors, [testError])
    }
}



