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