;; Public Building Maintenance Contract
;; Tracks repairs and upgrades to government facilities

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-INVALID-INPUT (err u501))
(define-constant ERR-NOT-FOUND (err u502))
(define-constant ERR-INVALID-STATUS (err u503))
(define-constant ERR-INSUFFICIENT-BUDGET (err u504))

;; Data Variables
(define-data-var next-building-id uint u1)
(define-data-var next-request-id uint u1)
(define-data-var total-buildings uint u0)
(define-data-var annual-budget uint u0)
(define-data-var budget-spent uint u0)

;; Data Maps
(define-map public-buildings
  { building-id: uint }
  {
    name: (string-ascii 200),
    address: (string-ascii 300),
    building-type: (string-ascii 100),
    year-built: uint,
    square-footage: uint,
    occupancy-limit: uint,
    last-inspection: (optional uint),
    maintenance-score: uint,
    energy-efficiency-rating: (optional (string-ascii 10)),
    accessibility-compliant: bool
  }
)

(define-map maintenance-requests
  { request-id: uint }
  {
    building-id: uint,
    requester: principal,
    request-type: (string-ascii 100),
    priority: uint,
    description: (string-ascii 1000),
    estimated-cost: (optional uint),
    status: (string-ascii 20),
    submitted-at: uint,
    assigned-contractor: (optional principal),
    scheduled-date: (optional uint),
    completed-date: (optional uint),
    actual-cost: (optional uint)
  }
)

(define-map building-inspections
  { inspection-id: uint }
  {
    building-id: uint,
    inspector: principal,
    inspection-date: uint,
    inspection-type: (string-ascii 50),
    overall-score: uint,
    safety-issues: uint,
    code-violations: uint,
    recommendations: (string-ascii 1000),
    next-inspection-due: uint
  }
)

(define-map maintenance-contractors
  { contractor: principal }
  {
    company-name: (string-ascii 200),
    license-types: (string-ascii 300),
    bonded-amount: uint,
    insurance-verified: bool,
    active-contracts: uint,
    completed-contracts: uint,
    performance-rating: (optional uint)
  }
)

(define-map budget-allocations
  { fiscal-year: uint }
  {
    total-budget: uint,
    emergency-reserve: uint,
    spent-amount: uint,
    remaining-balance: uint,
    projects-funded: uint
  }
)

;; Public Functions

;; Register new public building
(define-public (register-building (name (string-ascii 200)) (address (string-ascii 300)) (building-type (string-ascii 100)) (year-built uint) (square-footage uint) (occupancy-limit uint))
  (let
    (
      (building-id (var-get next-building-id))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len address) u0) ERR-INVALID-INPUT)
    (asserts! (> year-built u1800) ERR-INVALID-INPUT)
    (asserts! (> square-footage u0) ERR-INVALID-INPUT)

    (map-set public-buildings
      { building-id: building-id }
      {
        name: name,
        address: address,
        building-type: building-type,
        year-built: year-built,
        square-footage: square-footage,
        occupancy-limit: occupancy-limit,
        last-inspection: none,
        maintenance-score: u5,
        energy-efficiency-rating: none,
        accessibility-compliant: false
      }
    )

    (var-set next-building-id (+ building-id u1))
    (var-set total-buildings (+ (var-get total-buildings) u1))

    (ok building-id)
  )
)

