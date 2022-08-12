from sha256.sha256 import compute_sha256
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_le
from starkware.cairo.common.math import split_felt, unsigned_div_rem
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.memcpy import memcpy

# A 256-bit hash is represented as an array of 8 x Uint32
const HASH_LEN = 8
# A hash has 32 bytes
const N_BYTES_HASH = 32

# Convert an array of 8 x Uint32 to an Uint256
func array_to_uint256(array: felt*) -> (result: Uint256):
    let low  = array[0] * 2**96 + array[1] * 2**64 + array[2] * 2**32 + array[3]
    let high = array[4] * 2**96 + array[5] * 2**64 + array[6] * 2**32 + array[7]
    let result = Uint256(low, high)
    return (result)
end

func _compute_double_sha256{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
    input_len : felt, input : felt*, n_bytes : felt
) -> (result : felt*):
    alloc_locals
    let (hash_first_round) = compute_sha256(input_len, input, n_bytes)
    let (hash_second_round) = compute_sha256(HASH_LEN, hash_first_round, N_BYTES_HASH)
    return (hash_second_round)
end

# Compute double sha256 hash of the input given as an array of Uint32 
# and returns a Uint256.
func compute_double_sha256{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
    input_len : felt, input : felt*, n_bytes : felt
) -> (result : Uint256):
    alloc_locals
    let (hash) = _compute_double_sha256(input_len, input, n_bytes)
    let (result) = array_to_uint256(hash)
    return (result)
end

# Convert a felt into a Uint256
func to_uint256{range_check_ptr}(input: felt) -> (output: Uint256):
    let (high, low) = split_felt(input)
    let result = Uint256(low, high)
    return (result)
end

# Convert Uint32 to big endian
func to_big_endian{bitwise_ptr : BitwiseBuiltin*}(a : felt) -> (result : felt):
    let (byte1) = bitwise_and(a, 0x000000FF)
    let (byte2) = bitwise_and(a, 0x0000FF00)
    let (byte3) = bitwise_and(a, 0x00FF0000)
    let (byte4) = bitwise_and(a, 0xFF000000)
    let result = byte1 * 2**24 + byte2 * 2**8 + byte3 / 2**8 + byte4 / 2**24
    return (result)
end

# Copy a hash represented as 8 x Uint32. 
# Starts reading at `source` and writes to `destination`
func copy_hash(source: felt*, destination: felt*):
    memcpy(destination, source, HASH_LEN)
    return ()
end

# Assert equality of two hashes represented as an array of 8 x Uint32
func assert_hashes_equal(hash1: felt*, hash2: felt*):
    assert hash1[0] = hash2[0]
    assert hash1[1] = hash2[1]
    assert hash1[2] = hash2[2]
    assert hash1[3] = hash2[3]
    assert hash1[4] = hash2[4]
    assert hash1[5] = hash2[5]
    assert hash1[6] = hash2[6]
    assert hash1[7] = hash2[7]
    return ()
end