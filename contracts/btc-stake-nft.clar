;; title: BTC Stake NFT Contract
;; summary: A smart contract for minting, transferring, staking, and trading Bitcoin-backed NFTs.
;; description: This contract allows users to mint NFTs backed by Bitcoin, transfer ownership, list NFTs for sale, purchase listed NFTs, and stake NFTs to earn rewards. It includes functions for managing NFT metadata, handling staking rewards, and updating protocol parameters.

;;Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u1001))
(define-constant ERR-INVALID-PARAMETERS (err u1002))
(define-constant ERR-TOKEN-NOT-FOUND (err u1003))
(define-constant ERR-INSUFFICIENT-FUNDS (err u1004))
(define-constant ERR-LISTING-EXISTS (err u1005))
(define-constant ERR-LISTING-NOT-FOUND (err u1006))
(define-constant ERR-TRANSFER-FAILED (err u1007))
(define-constant ERR-ALREADY-STAKED (err u1008))
(define-constant ERR-NOT-STAKED (err u1009))

;; NFT Definition
(define-non-fungible-token bitcoin-backed-nft uint)

;; Data Variables
(define-data-var total-supply uint u0)
(define-data-var protocol-fee uint u25)  ;; 2.5% fee in basis points
(define-data-var min-collateral-ratio uint u150)  ;; 150% minimum collateral ratio
(define-data-var yield-rate uint u50)  ;; 5% annual yield rate in basis points

;; Data Maps
(define-map token-metadata 
    { token-id: uint }
    { 
        creator: principal,
        uri: (string-ascii 256),
        collateral-amount: uint,
        is-staked: bool,
        stake-start-height: uint
    }
)

(define-map token-listings 
    { token-id: uint }
    { 
        price: uint, 
        seller: principal, 
        is-active: bool 
    }
)

(define-map staking-rewards 
    { token-id: uint }
    {
        accumulated-yield: uint,
        last-claim-height: uint
    }
)

;; Utility Functions
(define-private (is-owner-or-authorized (token-id uint))
    (let 
        ((metadata (unwrap! (map-get? token-metadata { token-id: token-id }) false))
         (owner (nft-get-owner? bitcoin-backed-nft token-id)))
        (or 
            (is-eq tx-sender CONTRACT-OWNER)
            (and owner (is-eq tx-sender (unwrap-panic owner)))
        )
    )
)

;; Core NFT Functions
(define-public (mint-nft 
    (uri (string-ascii 256)) 
    (collateral-amount uint)
)
    (let 
        ((new-token-id (+ (var-get total-supply) u1))
         (min-collateral (/ (* (var-get min-collateral-ratio) collateral-amount) u100)))
        ;; Validate inputs
        (asserts! (> (len uri) u0) ERR-INVALID-PARAMETERS)
        (asserts! (>= (stx-get-balance tx-sender) min-collateral) ERR-INSUFFICIENT-FUNDS)
        
        ;; Transfer collateral
        (try! (stx-transfer? min-collateral tx-sender (as-contract tx-sender)))
        
        ;; Mint NFT
        (try! (nft-mint? bitcoin-backed-nft new-token-id tx-sender))
        
        ;; Store metadata
        (map-set token-metadata 
            { token-id: new-token-id }
            { 
                creator: tx-sender,
                uri: uri,
                collateral-amount: collateral-amount,
                is-staked: false,
                stake-start-height: u0
            }
        )
        
        ;; Update total supply
        (var-set total-supply new-token-id)
        
        (ok new-token-id)
    )
)

(define-public (transfer-nft 
    (token-id uint) 
    (recipient principal)
)
    (begin
        ;; Validate transfer
        (asserts! (is-owner-or-authorized token-id) ERR-UNAUTHORIZED)
        (asserts! (not (is-eq recipient tx-sender)) ERR-INVALID-PARAMETERS)
        
        ;; Transfer NFT
        (try! (nft-transfer? bitcoin-backed-nft token-id tx-sender recipient))
        
        ;; Update metadata if needed
        (ok true)
    )
)

;; Marketplace Functions
(define-public (list-nft 
    (token-id uint) 
    (price uint)
)
    (begin
        ;; Validate listing
        (asserts! (is-owner-or-authorized token-id) ERR-UNAUTHORIZED)
        (asserts! (> price u0) ERR-INVALID-PARAMETERS)
        (asserts! (is-none (map-get? token-listings { token-id: token-id })) ERR-LISTING-EXISTS)
        
        ;; Create listing
        (map-set token-listings 
            { token-id: token-id }
            { 
                price: price, 
                seller: tx-sender, 
                is-active: true 
            }
        )
        
        (ok true)
    )
)

(define-public (purchase-nft 
    (token-id uint)
)
    (let 
        ((listing (unwrap! (map-get? token-listings { token-id: token-id }) ERR-LISTING-NOT-FOUND))
         (price (get price listing))
         (seller (get seller listing))
         (protocol-fee-amount (/ (* price (var-get protocol-fee)) u1000)))
        ;; Validate purchase
        (asserts! (get is-active listing) ERR-LISTING-NOT-FOUND)
        (asserts! (>= (stx-get-balance tx-sender) price) ERR-INSUFFICIENT-FUNDS)
        
        ;; Transfer payment
        (try! (stx-transfer? price tx-sender seller))
        (try! (stx-transfer? protocol-fee-amount tx-sender CONTRACT-OWNER))
        
        ;; Transfer NFT
        (try! (nft-transfer? bitcoin-backed-nft token-id seller tx-sender))
        
        ;; Update listing
        (map-set token-listings 
            { token-id: token-id }
            { 
                price: u0, 
                seller: seller, 
                is-active: false 
            }
        )
        
        (ok true)
    )
)