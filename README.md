# StackVaultTrade README

## Overview

**StackVaultTrade** is a comprehensive Clarity smart contract for the Stacks blockchain that combines three core functionalities: a decentralized STX vault, a staking system with rewards, and a peer-to-peer trading platform.

## Features

###  Vault System
- **Deposit**: Users can deposit STX into their personal vault
- **Withdraw**: Withdraw STX from vault to wallet
- **Balance Tracking**: Real-time balance queries for any user

###  Staking Mechanism
- **Stake Funds**: Lock STX to earn rewards
- **10% Rewards**: Claim 10% of staked amount as reward
- **One Stake Per User**: Users can only maintain one active stake at a time
- **Reward Claiming**: Claim accumulated rewards with a single transaction

###  P2P Trading
- **Create Trade Orders**: Sellers can create trade offers with a specified price
- **Accept Trades**: Buyers can accept trade orders and send payment
- **Cancel Orders**: Sellers can cancel active trade orders
- **Trade Tracking**: View all trade order details and status

###  Admin Controls
- **Role-Based Access**: Set admin permissions
- **Admin Management**: Current admin can transfer admin role to another principal

## Contract Functions

### Public Functions

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `set-admin` | `new-admin: principal` | `principal` | Transfer admin role |
| `deposit` | `amount: uint` | `uint` | Deposit STX to vault |
| `withdraw` | `amount: uint` | `uint` | Withdraw STX from vault |
| `stake` | `amount: uint` | `string` | Lock STX for rewards |
| `claim-reward` | — | `uint` | Claim 10% reward on stake |
| `create-trade` | `price: uint` | `uint` | Create new trade order |
| `accept-trade` | `id: uint` | `string` | Accept and execute trade |
| `cancel-trade` | `id: uint` | `string` | Cancel active trade order |

### Read-Only Functions

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `get-balance` | `user: principal` | `uint` | Query user vault balance |
| `get-stake` | `user: principal` | `{amount, reward, active}` | Query user stake details |
| `get-order` | `id: uint` | `{seller, buyer, price, active}` | Query trade order details |
| `get-total-orders` | — | `uint` | Get total orders created |
| `get-admin` | — | `principal` | Get current admin |

## Error Codes

| Error | Code | Description |
|-------|------|-------------|
| `ERR_NOT_ENOUGH_FUNDS` | u100 | Insufficient balance for operation |
| `ERR_UNAUTHORIZED` | u101 | Caller lacks required permissions |
| `ERR_ALREADY_STAKED` | u102 | User already has an active stake |
| `ERR_NOT_STAKED` | u103 | User has no active stake |
| `ERR_INVALID_AMOUNT` | u104 | Invalid amount provided |
| `ERR_NO_SUCH_ORDER` | u105 | Trade order does not exist |

## Usage Example

```clarity
;; Deposit 1000 STX
(deposit u1000)

;; Stake 500 STX
(stake u500)

;; Claim 10% reward (50 STX)
(claim-reward)

;; Create a trade order for 100 STX
(create-trade u100)

;; Accept a trade order
(accept-trade u1)

;; Check balance
(get-balance tx-sender)
```

## Data Structures

- **user-balances**: Maps user principals to their vault balance
- **user-stakes**: Stores staking data (amount, reward, active status)
- **trade-orders**: Maps order IDs to trade details (seller, buyer, price, active status)

## State Variables

- `total-orders`: Counter for total trade orders created
- `total-staked`: Aggregate amount of all STX staked
- `admin`: Current contract administrator

## Security Considerations

- Only authorized admins can set new admin roles
- Users must have sufficient vault balance to stake
- One active stake per user prevents double-staking
- Only sellers can cancel their own trade orders
- All STX transfers are atomic and validated

## License

This contract is part of the StackVaultTrade project.
