from plasma_core.constants import NULL_ADDRESS, NULL_ADDRESS_HEX, MIN_EXIT_PERIOD


def test_process_exits_standard_exit_should_succeed(testlang):
    owner, amount = testlang.accounts[0], 100
    deposit_id = testlang.deposit(owner, amount)
    spend_id = testlang.spend_utxo([deposit_id], [owner.key], [(owner.address, NULL_ADDRESS, amount)])

    pre_balance = testlang.get_balance(owner)
    testlang.flush_events()

    testlang.start_standard_exit(spend_id, owner.key)
    [exit_event] = testlang.flush_events()
    assert {"owner": owner.address, "_event_type": b'ExitStarted'}.items() <= exit_event.items()

    testlang.forward_timestamp(2 * MIN_EXIT_PERIOD + 1)
    testlang.process_exits(NULL_ADDRESS, 0, 100)
    [exit_finalized] = testlang.flush_events()
    assert {"exitId": exit_event['exitId'], "_event_type": b'ExitFinalized'}.items() <= exit_finalized.items()

    standard_exit = testlang.get_standard_exit(spend_id)
    assert standard_exit.owner == NULL_ADDRESS_HEX
    assert standard_exit.token == NULL_ADDRESS_HEX
    assert standard_exit.amount == 100
    assert testlang.get_balance(owner) == pre_balance + amount
