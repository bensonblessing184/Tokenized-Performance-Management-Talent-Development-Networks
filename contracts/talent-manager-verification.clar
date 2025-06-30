;; Tokenized Performance Management - Talent Manager Verification Contract
;; Validates and manages performance talent managers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_VERIFIED (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map talent-managers
  principal
  {
    verified: bool,
    verification-date: uint,
    credentials-hash: (buff 32),
    reputation-score: uint,
    managed-employees: uint
  }
)

(define-map manager-credentials
  (buff 32)
  {
    manager: principal,
    certification-level: uint,
    expiry-date: uint
  }
)

(define-data-var total-verified-managers uint u0)

;; Public functions
(define-public (verify-talent-manager (manager principal) (credentials-hash (buff 32)) (certification-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? talent-managers manager)) ERR_ALREADY_VERIFIED)

    (map-set talent-managers manager {
      verified: true,
      verification-date: block-height,
      credentials-hash: credentials-hash,
      reputation-score: u100,
      managed-employees: u0
    })

    (map-set manager-credentials credentials-hash {
      manager: manager,
      certification-level: certification-level,
      expiry-date: (+ block-height u52560) ;; ~1 year in blocks
    })

    (var-set total-verified-managers (+ (var-get total-verified-managers) u1))
    (ok true)
  )
)

(define-public (update-reputation (manager principal) (new-score uint))
  (let ((manager-data (unwrap! (map-get? talent-managers manager) ERR_NOT_VERIFIED)))
    (asserts! (get verified manager-data) ERR_NOT_VERIFIED)
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set talent-managers manager (merge manager-data { reputation-score: new-score }))
    (ok true)
  )
)

(define-public (revoke-verification (manager principal))
  (let ((manager-data (unwrap! (map-get? talent-managers manager) ERR_NOT_VERIFIED)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set talent-managers manager (merge manager-data { verified: false }))
    (var-set total-verified-managers (- (var-get total-verified-managers) u1))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-verified-manager (manager principal))
  (match (map-get? talent-managers manager)
    manager-data (get verified manager-data)
    false
  )
)

(define-read-only (get-manager-info (manager principal))
  (map-get? talent-managers manager)
)

(define-read-only (get-total-verified-managers)
  (var-get total-verified-managers)
)
