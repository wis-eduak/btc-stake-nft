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