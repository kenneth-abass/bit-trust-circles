# BitTrust Circles - Decentralized SocialFi Protocol

[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-purple)](https://stacks.co/)
[![Bitcoin](https://img.shields.io/badge/Secured%20by-Bitcoin-orange)](https://bitcoin.org/)

## Overview

BitTrust Circles is a revolutionary social finance (SocialFi) protocol that transforms trust into tradeable digital assets on the Bitcoin ecosystem. Built on Stacks for Bitcoin-grade security with smart contract programmability, the protocol enables communities to stake their social capital, build verifiable reputation, and govern collective decisions through economic incentives.

## Key Features

- **🔒 Stake-to-Play**: Members must stake STX tokens to join circles, creating skin-in-the-game dynamics
- **⭐ Reputation Mining**: Earn reputation tokens through positive social interactions and peer endorsements
- **🗳️ Decentralized Governance**: Community-driven decisions via weighted voting mechanisms
- **💰 Trust Escrow**: Automated stake management with slashing mechanisms for bad actors
- **📈 Social Capital Markets**: Trade and transfer reputation across different trust circles

## System Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Layer    │    │  Governance      │    │  Reputation     │
│                 │    │  Layer           │    │  System         │
│ • Circle Join   │◄──►│ • Proposals      │◄──►│ • Global Rep    │
│ • Staking       │    │ • Voting         │    │ • Endorsements  │
│ • Endorsements  │    │ • Execution      │    │ • Rewards       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         └────────────────────────┼────────────────────────┘
                                  │
                     ┌──────────────────┐
                     │   Core Protocol  │
                     │                  │
                     │ • Trust Circles  │
                     │ • Stake Escrow   │
                     │ • Access Control │
                     └──────────────────┘
                                  │
                     ┌──────────────────┐
                     │  Stacks/Bitcoin  │
                     │                  │
                     │ • STX Transfers  │
                     │ • Block Height   │
                     │ • Security       │
                     └──────────────────┘
```

### Contract Architecture

The BitTrust Circles protocol is implemented as a single comprehensive smart contract with the following components:

#### Core Data Structures

- **Trust Circles**: Registry of all trust circles with metadata and economic parameters
- **Circle Members**: Membership records linking users to circles with stake and reputation data
- **User Reputation**: Global reputation tracking across all circles
- **Escrow Balances**: Secure stake management for each user-circle relationship
- **Governance System**: Proposals and voting records for decentralized decision-making

#### Key Constants & Parameters

```clarity
MIN_CIRCLE_STAKE: 1 STX        // Minimum stake to create a circle
MIN_MEMBER_STAKE: 0.1 STX      // Minimum stake to join a circle
VOTING_PERIOD: 1440 blocks     // ~1 day voting period
QUORUM_THRESHOLD: 60%          // Required participation for proposal execution
```

## Data Flow

### Circle Creation & Joining Flow

```
User Creates Circle
        │
        ▼
┌─────────────────┐
│ Validate Params │
│ • Name length   │
│ • Stake amount  │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Create Circle   │
│ • Generate ID   │
│ • Set metadata  │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Auto-join as    │
│ Founding Member │
└─────────────────┘

User Joins Existing Circle
        │
        ▼
┌─────────────────┐
│ Validate        │
│ • Circle exists │
│ • Not member    │
│ • Sufficient $  │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Transfer Stake  │
│ to Escrow       │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Record Member   │
│ & Update Stats  │
└─────────────────┘
```

### Reputation & Governance Flow

```
Member Actions
        │
        ├─── Endorse Member ────► Update Reputation ────► Global Rep Update
        │
        ├─── Create Proposal ───► Validation ───► Store Proposal
        │
        └─── Vote on Proposal ──► Weight Calculation ───► Update Vote Tally
                                                                │
                                                                ▼
                                                    ┌─────────────────────┐
                                                    │ Proposal Execution  │
                                                    │ • Check quorum      │
                                                    │ • Validate result   │
                                                    │ • Execute action    │
                                                    └─────────────────────┘
```

## Smart Contract Functions

### Circle Management

- `create-circle(name, is-public, stake-threshold)` - Create a new trust circle
- `join-circle(circle-id, stake-amount)` - Join an existing circle by staking STX
- `leave-circle(circle-id)` - Leave a circle and withdraw staked amount

### Reputation System

- `endorse-member(circle-id, target, amount)` - Transfer reputation to another member
- `reward-member(circle-id, target, amount)` - Reward member (governance-controlled)

### Governance Functions

- `create-proposal(circle-id, type, target, amount, description)` - Create governance proposal
- `vote-on-proposal(proposal-id, vote-for)` - Vote on active proposals
- `execute-proposal(proposal-id)` - Execute passed proposals

### Read-Only Functions

- `get-circle-info(circle-id)` - Retrieve circle information
- `get-member-info(circle-id, member)` - Get member details
- `get-user-reputation(user)` - Global reputation data
- `is-member(circle-id, user)` - Check membership status

## Economic Model

### Staking Mechanism

- **Circle Creation**: Requires minimum 1 STX stake
- **Membership**: Minimum 0.1 STX stake per circle
- **Skin in the Game**: Stakes are held in escrow and can be slashed for bad behavior

### Reputation Economics

- **Peer Endorsements**: Members can transfer reputation to each other
- **Activity Rewards**: Automatic reputation bonuses for positive actions
- **Governance Weight**: Voting power = Stake Amount + Reputation Score

### Governance Parameters

- **Voting Period**: 1 day (1440 blocks)
- **Quorum Requirement**: 60% of total staked amount must participate
- **Proposal Types**: Slash, Reward, Kick, Upgrade

## Security Features

- **Input Validation**: Comprehensive parameter validation for all functions
- **Access Control**: Role-based permissions for sensitive operations
- **Escrow Protection**: Automated stake management with controlled withdrawals
- **Slashing Mechanism**: Economic penalties for malicious behavior
- **Time-locked Governance**: Proposals have mandatory voting periods

## Getting Started

### Prerequisites

- Stacks wallet (Xverse, etc.)
- STX tokens for staking
- Basic understanding of Clarity smart contracts

### Deployment

1. Deploy the contract to Stacks testnet/mainnet
2. Initialize with desired economic parameters
3. Create your first trust circle
4. Invite members to join and stake

### Integration

```clarity
;; Example: Check if user is member of circle
(contract-call? .bittrust-circles is-member u1 'SP1234...)

;; Example: Get circle information
(contract-call? .bittrust-circles get-circle-info u1)
```

## Use Cases

- **DAOs**: Decentralized governance with reputation-weighted voting
- **Professional Networks**: Skill verification and endorsement systems
- **Community Curation**: Content moderation through economic incentives
- **Social Gaming**: Reputation-based matchmaking and tournaments
- **DeFi Protocols**: Credit scoring based on social capital

## Roadmap

- [ ] Multi-token support beyond STX
- [ ] Cross-circle reputation bridging
- [ ] Reputation NFT marketplace
- [ ] Mobile SDK for easy integration
- [ ] Analytics dashboard for circle insights

## Contributing

We welcome contributions from the community! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on how to submit pull requests, report issues, and suggest improvements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
