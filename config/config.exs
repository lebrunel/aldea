import Config

# The hash function will be invoked as `B3.hash(payload, length: 64)`
config :eddy, hash_fn: {B3, :hash, [], [[length: 64]]}
