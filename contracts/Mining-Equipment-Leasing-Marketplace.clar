(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_EQUIPMENT_NOT_FOUND u101)
(define-constant ERR_LEASE_NOT_FOUND u102)
(define-constant ERR_INVALID_AMOUNT u103)
(define-constant ERR_LEASE_ACTIVE u104)
(define-constant ERR_LEASE_NOT_ACTIVE u105)
(define-constant ERR_PAYMENT_FAILED u106)
(define-constant ERR_DISPUTE_EXISTS u107)
(define-constant ERR_DISPUTE_NOT_FOUND u108)
(define-constant ERR_ALREADY_VOTED u109)
(define-constant ERR_INVALID_COORDINATES u110)

(define-data-var equipment-id-counter uint u0)
(define-data-var lease-id-counter uint u0)
(define-data-var dispute-id-counter uint u0)

(define-map equipment
  { equipment-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    daily-rate: uint,
    is-available: bool,
    current-location: { lat: int, lng: int }
  }
)

(define-map leases
  { lease-id: uint }
  {
    equipment-id: uint,
    lessee: principal,
    lessor: principal,
    daily-rate: uint,
    start-block: uint,
    end-block: uint,
    escrow-amount: uint,
    is-active: bool,
    is-completed: bool
  }
)

(define-map escrows
  { lease-id: uint }
  {
    amount: uint,
    released: bool
  }
)

(define-map disputes
  { dispute-id: uint }
  {
    lease-id: uint,
    creator: principal,
    description: (string-ascii 200),
    votes-for: uint,
    votes-against: uint,
    resolved: bool,
    resolution: bool
  }
)

(define-map dispute-votes
  { dispute-id: uint, voter: principal }
  { voted: bool }
)

(define-public (register-equipment (name (string-ascii 50)) (daily-rate uint) (lat int) (lng int))
  (let ((equipment-id (+ (var-get equipment-id-counter) u1)))
    (asserts! (> daily-rate u0) (err ERR_INVALID_AMOUNT))
    (asserts! (and (>= lat -90000000) (<= lat 90000000)) (err ERR_INVALID_COORDINATES))
    (asserts! (and (>= lng -180000000) (<= lng 180000000)) (err ERR_INVALID_COORDINATES))
    (map-set equipment
      { equipment-id: equipment-id }
      {
        owner: tx-sender,
        name: name,
        daily-rate: daily-rate,
        is-available: true,
        current-location: { lat: lat, lng: lng }
      }
    )
    (var-set equipment-id-counter equipment-id)
    (ok equipment-id)
  )
)

(define-public (create-lease (equipment-id uint) (duration-days uint))
  (let (
    (equipment-data (unwrap! (map-get? equipment { equipment-id: equipment-id }) (err ERR_EQUIPMENT_NOT_FOUND)))
    (lease-id (+ (var-get lease-id-counter) u1))
    (daily-rate (get daily-rate equipment-data))
    (total-cost (* daily-rate duration-days))
    (start-block stacks-block-height)
    (end-block (+ stacks-block-height (* duration-days u144)))
  )
    (asserts! (get is-available equipment-data) (err ERR_LEASE_ACTIVE))
    (asserts! (> duration-days u0) (err ERR_INVALID_AMOUNT))
    (asserts! (not (is-eq tx-sender (get owner equipment-data))) (err ERR_UNAUTHORIZED))
    
    (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
    
    (map-set leases
      { lease-id: lease-id }
      {
        equipment-id: equipment-id,
        lessee: tx-sender,
        lessor: (get owner equipment-data),
        daily-rate: daily-rate,
        start-block: start-block,
        end-block: end-block,
        escrow-amount: total-cost,
        is-active: true,
        is-completed: false
      }
    )
    
    (map-set escrows
      { lease-id: lease-id }
      { amount: total-cost, released: false }
    )
    
    (map-set equipment
      { equipment-id: equipment-id }
      (merge equipment-data { is-available: false })
    )
    
    (var-set lease-id-counter lease-id)
    (ok lease-id)
  )
)

(define-public (complete-lease (lease-id uint))
  (let (
    (lease-data (unwrap! (map-get? leases { lease-id: lease-id }) (err ERR_LEASE_NOT_FOUND)))
    (escrow-data (unwrap! (map-get? escrows { lease-id: lease-id }) (err ERR_LEASE_NOT_FOUND)))
  )
    (asserts! (is-eq tx-sender (get lessee lease-data)) (err ERR_UNAUTHORIZED))
    (asserts! (get is-active lease-data) (err ERR_LEASE_NOT_ACTIVE))
    (asserts! (<= stacks-block-height (get end-block lease-data)) (err ERR_LEASE_ACTIVE))
    
    (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender (get lessor lease-data))))
    
    (map-set leases
      { lease-id: lease-id }
      (merge lease-data { is-active: false, is-completed: true })
    )
    
    (map-set escrows
      { lease-id: lease-id }
      (merge escrow-data { released: true })
    )
    
    (let ((equipment-data (unwrap! (map-get? equipment { equipment-id: (get equipment-id lease-data) }) (err ERR_EQUIPMENT_NOT_FOUND))))
      (map-set equipment
        { equipment-id: (get equipment-id lease-data) }
        (merge equipment-data { is-available: true })
      )
    )
    
    (ok true)
  )
)

