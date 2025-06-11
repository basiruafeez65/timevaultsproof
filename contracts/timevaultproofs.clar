(define-map vaults principal
  {
    beneficiary: principal,
    unlock-block: uint,
    approved-guardians: (list 5 principal),
    guardian-approvals: (list 5 principal),
    is-unlocked: bool
  }
)

(define-map archive-index (buff 32)
  {
    owner: principal,
    submit-block: uint,
    unlock-delay: uint,
    is-released: bool,
    metadata: (optional (buff 100))
  }
)

(define-constant inactivity-threshold u10000) ;; ~70 days at 10min/block

;; Create a vault with inheritance rules
(define-public (create-vault (beneficiary principal) (guardians (list 5 principal)))
  (let 
    (
      (checked-guardians (unwrap! (as-max-len? guardians u5) (err u100)))
      (vault-data (merge 
        {
          beneficiary: beneficiary,
          unlock-block: (+ stacks-block-height inactivity-threshold),
          approved-guardians: checked-guardians,
          guardian-approvals: (list),
          is-unlocked: false
        }
        ;; No additional fields to merge, this ensures type checking
        {
          beneficiary: beneficiary,
          unlock-block: (+ stacks-block-height inactivity-threshold),
          approved-guardians: checked-guardians,
          guardian-approvals: (list),
          is-unlocked: false
        }
      ))
    )
    (ok (map-set vaults tx-sender vault-data)))
)

;; Guardian approves unlocking
(define-public (guardian-approve (owner principal))
  (let ((vault (unwrap! (map-get? vaults owner) (err u100))))
    (begin
      (asserts! (is-eq false (get is-unlocked vault)) (err u101))
      (asserts! (is-some (index-of (get approved-guardians vault) tx-sender)) (err u102))
      (let ((approvals (get guardian-approvals vault)))
        (asserts! (is-none (index-of approvals tx-sender)) (err u103))
        (let ((new-approvals (unwrap! (as-max-len? (append approvals tx-sender) u5) (err u104))))
          (ok (map-set vaults owner (merge vault {
            guardian-approvals: new-approvals
          })))))))
)

;; Check if vault can be unlocked (majority guardian + inactivity)
(define-public (unlock-vault (owner principal))
  (let ((vault (unwrap! (map-get? vaults owner) (err u100))))
    (let (
      (num-guardians (len (get approved-guardians vault)))
      (approvals (get guardian-approvals vault))
      (num-approvals (len approvals))
    )
      (begin
        (asserts! (is-eq false (get is-unlocked vault)) (err u104))
        (asserts! (>= (- stacks-block-height (get unlock-block vault)) u0) (err u105))
        (asserts! (>= num-approvals (/ (+ num-guardians u1) u2)) (err u106))
        (ok (map-set vaults owner (merge vault {is-unlocked: true}))))))
)

;; Claim assets after vault unlocked
(define-public (claim-assets (owner principal))
  (let ((vault (unwrap! (map-get? vaults owner) (err u100))))
    (begin
      (asserts! (is-eq tx-sender (get beneficiary vault)) (err u107))
      (asserts! (is-eq true (get is-unlocked vault)) (err u108))
      ;; Transfer assets logic can be extended here
      (ok (map-delete vaults owner))))
)

;; Read-only: Check vault status
(define-read-only (get-vault (owner principal))
  (map-get? vaults owner)
)

;; Submit archival hash with unlock schedule
(define-public (submit-archive (doc-hash (buff 32)) (unlock-delay uint) (meta (optional (buff 100))))
  (begin
    (asserts! (not (is-some (map-get? archive-index doc-hash))) (err u200))
    (let 
      ((archive-data (merge 
        {
          owner: tx-sender,
          submit-block: stacks-block-height,
          unlock-delay: unlock-delay,
          is-released: false,
          metadata: meta
        }
        ;; No additional fields to merge, this ensures type checking
        {
          owner: tx-sender,
          submit-block: stacks-block-height,
          unlock-delay: unlock-delay,
          is-released: false,
          metadata: meta
        }
      )))
      (ok (map-set archive-index doc-hash archive-data))))
)

;; Release archived data if time has passed
(define-public (release-archive (doc-hash (buff 32)))
  (let ((entry (unwrap! (map-get? archive-index doc-hash) (err u204))))
    (begin
      (asserts! (is-eq tx-sender (get owner entry)) (err u201))
      (asserts! (is-eq false (get is-released entry)) (err u202))
      (asserts! (>= stacks-block-height (+ (get submit-block entry) (get unlock-delay entry))) (err u203))
      (ok (map-set archive-index doc-hash (merge entry {is-released: true})))))
)

;; Read-only: get archive entry
(define-read-only (get-archive (doc-hash (buff 32)))
  (map-get? archive-index doc-hash)
)
