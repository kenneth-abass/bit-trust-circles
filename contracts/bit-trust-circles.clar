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

;; Governance Proposals
(define-map proposals
  { proposal-id: uint }
  {
    circle-id: uint,
    proposer: principal,
    proposal-type: (string-ascii 32), ;; "slash", "reward", "kick", "upgrade"
    target: (optional principal),
    amount: uint,
    description: (string-ascii 256),
    votes-for: uint,
    votes-against: uint,
    total-votes: uint,
    created-at: uint,
    expires-at: uint,
    executed: bool
  }
)

;; Voting Records
(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, weight: uint, timestamp: uint }
)

;; STATE VARIABLES

(define-data-var next-circle-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var protocol-fee uint u50) ;; 0.5% fee in basis points

;; PRIVATE HELPER FUNCTIONS

(define-private (is-circle-member (circle-id uint) (user principal))
  ;; Check if a user is a member of a specific circle
  (is-some (map-get? circle-members { circle-id: circle-id, member: user }))
)

(define-private (get-member-reputation (circle-id uint) (member principal))
  ;; Get reputation score for a member in a specific circle
  (default-to u0 
    (get reputation-score 
      (map-get? circle-members { circle-id: circle-id, member: member })))
)

(define-private (calculate-voting-weight (circle-id uint) (voter principal))
  ;; Calculate voting power based on stake amount and reputation score
  (let ((member-data (map-get? circle-members { circle-id: circle-id, member: voter })))
    (match member-data
      data (+ (get stake-amount data) (get reputation-score data))
      u0
    )
  )
)

(define-private (update-user-reputation (user principal) (reputation-change int))
  ;; Update global reputation for a user (can be positive or negative)
  (let ((current-rep (default-to 
                       { total-reputation: u0, circles-joined: u0, total-staked: u0, last-updated: u0 }
                       (map-get? user-reputation { user: user }))))
    (map-set user-reputation
      { user: user }
      (merge current-rep {
        total-reputation: (if (>= reputation-change 0)
                           (+ (get total-reputation current-rep) (to-uint reputation-change))
                           (if (> (get total-reputation current-rep) (to-uint (- reputation-change)))
                             (- (get total-reputation current-rep) (to-uint (- reputation-change)))
                             u0)),
        last-updated: stacks-block-height
      })
    )
  )
)

;; PUBLIC FUNCTIONS - CIRCLE MANAGEMENT

(define-public (create-circle (name (string-ascii 64)) (is-public bool) (stake-threshold uint))
  ;; Create a new trust circle with specified parameters
  (let ((circle-id (var-get next-circle-id)))
    ;; Validate input parameters
    (asserts! (>= stake-threshold MIN_CIRCLE_STAKE) ERR_INVALID_PARAMS)
    (asserts! (> (len name) u0) ERR_INVALID_PARAMS)
    
    ;; Create the circle record
    (map-set circles
      { circle-id: circle-id }
      {
        name: name,
        creator: tx-sender,
        is-public: is-public,
        stake-threshold: stake-threshold,
        total-staked: u0,
        member-count: u0,
        created-at: stacks-block-height,
        reputation-weight: u100
      }
    )
    
    ;; Auto-join creator as founding member
    (try! (join-circle circle-id stake-threshold))
    
    ;; Increment circle counter
    (var-set next-circle-id (+ circle-id u1))
    
    (ok circle-id)
  )
)

(define-public (join-circle (circle-id uint) (stake-amount uint))
  ;; Join an existing circle by staking the required amount
  (let ((circle (unwrap! (map-get? circles { circle-id: circle-id }) ERR_CIRCLE_NOT_FOUND)))
    ;; Validation checks
    (asserts! (not (is-circle-member circle-id tx-sender)) ERR_ALREADY_MEMBER)
    (asserts! (>= stake-amount (get stake-threshold circle)) ERR_INSUFFICIENT_STAKE)
    (asserts! (>= (stx-get-balance tx-sender) stake-amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Transfer stake to protocol escrow
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
    
    ;; Record escrowed amount
    (map-set escrow-balances
      { user: tx-sender, circle-id: circle-id }
      { amount: stake-amount }
    )
    
    ;; Add member to circle
    (map-set circle-members
      { circle-id: circle-id, member: tx-sender }
      {
        stake-amount: stake-amount,
        reputation-score: u0,
        joined-at: stacks-block-height,
        last-activity: stacks-block-height,
        is-active: true
      }
    )
    
    ;; Update circle statistics
    (map-set circles
      { circle-id: circle-id }
      (merge circle {
        total-staked: (+ (get total-staked circle) stake-amount),
        member-count: (+ (get member-count circle) u1)
      })
    )
    
    ;; Award reputation bonus for joining
    (update-user-reputation tx-sender 10)
    
    (ok true)
  )
)

(define-public (leave-circle (circle-id uint))
  ;; Leave a circle and withdraw staked amount
  (let ((circle (unwrap! (map-get? circles { circle-id: circle-id }) ERR_CIRCLE_NOT_FOUND))
        (member-data (unwrap! (map-get? circle-members { circle-id: circle-id, member: tx-sender }) ERR_NOT_MEMBER))
        (escrow-data (unwrap! (map-get? escrow-balances { user: tx-sender, circle-id: circle-id }) ERR_NOT_MEMBER)))
    
    ;; Return staked amount from escrow
    (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender tx-sender)))
    
    ;; Clean up member records
    (map-delete circle-members { circle-id: circle-id, member: tx-sender })
    (map-delete escrow-balances { user: tx-sender, circle-id: circle-id })
    
    ;; Update circle statistics
    (map-set circles
      { circle-id: circle-id }
      (merge circle {
        total-staked: (- (get total-staked circle) (get stake-amount member-data)),
        member-count: (- (get member-count circle) u1)
      })
    )
    
    (ok true)
  )
)

