import XCTest
@testable import Ideator

@MainActor
final class IdeaListViewModelDuplicateTests: XCTestCase {
    private var vm: IdeaListViewModel!

    private var prompt: Prompt {
        let suffix = UUID().uuidString.prefix(8)
        return Prompt(
            text: "Duplicate test prompt (suffix)",
            category: .creative,
            suggestedCount: 3,
            slug: "duplicate-test-prompt-(suffix)"
        )
    }

    override func setUp() {
        super.setUp()
        vm = IdeaListViewModel()
        vm.startNewList(with: prompt)
    }

    override func tearDown() {
        if let id = vm.currentIdeaList?.id {
            PersistenceManager.shared.deleteDraft(withId: id)
            PersistenceManager.shared.deleteCompleted(withId: id)
        }
        vm.resetList()
        super.tearDown()
    }

    func testAddIdea_blocksExactDuplicate() {
        vm.addIdea("Solar panels")
        vm.addIdea("Solar panels")

        XCTAssertEqual(vm.ideas, ["Solar panels"])
    }

    func testAddIdea_blocksCaseInsensitiveDuplicate() {
        vm.addIdea("Solar Punk")
        vm.addIdea("solar punk")

        XCTAssertEqual(vm.ideas, ["Solar Punk"])
    }

    func testIsDuplicate_normalizesSurroundingAndInternalWhitespace() {
        vm.addIdea("coffee shop")

        XCTAssertTrue(vm.isDuplicate("  Coffee   shop  "))
    }

    func testIsDuplicate_doesNotFlagEmptyStrings() {
        vm.ideas = ["", "   "]

        XCTAssertFalse(vm.isDuplicate(""))
        XCTAssertFalse(vm.isDuplicate("   "))
    }

    func testIsDuplicate_excludingIndex_allowsOwnValueButBlocksOtherRows() {
        vm.addIdea("First idea")
        vm.addIdea("Second idea")

        XCTAssertFalse(vm.isDuplicate("First idea", excludingIndex: 0))
        XCTAssertTrue(vm.isDuplicate("Second idea", excludingIndex: 0))
    }

    func testAddIdea_appendsNonDuplicate() {
        vm.addIdea("First idea")
        vm.addIdea("Second idea")

        XCTAssertEqual(vm.ideas, ["First idea", "Second idea"])
    }

    func testCheckIfComplete_requiresDistinctIdeas() {
        vm.addIdea("First idea")
        vm.addIdea(" first   idea ")

        XCTAssertFalse(vm.checkIfComplete())
    }
}
