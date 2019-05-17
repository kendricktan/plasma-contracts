from plasma_core.utils.merkle.fixed_merkle import FixedMerkle


def test_ethereum_deposit_should_succeed(ethtester, testlang):
    owner, amount = testlang.accounts[0], 100
    deposit_id = testlang.deposit(owner, amount)
    deposit_tx = testlang.child_chain.get_transaction(deposit_id)

    merkle = FixedMerkle(16, [deposit_tx.encoded])

    assert testlang.root_chain.blocks(1) == [merkle.root, ethtester.chain.head_state.timestamp]
    assert testlang.root_chain.nextDepositBlock() == 2


def test_token_deposit_should_succeed(ethtester, testlang):
    pass