;; Submit maintenance request
(define-public (submit-maintenance-request (building-id uint) (request-type (string-ascii 100)) (priority uint) (description (string-ascii 1000)))
  (let
    (
      (request-id (var-get next-request-id))
      (building-data (unwrap! (map-get? public-buildings { building-id: building-id }) ERR-NOT-FOUND))
    )
    (asserts! (and (>= priority u1) (<= priority u5)) ERR-INVALID-INPUT)
    (asserts! (> (len request-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)

    (map-set maintenance-requests
      { request-id: request-id }
      {
        building-id: building-id,
        requester: tx-sender,
        request-type: request-type,
        priority: priority,
        description: description,
        estimated-cost: none,
        status: "submitted",
        submitted-at: block-height,
        assigned-contractor: none,
        scheduled-date: none,
        completed-date: none,
        actual-cost: none
      }
    )

    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

;; Register maintenance contractor
(define-public (register-contractor (company-name (string-ascii 200)) (license-types (string-ascii 300)) (bonded-amount uint) (insurance-verified bool))
  (begin
    (asserts! (> (len company-name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len license-types) u0) ERR-INVALID-INPUT)
    (asserts! (> bonded-amount u0) ERR-INVALID-INPUT)

    (map-set maintenance-contractors
      { contractor: tx-sender }
      {
        company-name: company-name,
        license-types: license-types,
        bonded-amount: bonded-amount,
        insurance-verified: insurance-verified,
        active-contracts: u0,
        completed-contracts: u0,
        performance-rating: none
      }
    )

    (ok true)
  )
)

;; Assign contractor to maintenance request
(define-public (assign-contractor (request-id uint) (contractor principal) (estimated-cost uint))
  (let
    (
      (request-data (unwrap! (map-get? maintenance-requests { request-id: request-id }) ERR-NOT-FOUND))
      (contractor-data (unwrap! (map-get? maintenance-contractors { contractor: contractor }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request-data) "submitted") ERR-INVALID-STATUS)
    (asserts! (> estimated-cost u0) ERR-INVALID-INPUT)
    (asserts! (<= (+ (var-get budget-spent) estimated-cost) (var-get annual-budget)) ERR-INSUFFICIENT-BUDGET)

    (map-set maintenance-requests
      { request-id: request-id }
      (merge request-data {
        status: "assigned",
        assigned-contractor: (some contractor),
        estimated-cost: (some estimated-cost)
      })
    )

    (map-set maintenance-contractors
      { contractor: contractor }
      (merge contractor-data { active-contracts: (+ (get active-contracts contractor-data) u1) })
    )

    (ok true)
  )
)

;; Update maintenance status
(define-public (update-maintenance-status (request-id uint) (new-status (string-ascii 20)))
  (let
    (
      (request-data (unwrap! (map-get? maintenance-requests { request-id: request-id }) ERR-NOT-FOUND))
      (assigned-contractor (unwrap! (get assigned-contractor request-data) ERR-NOT-AUTHORIZED))
    )
    (asserts! (is-eq tx-sender assigned-contractor) ERR-NOT-AUTHORIZED)
    (asserts! (or (is-eq new-status "in-progress") (is-eq new-status "completed")) ERR-INVALID-INPUT)

    (if (is-eq new-status "completed")
      (let
        (
          (contractor-data (unwrap! (map-get? maintenance-contractors { contractor: assigned-contractor }) ERR-NOT-FOUND))
        )
        (map-set maintenance-requests
          { request-id: request-id }
          (merge request-data { status: new-status, completed-date: (some block-height) })
        )
        (map-set maintenance-contractors
          { contractor: assigned-contractor }
          (merge contractor-data {
            active-contracts: (- (get active-contracts contractor-data) u1),
            completed-contracts: (+ (get completed-contracts contractor-data) u1)
          })
        )
      )
      (map-set maintenance-requests
        { request-id: request-id }
        (merge request-data { status: new-status })
      )
    )

    (ok true)
  )
)

;; Conduct building inspection
(define-public (conduct-inspection (building-id uint) (inspection-type (string-ascii 50)) (overall-score uint) (safety-issues uint) (code-violations uint) (recommendations (string-ascii 1000)))
  (let
    (
      (inspection-id (var-get next-request-id))
      (building-data (unwrap! (map-get? public-buildings { building-id: building-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= overall-score u1) (<= overall-score u10)) ERR-INVALID-INPUT)
    (asserts! (> (len inspection-type) u0) ERR-INVALID-INPUT)

    (map-set building-inspections
      { inspection-id: inspection-id }
      {
        building-id: building-id,
        inspector: tx-sender,
        inspection-date: block-height,
        inspection-type: inspection-type,
        overall-score: overall-score,
        safety-issues: safety-issues,
        code-violations: code-violations,
        recommendations: recommendations,
        next-inspection-due: (+ block-height u26280)
      }
    )

    (map-set public-buildings
      { building-id: building-id }
      (merge building-data {
        last-inspection: (some block-height),
        maintenance-score: overall-score
      })
    )

    (var-set next-request-id (+ inspection-id u1))
    (ok inspection-id)
  )
)

;; Set annual budget
(define-public (set-annual-budget (fiscal-year uint) (total-budget uint) (emergency-reserve uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> total-budget u0) ERR-INVALID-INPUT)
    (asserts! (< emergency-reserve total-budget) ERR-INVALID-INPUT)

    (map-set budget-allocations
      { fiscal-year: fiscal-year }
      {
        total-budget: total-budget,
        emergency-reserve: emergency-reserve,
        spent-amount: u0,
        remaining-balance: total-budget,
        projects-funded: u0
      }
    )

    (var-set annual-budget total-budget)
    (var-set budget-spent u0)

    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-building (building-id uint))
  (map-get? public-buildings { building-id: building-id })
)

(define-read-only (get-maintenance-request (request-id uint))
  (map-get? maintenance-requests { request-id: request-id })
)

(define-read-only (get-inspection (inspection-id uint))
  (map-get? building-inspections { inspection-id: inspection-id })
)

(define-read-only (get-contractor-info (contractor principal))
  (map-get? maintenance-contractors { contractor: contractor })
)

(define-read-only (get-budget-info (fiscal-year uint))
  (map-get? budget-allocations { fiscal-year: fiscal-year })
)

(define-read-only (get-system-stats)
  {
    total-buildings: (var-get total-buildings),
    annual-budget: (var-get annual-budget),
    budget-spent: (var-get budget-spent),
    next-building-id: (var-get next-building-id),
    next-request-id: (var-get next-request-id)
  }
)
