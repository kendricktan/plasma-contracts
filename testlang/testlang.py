from plasma_core.child_chain import ChildChain
from plasma_core.account import EthereumAccount
from plasma_core.block import Block
from plasma_core.transaction import Transaction
from plasma_core.constants import MIN_EXIT_PERIOD, NULL_SIGNATURE, NULL_ADDRESS
from plasma_core.utils.transactions import decode_utxo_id, encode_utxo_id
from plasma_core.utils.address import address_to_hex
from plasma_core.utils.merkle.fixed_merkle import FixedMerkle
import conftest


PREDICATE_VERSION = 1
TX_OUTPUT_TYPE = 1
CONSUMED_TRANSACTION_TYPE = 1


def get_accounts(ethtester):
    """Converts ethereum.tools.tester accounts into a list.

    Args:
        ethtester (ethereum.tools.tester): Ethereum tester instance.

    Returns:
        EthereumAccount[]: A list of EthereumAccounts.
    """

    accounts = []
    for i in range(10):
        address = getattr(ethtester, 'a{0}'.format(i))
        key = getattr(ethtester, 'k{0}'.format(i))
        accounts.append(EthereumAccount(address_to_hex(address), key))
    return accounts


class StandardExit(object):
    """Represents a Plasma exit.

    Attributes:
        owner (str): Address of the exit's owner.
        token (str): Address of the token being exited.
        amount (int): How much value is being exited.
        position (int): UTXO position.
    """

    def __init__(self, owner, token, amount, position=0):
        self.owner = owner
        self.token = token
        self.amount = amount
        self.position = position

    def to_list(self):
        return [self.owner, self.token, self.amount, self.position]

    def __str__(self):
        return self.to_list().__str__()

    def __repr__(self):
        return self.to_list().__repr__()

    def __eq__(self, other):
        if hasattr(other, "to_list"):
            return self.to_list() == other.to_list()
        return (self.to_list() == other) or (self.to_list()[:3] == other)


class PlasmaBlock(object):
    """Represents a Plasma block.

    Attributes:
        root (str): Root hash of the block.
        timestamp (int): Time when the block was created.
    """

    def __init__(self, root, timestamp):
        self.root = root
        self.timestamp = timestamp


