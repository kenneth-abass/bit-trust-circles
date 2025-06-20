;; BitTrust Circles - A Decentralized SocialFi Protocol on Stacks/Bitcoin
;;
;; Summary:
;; A revolutionary social finance protocol that transforms trust into tradeable digital assets
;; on the Bitcoin ecosystem. BitTrust Circles enables communities to stake their social 
;; capital, build verifiable reputation, and govern collective decisions through economic incentives.
;;
;; Description:
;; BitTrust Circles creates a new paradigm for social interaction on Bitcoin's layer 2,
;; where trust becomes quantifiable and reputation becomes valuable. Users form exclusive
;; trust circles by staking STX tokens, creating skin-in-the-game dynamics that incentivize
;; honest behavior and meaningful relationships. The protocol features:
;;
;; - Stake-to-Play: Members must stake STX to join circles, aligning economic incentives
;; - Reputation Mining: Earn reputation tokens through positive social interactions
;; - Decentralized Governance: Community-driven decisions via weighted voting mechanisms
;; - Trust Escrow: Automated stake management with slashing for bad actors
;; - Social Capital Markets: Trade and transfer reputation across different circles
;;
;; Built on Stacks for Bitcoin-grade security with smart contract programmability,
;; BitTrust Circles bridges the gap between social networks and decentralized finance,
;; creating the first truly economically-aligned social protocol on Bitcoin.

;; CONSTANTS & ERROR CODES

(define-constant CONTRACT_OWNER tx-sender)

;; Error codes with descriptive names
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_INVALID_PARAMS (err u400))
(define-constant ERR_CIRCLE_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_MEMBER (err u409))
(define-constant ERR_NOT_MEMBER (err u403))
(define-constant ERR_INSUFFICIENT_STAKE (err u402))
(define-constant ERR_INSUFFICIENT_BALANCE (err u405))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u406))
(define-constant ERR_VOTING_CLOSED (err u407))
(define-constant ERR_ALREADY_VOTED (err u408))
(define-constant ERR_INVALID_VOTE (err u410))
(define-constant ERR_PROPOSAL_EXPIRED (err u411))

;; Economic parameters
(define-constant MIN_CIRCLE_STAKE u1000000) ;; 1 STX in microSTX
(define-constant MIN_MEMBER_STAKE u100000)  ;; 0.1 STX in microSTX

;; Governance parameters
(define-constant VOTING_PERIOD u1440)      ;; ~1 day in blocks (10min blocks)
(define-constant QUORUM_THRESHOLD u60)     ;; 60% quorum required for proposals

;; DATA STRUCTURES

;; Trust Circle Configuration
(define-map circles
  { circle-id: uint }
  {
    name: (string-ascii 64),
    creator: principal,
    is-public: bool,
    stake-threshold: uint,
    total-staked: uint,
    member-count: uint,
    created-at: uint,
    reputation-weight: uint
  }
)

;; Circle Membership Registry
(define-map circle-members
  { circle-id: uint, member: principal }
  {
    stake-amount: uint,
    reputation-score: uint,
    joined-at: uint,
    last-activity: uint,
    is-active: bool
  }
)

;; Global Reputation System
(define-map user-reputation
  { user: principal }
  {
    total-reputation: uint,
    circles-joined: uint,
    total-staked: uint,
    last-updated: uint
  }
)

;; Stake Escrow Management
(define-map escrow-balances
  { user: principal, circle-id: uint }
  { amount: uint }
)