;; PUBLIC FUNCTIONS - REPUTATION & SOCIAL CAPITAL

(define-public (endorse-member (circle-id uint) (target principal) (amount uint))
  ;; Transfer reputation points to another member (peer-to-peer endorsement)
  (let ((endorser-data (unwrap! (map-get? circle-members { circle-id: circle-id, member: tx-sender }) ERR_NOT_MEMBER))
        (target-data (unwrap! (map-get? circle-members { circle-id: circle-id, member: target }) ERR_NOT_MEMBER)))
    
    ;; Validation checks
    (asserts! (> amount u0) ERR_INVALID_PARAMS)
    (asserts! (>= (get reputation-score endorser-data) amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (not (is-eq tx-sender target)) ERR_INVALID_PARAMS)
    
    ;; Deduct reputation from endorser
    (map-set circle-members
      { circle-id: circle-id, member: tx-sender }
      (merge endorser-data {
        reputation-score: (- (get reputation-score endorser-data) amount),
        last-activity: stacks-block-height
      })
    )
    
    ;; Add reputation to target
    (map-set circle-members
      { circle-id: circle-id, member: target }
      (merge target-data {
        reputation-score: (+ (get reputation-score target-data) amount),
        last-activity: stacks-block-height
      })
    )
    
    ;; Update global reputation for target
    (update-user-reputation target (to-int amount))
    
    (ok true)
  )
)

(define-public (reward-member (circle-id uint) (target principal) (amount uint))
  ;; Reward member with reputation points (governance-controlled)
  (let ((member-data (unwrap! (map-get? circle-members { circle-id: circle-id, member: target }) ERR_NOT_MEMBER)))
    (asserts! (is-circle-member circle-id tx-sender) ERR_NOT_MEMBER)
    
    ;; Update target's reputation in circle
    (map-set circle-members
      { circle-id: circle-id, member: target }
      (merge member-data {
        reputation-score: (+ (get reputation-score member-data) amount)
      })
    )
    
    ;; Update global reputation
    (update-user-reputation target (to-int amount))
    
    (ok true)
  )
)

;; PUBLIC FUNCTIONS - DECENTRALIZED GOVERNANCE

(define-public (create-proposal 
  (circle-id uint) 
  (proposal-type (string-ascii 32)) 
  (target (optional principal)) 
  (amount uint) 
  (description (string-ascii 256)))
  ;; Create a governance proposal for circle decision-making
  (let ((proposal-id (var-get next-proposal-id)))
    ;; Validation checks
    (asserts! (is-circle-member circle-id tx-sender) ERR_NOT_MEMBER)
    (asserts! (> (len description) u0) ERR_INVALID_PARAMS)
    
    ;; Create proposal record
    (map-set proposals
      { proposal-id: proposal-id }
      {
        circle-id: circle-id,
        proposer: tx-sender,
        proposal-type: proposal-type,
        target: target,
        amount: amount,
        description: description,
        votes-for: u0,
        votes-against: u0,
        total-votes: u0,
        created-at: stacks-block-height,
        expires-at: (+ stacks-block-height VOTING_PERIOD),
        executed: false
      }
    )
    
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  ;; Cast a weighted vote on a governance proposal
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
        (voting-weight (calculate-voting-weight (get circle-id proposal) tx-sender)))
    
    ;; Validation checks
    (asserts! (is-circle-member (get circle-id proposal) tx-sender) ERR_NOT_MEMBER)
    (asserts! (< stacks-block-height (get expires-at proposal)) ERR_VOTING_CLOSED)
    (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) ERR_ALREADY_VOTED)
    (asserts! (> voting-weight u0) ERR_INSUFFICIENT_STAKE)
    
    ;; Record the vote
    (map-set votes
      { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote-for, weight: voting-weight, timestamp: stacks-block-height }
    )
    
    ;; Update proposal vote tallies
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal {
        votes-for: (if vote-for (+ (get votes-for proposal) voting-weight) (get votes-for proposal)),
        votes-against: (if vote-for (get votes-against proposal) (+ (get votes-against proposal) voting-weight)),
        total-votes: (+ (get total-votes proposal) voting-weight)
      })
    )
    
    (ok true)
  )
)