class TestingLanguage(object):
    """Represents the testing language.

    Attributes:
        root_chain (ABIContract): Root chain contract instance.
        eththester (tester): Ethereum tester instance.
        accounts (EthereumAccount[]): List of available accounts.
        operator (EthereumAccount): The operator's account.
        child_chain (ChildChain): Child chain instance.
    """

    def __init__(self, root_chain, ethtester):
        self.root_chain = root_chain
        self.ethtester = ethtester
        self.accounts = get_accounts(ethtester)
        self.operator = self.accounts[0]
        self.child_chain = ChildChain(operator=self.operator.address)
        self.events = []

        def gather_events(event):
            all_contract_topics = self.root_chain.translator.event_data.keys()
            if self.root_chain.address is event.address and event.topics[0] in all_contract_topics:
                self.events.append(self.root_chain.translator.decode_event(event.topics, event.data))
        self.ethtester.chain.head_state.log_listeners.append(gather_events)

    def flush_events(self):
        events, self.events = self.events, []
        return events

    def submit_block(self, transactions, signer=None, force_invalid=False):
        signer = signer or self.operator
        blknum = self.root_chain.nextChildBlock()
        block = Block(transactions, number=blknum)
        block.sign(signer.key)
        self.root_chain.submitBlock(block.root, sender=signer.key)
        if force_invalid:
            self.child_chain.blocks[self.child_chain.next_child_block] = block
            self.child_chain.next_deposit_block = self.child_chain.next_child_block + 1
            self.child_chain.next_child_block += self.child_chain.child_block_interval
        else:
            assert self.child_chain.add_block(block)
        return blknum

    @property
    def timestamp(self):
        """Current chain timestamp"""
        return self.ethtester.chain.head_state.timestamp

    def deposit(self, owner, amount):
        deposit_tx = Transaction(outputs=[(owner.address, NULL_ADDRESS, amount)])
        blknum = self.root_chain.getDepositBlockNumber()
        self.root_chain.deposit(deposit_tx.encoded, value=amount)
        deposit_id = encode_utxo_id(blknum, 0, 0)
        block = Block([deposit_tx], number=blknum)
        self.child_chain.add_block(block)
        return deposit_id

    def deposit_token(self, owner, token, amount):
        """Mints, approves and deposits token for given owner and amount

        Args:
            owner (EthereumAccount): Account to own the deposit.
            token (Contract: ERC20, MintableToken): Token to be deposited.
            amount (int): Deposit amount.

        Returns:
            int: Unique identifier of the deposit.
        """

        deposit_tx = Transaction(outputs=[(owner.address, token.address, amount)])
        token.mint(owner.address, amount)
        self.ethtester.chain.mine()
        token.approve(self.root_chain.address, amount, sender=owner.key)
        self.ethtester.chain.mine()
        blknum = self.root_chain.getDepositBlockNumber()
        pre_balance = self.get_balance(self.root_chain, token)
        self.root_chain.depositFrom(deposit_tx.encoded, sender=owner.key)
        balance = self.get_balance(self.root_chain, token)
        assert balance == pre_balance + amount
        block = Block(transactions=[deposit_tx], number=blknum)
        self.child_chain.add_block(block)
        return encode_utxo_id(blknum, 0, 0)

    def spend_utxo(self, input_ids, keys, outputs=None, metadata=None, force_invalid=False):
        if outputs is None:
            outputs = []
        inputs = [decode_utxo_id(input_id) for input_id in input_ids]
        spend_tx = Transaction(inputs=inputs, outputs=outputs, metadata=metadata)
        for i in range(0, len(inputs)):
            spend_tx.sign(i, keys[i])
        blknum = self.submit_block([spend_tx], force_invalid=force_invalid)
        spend_id = encode_utxo_id(blknum, 0, 0)
        return spend_id

    def start_standard_exit(self, output_id, key, bond=None):
        output_tx = self.child_chain.get_transaction(output_id)
        self.start_standard_exit_with_tx_body(output_id, output_tx, key, bond)

    def start_standard_exit_with_tx_body(self, output_id, output_tx, key, bond=None):
        merkle = FixedMerkle(16, [output_tx.encoded])
        proof = merkle.create_membership_proof(output_tx.encoded)
        bond = bond if bond is not None else self.root_chain.standardExitBond()
        self.root_chain.startStandardExit(output_id, output_tx.encoded, proof, value=bond, sender=key)

    def challenge_standard_exit(self, output_id, spend_id, input_index=None):
        spend_tx = self.child_chain.get_transaction(spend_id)
        signature = NULL_SIGNATURE
        if input_index is None:
            for i in range(0, 4):
                signature = spend_tx.signatures[i]
                if spend_tx.inputs[i].identifier == output_id and signature != NULL_SIGNATURE:
                    input_index = i
                    break
        if input_index is None:
            input_index = 3
        exit_id = self.get_standard_exit_id(output_id)
        self.root_chain.challengeStandardExit(exit_id, spend_tx.encoded, input_index, signature)

    def create_utxo(self, token=NULL_ADDRESS):
        class Utxo(object):
            def __init__(self, deposit_id, owner, token, amount, spend, spend_id):
                self.deposit_id = deposit_id
                self.owner = owner
                self.amount = amount
                self.token = token
                self.spend_id = spend_id
                self.spend = spend

        owner, amount = self.accounts[0], 100
        if token == NULL_ADDRESS:
            deposit_id = self.deposit(owner, amount)
            token_address = NULL_ADDRESS
        else:
            deposit_id = self.deposit_token(owner, token, amount)
            token_address = token.address
        spend_id = self.spend_utxo([deposit_id], [owner.key], [(owner.address, token_address, 100)])
        spend = self.child_chain.get_transaction(spend_id)
        return Utxo(deposit_id, owner, token_address, amount, spend, spend_id)

    def start_fee_exit(self, operator, amount, token=NULL_ADDRESS, bond=None):
        """Starts a fee exit.

        Args:
            operator (EthereumAccount): Account to attempt the fee exit.
            amount (int): Amount to exit.

        Returns:
            int: Unique identifier of the exit.
        """

        fee_exit_id = self.root_chain.getFeeExitId(self.root_chain.nextFeeExit())
        bond = bond if bond is not None else self.root_chain.standardExitBond()
        self.root_chain.startFeeExit(token, amount, value=bond, sender=operator.key)
        return fee_exit_id

    def process_exits(self, token, exit_id, count, **kwargs):
        """Finalizes exits that have completed the exit period.

        Args:
            token (address): Address of the token to be processed.
            exit_id (int): Identifier of an exit (optional, pass 0 to ignore the check)
            count (int): Maximum number of exits to be processed.
        """

        self.root_chain.processExits(token, exit_id, count, **kwargs)

    def get_challenge_proof(self, utxo_id, spend_id):
        """Returns information required to submit a challenge.

        Args:
            utxo_id (int): Identifier of the UTXO being exited.
            spend_id (int): Identifier of the transaction that spent the UTXO.

        Returns:
            int, bytes, bytes, bytes: Information necessary to create a challenge proof.
        """

        spend_tx = self.child_chain.get_transaction(spend_id)
        inputs = [(spend_tx.blknum1, spend_tx.txindex1, spend_tx.oindex1), (spend_tx.blknum2, spend_tx.txindex2, spend_tx.oindex2)]
        try:
            input_index = inputs.index(decode_utxo_id(utxo_id))
        except ValueError:
            input_index = 0
        (blknum, _, _) = decode_utxo_id(spend_id)
        block = self.child_chain.blocks[blknum]
        proof = block.merklized_transaction_set.create_membership_proof(spend_tx.merkle_hash)
        sigs = spend_tx.sig1 + spend_tx.sig2
        return input_index, spend_tx.encoded, proof, sigs

    def get_plasma_block(self, blknum):
        """Queries a plasma block by its number.

        Args:
            blknum (int): Plasma block number to query.

        Returns:
            PlasmaBlock: Formatted plasma block information.
        """

        block_info = self.root_chain.blocks(blknum)
        return PlasmaBlock(*block_info)

    def get_standard_exit(self, utxo_pos):
        """Queries a plasma exit by its ID.

        Args:
            utxo_pos (int): position of utxo being exited

        Returns:
            tuple: (owner (address), token (address), amount (int))
        """

        exit_id = self.get_standard_exit_id(utxo_pos)
        exit_info = self.root_chain.exits(exit_id)
        return StandardExit(*exit_info)

    def get_standard_exit_id(self, utxo_pos):
        tx = self.child_chain.get_transaction(utxo_pos)
        return self.root_chain.getStandardExitId(tx.encoded, utxo_pos)

    def get_balance(self, account, token=NULL_ADDRESS):
        """Queries ETH or token balance of an account.

        Args:
            account (EthereumAccount): Account to query,
            token (str OR ABIContract OR NULL_ADDRESS):
                MintableToken contract: its address or ABIContract representation.

        Returns:
            int: The account's balance.
        """
        if token == NULL_ADDRESS:
            return self.ethtester.chain.head_state.get_balance(account.address)
        if hasattr(token, "balanceOf"):
            return token.balanceOf(account.address)
        else:
            token_contract = conftest.watch_contract(self.ethtester, 'MintableToken', token)
            return token_contract.balanceOf(account.address)

    def forward_timestamp(self, amount):
        """Forwards the chain's timestamp.

        Args:
            amount (int): Number of seconds to move forward time.
        """

        self.ethtester.chain.head_state.timestamp += amount

    def get_merkle_proof(self, tx_id):
        tx = self.child_chain.get_transaction(tx_id)
        (blknum, _, _) = decode_utxo_id(tx_id)
        block = self.child_chain.get_block(blknum)
        merkle = block.merklized_transaction_set
        return merkle.create_membership_proof(tx.encoded)

    @staticmethod
    def find_shared_input(tx_a, tx_b):
        tx_a_input_index = 0
        tx_b_input_index = 0
        for i in range(0, 4):
            for j in range(0, 4):
                tx_a_input = tx_a.inputs[i].identifier
                tx_b_input = tx_b.inputs[j].identifier
                if tx_a_input == tx_b_input and tx_a_input != 0:
                    tx_a_input_index = i
                    tx_b_input_index = j
        return tx_a_input_index, tx_b_input_index

    @staticmethod
    def find_input_index(output_id, tx_b):
        tx_b_input_index = 0
        for i in range(0, 4):
            tx_b_input = tx_b.inputs[i].identifier
            if tx_b_input == output_id:
                tx_b_input_index = i
        return tx_b_input_index

    def forward_to_period(self, period):
        self.forward_timestamp((period - 1) * MIN_EXIT_PERIOD)

    def register_output_predicate(self, output_predicate):
        self.root_chain.registerTxOutputPredicate(TX_OUTPUT_TYPE, CONSUMED_TRANSACTION_TYPE, output_predicate.address, PREDICATE_VERSION)

    def register_exit_processor(self, exit_processor):
        self.root_chain.registerExitProcessor(CONSUMED_TRANSACTION_TYPE, exit_processor.address, PREDICATE_VERSION)

    def register_exit_game(self, exit_game):
        self.root_chain.registerExitGame(CONSUMED_TRANSACTION_TYPE, exit_game.address, PREDICATE_VERSION)

