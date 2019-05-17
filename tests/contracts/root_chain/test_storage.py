
def test_submit_block(ethtester, testlang):
    submitter = testlang.accounts[0]
    assert testlang.root_chain.nextChildBlock() == 1000
    blknum = testlang.submit_block([], submitter)

    block_info = testlang.root_chain.blocks(1000)
    assert block_info[0] == testlang.child_chain.get_block(blknum).root
    assert block_info[1] == ethtester.chain.head_state.timestamp
    assert testlang.root_chain.nextChildBlock() == 2000
