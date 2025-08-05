;; Pothole Management Contract
;; Tracks road damage reports and coordinates repair crews

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-STATUS (err u104))

;; Data Variables
(define-data-var next-pothole-id uint u1)
(define-data-var total-potholes uint u0)
(define-data-var completed-repairs uint u0)

;; Data Maps
(define-map potholes
  { pothole-id: uint }
  {
    reporter: principal,
    latitude: int,
    longitude: int,
    severity: uint,
    description: (string-ascii 500),
    status: (string-ascii 20),
    assigned-crew: (optional principal),
    reported-at: uint,
    completed-at: (optional uint),
    repair-cost: (optional uint),
    quality-rating: (optional uint)
  }
)

(define-map crew-assignments
  { crew: principal }
  { active-assignments: uint, total-completed: uint }
)

(define-map pothole-reports-by-location
  { latitude: int, longitude: int }
  { report-count: uint, last-report-id: uint }
)

;; Public Functions

;; Report a new pothole
(define-public (report-pothole (latitude int) (longitude int) (severity uint) (description (string-ascii 500)))
  (let
    (
      (pothole-id (var-get next-pothole-id))
      (current-block block-height)
    )
    (asserts! (and (>= severity u1) (<= severity u5)) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)

    (map-set potholes
      { pothole-id: pothole-id }
      {
        reporter: tx-sender,
        latitude: latitude,
        longitude: longitude,
        severity: severity,
        description: description,
        status: "reported",
        assigned-crew: none,
        reported-at: current-block,
        completed-at: none,
        repair-cost: none,
        quality-rating: none
      }
    )

    (map-set pothole-reports-by-location
      { latitude: latitude, longitude: longitude }
      {
        report-count: (+ (default-to u0 (get report-count (map-get? pothole-reports-by-location { latitude: latitude, longitude: longitude }))) u1),
        last-report-id: pothole-id
      }
    )

    (var-set next-pothole-id (+ pothole-id u1))
    (var-set total-potholes (+ (var-get total-potholes) u1))

    (ok pothole-id)
  )
)

;; Assign crew to pothole repair
(define-public (assign-crew (pothole-id uint) (crew principal))
  (let
    (
      (pothole-data (unwrap! (map-get? potholes { pothole-id: pothole-id }) ERR-NOT-FOUND))
      (crew-data (default-to { active-assignments: u0, total-completed: u0 } (map-get? crew-assignments { crew: crew })))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status pothole-data) "reported") ERR-INVALID-STATUS)

    (map-set potholes
      { pothole-id: pothole-id }
      (merge pothole-data { status: "assigned", assigned-crew: (some crew) })
    )

    (map-set crew-assignments
      { crew: crew }
      { active-assignments: (+ (get active-assignments crew-data) u1), total-completed: (get total-completed crew-data) }
    )

    (ok true)
  )
)

;; Update repair status
(define-public (update-status (pothole-id uint) (new-status (string-ascii 20)))
  (let
    (
      (pothole-data (unwrap! (map-get? potholes { pothole-id: pothole-id }) ERR-NOT-FOUND))
      (assigned-crew (unwrap! (get assigned-crew pothole-data) ERR-NOT-AUTHORIZED))
    )
    (asserts! (is-eq tx-sender assigned-crew) ERR-NOT-AUTHORIZED)
    (asserts! (or (is-eq new-status "in-progress") (is-eq new-status "completed")) ERR-INVALID-INPUT)

    (if (is-eq new-status "completed")
      (begin
        (map-set potholes
          { pothole-id: pothole-id }
          (merge pothole-data { status: new-status, completed-at: (some block-height) })
        )
        (let
          (
            (crew-data (unwrap! (map-get? crew-assignments { crew: assigned-crew }) ERR-NOT-FOUND))
          )
          (map-set crew-assignments
            { crew: assigned-crew }
            {
              active-assignments: (- (get active-assignments crew-data) u1),
              total-completed: (+ (get total-completed crew-data) u1)
            }
          )
          (var-set completed-repairs (+ (var-get completed-repairs) u1))
        )
      )
      (map-set potholes
        { pothole-id: pothole-id }
        (merge pothole-data { status: new-status })
      )
    )

    (ok true)
  )
)

;; Add repair cost
(define-public (add-repair-cost (pothole-id uint) (cost uint))
  (let
    (
      (pothole-data (unwrap! (map-get? potholes { pothole-id: pothole-id }) ERR-NOT-FOUND))
      (assigned-crew (unwrap! (get assigned-crew pothole-data) ERR-NOT-AUTHORIZED))
    )
    (asserts! (is-eq tx-sender assigned-crew) ERR-NOT-AUTHORIZED)
    (asserts! (> cost u0) ERR-INVALID-INPUT)

    (map-set potholes
      { pothole-id: pothole-id }
      (merge pothole-data { repair-cost: (some cost) })
    )

    (ok true)
  )
)

;; Rate repair quality
(define-public (rate-repair (pothole-id uint) (rating uint))
  (let
    (
      (pothole-data (unwrap! (map-get? potholes { pothole-id: pothole-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get reporter pothole-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status pothole-data) "completed") ERR-INVALID-STATUS)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-INPUT)

    (map-set potholes
      { pothole-id: pothole-id }
      (merge pothole-data { quality-rating: (some rating) })
    )

    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-pothole (pothole-id uint))
  (map-get? potholes { pothole-id: pothole-id })
)

(define-read-only (get-crew-stats (crew principal))
  (map-get? crew-assignments { crew: crew })
)

(define-read-only (get-location-reports (latitude int) (longitude int))
  (map-get? pothole-reports-by-location { latitude: latitude, longitude: longitude })
)

(define-read-only (get-total-stats)
  {
    total-potholes: (var-get total-potholes),
    completed-repairs: (var-get completed-repairs),
    next-id: (var-get next-pothole-id)
  }
)
