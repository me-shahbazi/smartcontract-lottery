# Lottery Smart Contract

A brownie project

1. Users can enter lottery with ETH based on a USD fee. (ChainLink DataFeed)
2. An admin will choose when the lottery is over.
3. The lottery will select a random winner.

## Testing Solutions

1. mainnet-fork (using Infura or Alchemy)
2. development with mocks (deploy mock Contracts)
3. testnet (fuji, sepolia, ...)

## ChainLink VRF

Request and Receive cycle.

1. Submits a randomness request to Chainlink VRF.
2. The fullfill function that the Oracle uses to send the result back.
3. Useing Random Value.

