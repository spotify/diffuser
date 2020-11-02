import Diffuser
import XCTest
import SwiftCheck

class FuseableTests: XCTestCase {
    func testFuseableEmitsEventsWhenConnected() {
        var outputs: [String] = []
        let fuseable = FakeFuseable()
        let disposable = Fuser.fromFuseable(fuseable).connect { output in
            outputs.append(output)
        }

        fuseable.output.send("1")
        fuseable.output.send("2")
        fuseable.output.send("3")

        XCTAssertEqual(["1", "2", "3"], outputs)

        disposable.dispose()
    }

    func testOutputSentBeforeConnectingIsDropped() {
        var outputs: [String] = []
        let fuseable = FakeFuseable()

        fuseable.output.send("1")

        let disposable = Fuser.fromFuseable(fuseable).connect { output in
            outputs.append(output)
        }

        XCTAssertEqual([], outputs)

        disposable.dispose()
    }

    func testOutputSentAfterDisposingIsDropped() {
        var outputs: [String] = []
        let fuseable = FakeFuseable()
        Fuser.fromFuseable(fuseable).connect { output in
            outputs.append(output)
        }.dispose()

        fuseable.output.send("1")

        XCTAssertEqual([], outputs)
    }

    func testMultipleConnectionsAreSupported() {
          let fuseable = FakeFuseable()

          var outputs1: [String] = []
          let disposable1 = Fuser.fromFuseable(fuseable).connect { output in
              outputs1.append(output)
          }
          var outputs2: [String] = []
          let disposable2 = Fuser.fromFuseable(fuseable).connect { output in
              outputs2.append(output)
          }

          fuseable.output.send("1")
          fuseable.output.send("2")

          XCTAssertEqual(outputs1, ["1", "2"])
          XCTAssertEqual(outputs2, ["1", "2"])

          disposable1.dispose()
          disposable2.dispose()
      }

      func testMultipleConnectionsCanBeDisposedIndependently() {
          var outputs1: [String] = []
          let fuseable = FakeFuseable()
          let disposable1 = Fuser.fromFuseable(fuseable).connect { output in
              outputs1.append(output)
          }
          var outputs2: [String] = []
          let disposable2 = Fuser.fromFuseable(fuseable).connect { output in
              outputs2.append(output)
          }

          disposable2.dispose()

          fuseable.output.send("1")
          XCTAssertEqual(["1"], outputs1)
          XCTAssertEqual([], outputs2)

          disposable1.dispose()
      }

}

private class FakeFuseable: Fuseable {
    let output = Output<String>()
}