(define-public (update-equipment-location (equipment-id uint) (lat int) (lng int))
  (let ((equipment-data (unwrap! (map-get? equipment { equipment-id: equipment-id }) (err ERR_EQUIPMENT_NOT_FOUND))))
    (asserts! (is-eq tx-sender (get owner equipment-data)) (err ERR_UNAUTHORIZED))
    (asserts! (and (>= lat -90000000) (<= lat 90000000)) (err ERR_INVALID_COORDINATES))
    (asserts! (and (>= lng -180000000) (<= lng 180000000)) (err ERR_INVALID_COORDINATES))
    
    (map-set equipment
      { equipment-id: equipment-id }
      (merge equipment-data { current-location: { lat: lat, lng: lng } })
    )
    (ok true)
  )
)

(define-public (create-dispute (lease-id uint) (description (string-ascii 200)))
  (let (
    (lease-data (unwrap! (map-get? leases { lease-id: lease-id }) (err ERR_LEASE_NOT_FOUND)))
    (dispute-id (+ (var-get dispute-id-counter) u1))
  )
    (asserts! (or (is-eq tx-sender (get lessee lease-data)) (is-eq tx-sender (get lessor lease-data))) (err ERR_UNAUTHORIZED))
    (asserts! (get is-active lease-data) (err ERR_LEASE_NOT_ACTIVE))
    
    (map-set disputes
      { dispute-id: dispute-id }
      {
        lease-id: lease-id,
        creator: tx-sender,
        description: description,
        votes-for: u0,
        votes-against: u0,
        resolved: false,
        resolution: false
      }
    )
    
    (var-set dispute-id-counter dispute-id)
    (ok dispute-id)
  )
)

(define-public (vote-dispute (dispute-id uint) (vote-for bool))
  (let ((dispute-data (unwrap! (map-get? disputes { dispute-id: dispute-id }) (err ERR_DISPUTE_NOT_FOUND))))
    (asserts! (not (get resolved dispute-data)) (err ERR_DISPUTE_EXISTS))
    (asserts! (is-none (map-get? dispute-votes { dispute-id: dispute-id, voter: tx-sender })) (err ERR_ALREADY_VOTED))
    
    (map-set dispute-votes
      { dispute-id: dispute-id, voter: tx-sender }
      { voted: true }
    )
    
    (if vote-for
      (map-set disputes
        { dispute-id: dispute-id }
        (merge dispute-data { votes-for: (+ (get votes-for dispute-data) u1) })
      )
      (map-set disputes
        { dispute-id: dispute-id }
        (merge dispute-data { votes-against: (+ (get votes-against dispute-data) u1) })
      )
    )
    
    (ok true)
  )
)

(define-public (resolve-dispute (dispute-id uint))
  (let ((dispute-data (unwrap! (map-get? disputes { dispute-id: dispute-id }) (err ERR_DISPUTE_NOT_FOUND))))
    (asserts! (not (get resolved dispute-data)) (err ERR_DISPUTE_EXISTS))
    (asserts! (> (+ (get votes-for dispute-data) (get votes-against dispute-data)) u5) (err ERR_UNAUTHORIZED))
    
    (let ((resolution (> (get votes-for dispute-data) (get votes-against dispute-data))))
      (map-set disputes
        { dispute-id: dispute-id }
        (merge dispute-data { resolved: true, resolution: resolution })
      )
      
      (if resolution
        (let (
          (lease-data (unwrap! (map-get? leases { lease-id: (get lease-id dispute-data) }) (err ERR_LEASE_NOT_FOUND)))
          (escrow-data (unwrap! (map-get? escrows { lease-id: (get lease-id dispute-data) }) (err ERR_LEASE_NOT_FOUND)))
        )
          (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender (get lessee lease-data))))
          (map-set escrows
            { lease-id: (get lease-id dispute-data) }
            (merge escrow-data { released: true })
          )
          (ok true)
        )
        (ok false)
      )
    )
  )
)
(define-public (extend-lease (lease-id uint) (additional-days uint))
  (let (
    (lease-data (unwrap! (map-get? leases { lease-id: lease-id }) (err ERR_LEASE_NOT_FOUND)))
    (equipment-data (unwrap! (map-get? equipment { equipment-id: (get equipment-id lease-data) }) (err ERR_EQUIPMENT_NOT_FOUND)))
    (additional-cost (* (get daily-rate lease-data) additional-days))
    (new-end-block (+ (get end-block lease-data) (* additional-days u144)))
    (new-escrow (+ (get escrow-amount lease-data) additional-cost))
  )
    (asserts! (is-eq tx-sender (get lessee lease-data)) (err ERR_UNAUTHORIZED))
    (asserts! (get is-active lease-data) (err ERR_LEASE_NOT_ACTIVE))
    (asserts! (> additional-days u0) (err ERR_INVALID_AMOUNT))
    (try! (stx-transfer? additional-cost tx-sender (as-contract tx-sender)))
    (map-set leases
      { lease-id: lease-id }
      (merge lease-data { end-block: new-end-block, escrow-amount: new-escrow })
    )
    (map-set escrows
      { lease-id: lease-id }
      { amount: new-escrow, released: false }
    )
    (ok true)
  )
)

(define-read-only (get-equipment (equipment-id uint))
  (map-get? equipment { equipment-id: equipment-id })
)

(define-read-only (get-lease (lease-id uint))
  (map-get? leases { lease-id: lease-id })
)

(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id })
)

(define-read-only (get-escrow (lease-id uint))
  (map-get? escrows { lease-id: lease-id })
)

(define-read-only (get-equipment-counter)
  (var-get equipment-id-counter)
)

(define-read-only (get-lease-counter)
  (var-get lease-id-counter)
)

(define-read-only (get-dispute-counter)
  (var-get dispute-id-counter)
)
