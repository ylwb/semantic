final class LocationTests: XCTestCase {
	func testExplorationOfATermBeginsAtTheExploredTerm() {
		assert(term.explore().it, ==, term)
	}

	func testCannotMoveUpwardsAtTheStartOfAnExploration() {
		assert(term.explore().up?.it, ==, nil)
	}

	func testCannotMoveSidewaysAtTheStartOfAnExploration() {
		assert(term.explore().left?.it, ==, nil)
		assert(term.explore().right?.it, ==, nil)
	}

	func testCannotMoveDownwardsFromLeaves() {
		assert(leafA.explore().down?.it, ==, nil)
	}

	func testCanMoveDownwardsIntoBranches() {
		assert(term.explore().down?.it, ==, leafA)
	}

	func testCanMoveBackUpwards() {
		assert(term.explore().down?.up?.it, ==, term)
	}

	func testCannotMoveLeftwardsFromFirstChildOfBranch() {
		assert(term.explore().down?.left?.it, ==, nil)
	}

	func testCanMoveRightwardsFromLeftmostChildOfLongBranch() {
		assert(term.explore().down?.right?.it, ==, leafB)
	}
}


private let leafA = Cofree(1, .Leaf("a string"))
private let leafB = Cofree(2, .Leaf("b string"))
private let innerLeaf = Cofree(4, .Leaf("a nested string"))
private let keyed = Cofree(3, .Keyed([
	"a": innerLeaf,
	"b": Cofree(5, .Leaf("b nested string")),
]))
private let term: Cofree<String, Int> = Cofree(0, .Indexed([
	leafA,
	leafB,
	keyed,
]))


import Assertions
@testable import Doubt
import XCTest
