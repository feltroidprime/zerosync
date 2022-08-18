# Validation of Bitcoin Blocks
#
# We do not implement block serialization here because 
# we never hash a block all at once but only its header and transactions.
#
# See also: 
# - Reference: https://developer.bitcoin.org/reference/block_chain.html#block-chain
# - Bitcoin Core: https://github.com/bitcoin/bitcoin/blob/7fcf53f7b4524572d1d0c9a5fdc388e87eb02416/src/primitives/block.h#L22

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from buffer import Reader, Writer, read_varint
from block_header import BlockHeaderValidationContext, ChainState, read_block_header_validation_context, validate_block_header
from transaction import TransactionValidationContext, read_transaction_validation_context
from merkle_tree import compute_merkle_root
from crypto.sha256d.sha256d import assert_hashes_equal, copy_hash, HASH_FELT_SIZE

struct BlockValidationContext:
	member header_context: BlockHeaderValidationContext
	member transactions_count: felt
	member transactions_context: TransactionValidationContext*
end

func read_block_validation_context{reader: Reader, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
	prev_chain_state: ChainState) -> (context: BlockValidationContext*):
	alloc_locals

	let (header_context) = read_block_header_validation_context(prev_chain_state)
	let (transactions_count, _) = read_varint()
	let (transactions_context) = read_transactions_validation_context(transactions_count)

	let (context: BlockValidationContext*) = alloc()
	assert [context] = BlockValidationContext(
		header_context, 
		transactions_count,
		transactions_context
	)
	return (context)
end

func read_transactions_validation_context{reader: Reader, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
	transactions_count) -> (contexts: TransactionValidationContext*):
	alloc_locals
	let (contexts: TransactionValidationContext*) = alloc()
	_read_transactions_validation_context_loop(contexts, transactions_count)
	return (contexts)
end

func _read_transactions_validation_context_loop{reader: Reader, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
	contexts: TransactionValidationContext*, loop_counter):
	if loop_counter == 0:
		return ()
	end
	let (context) = read_transaction_validation_context()
	assert [contexts] = context

	return _read_transactions_validation_context_loop(
		contexts + TransactionValidationContext.SIZE,
		loop_counter - 1
	)
end

func validate_block{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
	context: BlockValidationContext):
	alloc_locals
	# validate_block_header(context.header_context)
	validate_merkle_root(context)
	validate_coinbase(context)
	validate_transactions(context)
	return ()
end

func validate_merkle_root{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
	context: BlockValidationContext):
	alloc_locals
	let (txids) = alloc()
	_copy_txids_into_array_loop(
		context.transactions_context, 
		txids, 
		context.transactions_count
	)
	let (merkle_root) = compute_merkle_root(
		txids, 
		context.transactions_count
	)
	assert_hashes_equal(
		context.header_context.block_header.merkle_root_hash,
		merkle_root
	)
	return()
end

func _copy_txids_into_array_loop(
	tx_context: TransactionValidationContext*, txids: felt*, loop_counter):
	if loop_counter == 0:
		return ()
	end
	copy_hash([tx_context].txid, txids)
	return _copy_txids_into_array_loop(
		tx_context + TransactionValidationContext.SIZE, 
		txids + HASH_FELT_SIZE, 
		loop_counter - 1
	)
end


# Validate that all transactions in this block are valid
func validate_transactions(context: BlockValidationContext):
	# TODO: implement me
	return ()
end


# Validate that the coinbase's output amount is at most 
# the current block reward plus the transaction fees of this block
func validate_coinbase(context: BlockValidationContext):
	# TODO: implement me
	return ()
end



