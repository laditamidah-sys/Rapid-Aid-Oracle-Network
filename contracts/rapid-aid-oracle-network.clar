(define-constant ERR_UNAUTHORIZED u401)
(define-constant ERR_ORACLE_NOT_FOUND u402)
(define-constant ERR_INVALID_AMOUNT u403)
(define-constant ERR_EMERGENCY_NOT_FOUND u404)
(define-constant ERR_ALREADY_VERIFIED u405)
(define-constant ERR_INSUFFICIENT_FUNDS u406)
(define-constant ERR_INVALID_STATUS u407)
(define-constant ERR_ORACLE_INACTIVE u408)
(define-constant ERR_VERIFICATION_FAILED u409)
(define-constant ERR_COOLDOWN_ACTIVE u410)

(define-constant EMERGENCY_STATUS_PENDING u0)
(define-constant EMERGENCY_STATUS_VERIFIED u1)
(define-constant EMERGENCY_STATUS_FUNDED u2)
(define-constant EMERGENCY_STATUS_COMPLETED u3)
(define-constant EMERGENCY_STATUS_REJECTED u4)

(define-constant EMERGENCY_TYPE_NATURAL_DISASTER u0)
(define-constant EMERGENCY_TYPE_MEDICAL u1)
(define-constant EMERGENCY_TYPE_HUMANITARIAN u2)
(define-constant EMERGENCY_TYPE_INFRASTRUCTURE u3)

(define-constant MIN_AID_AMOUNT u1000000)
(define-constant MAX_AID_AMOUNT u100000000)
(define-constant ORACLE_BOND_AMOUNT u5000000)
(define-constant VERIFICATION_THRESHOLD u3)
(define-constant COOLDOWN_PERIOD u144)

(define-data-var emergency-counter uint u0)
(define-data-var oracle-counter uint u0)
(define-data-var total-aid-distributed uint u0)
(define-data-var network-admin principal tx-sender)
(define-data-var emergency-fund uint u0)
(define-data-var oracle-reward-rate uint u50)

(define-map emergencies uint {
    emergency-id: uint,
    reporter: principal,
    location: (string-ascii 100),
    emergency-type: uint,
    severity: uint,
    requested-amount: uint,
    verified-amount: uint,
    status: uint,
    creation-time: uint,
    verification-count: uint,
    rejection-count: uint,
    funding-deadline: uint,
    description: (string-ascii 500)
})

(define-map oracles principal {
    oracle-id: uint,
    reputation: uint,
    verifications-completed: uint,
    bond-amount: uint,
    is-active: bool,
    specialization: uint,
    registration-time: uint,
    last-activity: uint,
    reward-balance: uint
})

(define-map emergency-verifications { emergency-id: uint, oracle: principal } {
    verified: bool,
    verification-time: uint,
    confidence-score: uint,
    evidence-hash: (string-ascii 64)
})

(define-map aid-distributions { emergency-id: uint, recipient: principal } {
    amount: uint,
    distribution-time: uint,
    milestone: uint,
    is-completed: bool
})

(define-map oracle-specializations principal {
    natural-disasters: bool,
    medical-emergencies: bool,
    humanitarian-crisis: bool,
    infrastructure-damage: bool
})

(define-map emergency-fund-contributions principal {
    total-contributed: uint,
    contribution-count: uint,
    last-contribution: uint
})

(define-public (register-oracle (specialization uint) (bond-amount uint))
    (let (
        (oracle-id (+ (var-get oracle-counter) u1))
        (existing-oracle (map-get? oracles tx-sender))
    )
        (asserts! (is-none existing-oracle) (err ERR_UNAUTHORIZED))
        (asserts! (>= bond-amount ORACLE_BOND_AMOUNT) (err ERR_INVALID_AMOUNT))
        (asserts! (<= specialization EMERGENCY_TYPE_INFRASTRUCTURE) (err ERR_INVALID_STATUS))
        
        (try! (stx-transfer? bond-amount tx-sender (as-contract tx-sender)))
        
        (map-set oracles tx-sender {
            oracle-id: oracle-id,
            reputation: u100,
            verifications-completed: u0,
            bond-amount: bond-amount,
            is-active: true,
            specialization: specialization,
            registration-time: stacks-block-height,
            last-activity: stacks-block-height,
            reward-balance: u0
        })
        
        (var-set oracle-counter oracle-id)
        (ok oracle-id)
    )
)

(define-public (report-emergency 
    (location (string-ascii 100)) 
    (emergency-type uint) 
    (severity uint) 
    (requested-amount uint)
    (description (string-ascii 500)))
    (let (
        (emergency-id (+ (var-get emergency-counter) u1))
        (funding-deadline (+ stacks-block-height u1008))
    )
        (asserts! (>= requested-amount MIN_AID_AMOUNT) (err ERR_INVALID_AMOUNT))
        (asserts! (<= requested-amount MAX_AID_AMOUNT) (err ERR_INVALID_AMOUNT))
        (asserts! (<= emergency-type EMERGENCY_TYPE_INFRASTRUCTURE) (err ERR_INVALID_STATUS))
        (asserts! (<= severity u10) (err ERR_INVALID_STATUS))
        
        (map-set emergencies emergency-id {
            emergency-id: emergency-id,
            reporter: tx-sender,
            location: location,
            emergency-type: emergency-type,
            severity: severity,
            requested-amount: requested-amount,
            verified-amount: u0,
            status: EMERGENCY_STATUS_PENDING,
            creation-time: stacks-block-height,
            verification-count: u0,
            rejection-count: u0,
            funding-deadline: funding-deadline,
            description: description
        })
        
        (var-set emergency-counter emergency-id)
        (ok emergency-id)
    )
)

(define-public (verify-emergency (emergency-id uint) (verified bool) (confidence-score uint) (evidence-hash (string-ascii 64)))
    (let (
        (emergency (unwrap! (map-get? emergencies emergency-id) (err ERR_EMERGENCY_NOT_FOUND)))
        (oracle (unwrap! (map-get? oracles tx-sender) (err ERR_ORACLE_NOT_FOUND)))
        (existing-verification (map-get? emergency-verifications { emergency-id: emergency-id, oracle: tx-sender }))
    )
        (asserts! (get is-active oracle) (err ERR_ORACLE_INACTIVE))
        (asserts! (is-none existing-verification) (err ERR_ALREADY_VERIFIED))
        (asserts! (is-eq (get status emergency) EMERGENCY_STATUS_PENDING) (err ERR_INVALID_STATUS))
        (asserts! (<= confidence-score u100) (err ERR_INVALID_AMOUNT))
        (asserts! (>= (- stacks-block-height (get last-activity oracle)) COOLDOWN_PERIOD) (err ERR_COOLDOWN_ACTIVE))
        
        (map-set emergency-verifications { emergency-id: emergency-id, oracle: tx-sender } {
            verified: verified,
            verification-time: stacks-block-height,
            confidence-score: confidence-score,
            evidence-hash: evidence-hash
        })
        
        (map-set oracles tx-sender (merge oracle {
            verifications-completed: (+ (get verifications-completed oracle) u1),
            last-activity: stacks-block-height,
            reputation: (if verified 
                           (+ (get reputation oracle) u10)
                           (- (get reputation oracle) u5))
        }))
        
        (let (
            (new-verification-count (if verified 
                                      (+ (get verification-count emergency) u1)
                                      (get verification-count emergency)))
            (new-rejection-count (if (not verified)
                                   (+ (get rejection-count emergency) u1)
                                   (get rejection-count emergency)))
        )
            (map-set emergencies emergency-id (merge emergency {
                verification-count: new-verification-count,
                rejection-count: new-rejection-count
            }))
            
            (if (>= new-verification-count VERIFICATION_THRESHOLD)
                (begin
                    (map-set emergencies emergency-id (merge emergency {
                        verification-count: new-verification-count,
                        rejection-count: new-rejection-count,
                        status: EMERGENCY_STATUS_VERIFIED,
                        verified-amount: (calculate-verified-amount emergency-id)
                    }))
                    (distribute-oracle-rewards emergency-id)
                )
                (if (>= new-rejection-count VERIFICATION_THRESHOLD)
                    (map-set emergencies emergency-id (merge emergency {
                        verification-count: new-verification-count,
                        rejection-count: new-rejection-count,
                        status: EMERGENCY_STATUS_REJECTED
                    }))
                    true
                )
            )
        )
        
        (ok verified)
    )
)

(define-public (fund-emergency-pool (amount uint))
    (let (
        (contribution-record (default-to 
            { total-contributed: u0, contribution-count: u0, last-contribution: u0 }
            (map-get? emergency-fund-contributions tx-sender)))
    )
        (asserts! (> amount u0) (err ERR_INVALID_AMOUNT))
        
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (var-set emergency-fund (+ (var-get emergency-fund) amount))
        
        (map-set emergency-fund-contributions tx-sender {
            total-contributed: (+ (get total-contributed contribution-record) amount),
            contribution-count: (+ (get contribution-count contribution-record) u1),
            last-contribution: stacks-block-height
        })
        
        (ok amount)
    )
)

(define-public (distribute-aid (emergency-id uint))
    (let (
        (emergency (unwrap! (map-get? emergencies emergency-id) (err ERR_EMERGENCY_NOT_FOUND)))
        (verified-amount (get verified-amount emergency))
    )
        (asserts! (is-eq (get status emergency) EMERGENCY_STATUS_VERIFIED) (err ERR_INVALID_STATUS))
        (asserts! (<= verified-amount (var-get emergency-fund)) (err ERR_INSUFFICIENT_FUNDS))
        
        (try! (as-contract (stx-transfer? verified-amount tx-sender (get reporter emergency))))
        
        (map-set emergencies emergency-id (merge emergency {
            status: EMERGENCY_STATUS_FUNDED
        }))
        
        (var-set emergency-fund (- (var-get emergency-fund) verified-amount))
        (var-set total-aid-distributed (+ (var-get total-aid-distributed) verified-amount))
        
        (map-set aid-distributions { emergency-id: emergency-id, recipient: (get reporter emergency) } {
            amount: verified-amount,
            distribution-time: stacks-block-height,
            milestone: u1,
            is-completed: true
        })
        
        (ok verified-amount)
    )
)

(define-public (complete-emergency (emergency-id uint) (completion-evidence (string-ascii 64)))
    (let (
        (emergency (unwrap! (map-get? emergencies emergency-id) (err ERR_EMERGENCY_NOT_FOUND)))
    )
        (asserts! (is-eq tx-sender (get reporter emergency)) (err ERR_UNAUTHORIZED))
        (asserts! (is-eq (get status emergency) EMERGENCY_STATUS_FUNDED) (err ERR_INVALID_STATUS))
        
        (map-set emergencies emergency-id (merge emergency {
            status: EMERGENCY_STATUS_COMPLETED
        }))
        
        (ok true)
    )
)

(define-public (claim-oracle-rewards)
    (let (
        (oracle (unwrap! (map-get? oracles tx-sender) (err ERR_ORACLE_NOT_FOUND)))
        (reward-amount (get reward-balance oracle))
    )
        (asserts! (> reward-amount u0) (err ERR_INVALID_AMOUNT))
        
        (try! (as-contract (stx-transfer? reward-amount tx-sender tx-sender)))
        
        (map-set oracles tx-sender (merge oracle {
            reward-balance: u0
        }))
        
        (ok reward-amount)
    )
)

(define-public (deactivate-oracle)
    (let (
        (oracle (unwrap! (map-get? oracles tx-sender) (err ERR_ORACLE_NOT_FOUND)))
        (bond-amount (get bond-amount oracle))
    )
        (asserts! (get is-active oracle) (err ERR_ORACLE_INACTIVE))
        
        (try! (as-contract (stx-transfer? bond-amount tx-sender tx-sender)))
        
        (map-set oracles tx-sender (merge oracle {
            is-active: false,
            bond-amount: u0
        }))
        
        (ok bond-amount)
    )
)

(define-public (update-oracle-specialization (emergency-type uint) (enabled bool))
    (let (
        (oracle (unwrap! (map-get? oracles tx-sender) (err ERR_ORACLE_NOT_FOUND)))
        (current-specializations (default-to 
            { natural-disasters: false, medical-emergencies: false, humanitarian-crisis: false, infrastructure-damage: false }
            (map-get? oracle-specializations tx-sender)))
    )
        (asserts! (get is-active oracle) (err ERR_ORACLE_INACTIVE))
        (asserts! (<= emergency-type EMERGENCY_TYPE_INFRASTRUCTURE) (err ERR_INVALID_STATUS))
        
        (if (is-eq emergency-type EMERGENCY_TYPE_NATURAL_DISASTER)
            (map-set oracle-specializations tx-sender (merge current-specializations {
                natural-disasters: enabled
            }))
            (if (is-eq emergency-type EMERGENCY_TYPE_MEDICAL)
                (map-set oracle-specializations tx-sender (merge current-specializations {
                    medical-emergencies: enabled
                }))
                (if (is-eq emergency-type EMERGENCY_TYPE_HUMANITARIAN)
                    (map-set oracle-specializations tx-sender (merge current-specializations {
                        humanitarian-crisis: enabled
                    }))
                    (map-set oracle-specializations tx-sender (merge current-specializations {
                        infrastructure-damage: enabled
                    }))
                )
            )
        )
        
        (ok enabled)
    )
)

(define-private (calculate-verified-amount (emergency-id uint))
    (let (
        (emergency (unwrap! (map-get? emergencies emergency-id) u0))
        (requested-amount (get requested-amount emergency))
        (verification-count (get verification-count emergency))
        (severity (get severity emergency))
    )
        (if (>= verification-count u5)
            requested-amount
            (if (>= verification-count u4)
                (/ (* requested-amount u90) u100)
                (if (>= verification-count u3)
                    (/ (* requested-amount u75) u100)
                    u0
                )
            )
        )
    )
)

(define-private (distribute-oracle-rewards (emergency-id uint))
    (let (
        (reward-amount (/ (* (var-get oracle-reward-rate) (calculate-verified-amount emergency-id)) u100))
    )
        (distribute-reward-to-verifiers emergency-id reward-amount)
        true
    )
)

(define-private (distribute-reward-to-verifiers (emergency-id uint) (total-reward uint))
    (let (
        (emergency (unwrap! (map-get? emergencies emergency-id) false))
        (verification-count (get verification-count emergency))
        (reward-per-oracle (/ total-reward verification-count))
    )
        (distribute-single-reward emergency-id reward-per-oracle)
    )
)

(define-private (distribute-single-reward (emergency-id uint) (reward-amount uint))
    true
)

(define-read-only (get-emergency (emergency-id uint))
    (map-get? emergencies emergency-id)
)

(define-read-only (get-oracle (oracle-address principal))
    (map-get? oracles oracle-address)
)

(define-read-only (get-verification (emergency-id uint) (oracle-address principal))
    (map-get? emergency-verifications { emergency-id: emergency-id, oracle: oracle-address })
)

(define-read-only (get-network-stats)
    {
        total-emergencies: (var-get emergency-counter),
        total-oracles: (var-get oracle-counter),
        total-aid-distributed: (var-get total-aid-distributed),
        emergency-fund-balance: (var-get emergency-fund),
        oracle-reward-rate: (var-get oracle-reward-rate)
    }
)

(define-read-only (get-emergency-status (emergency-id uint))
    (match (map-get? emergencies emergency-id)
        emergency (some {
            status: (get status emergency),
            verification-progress: (/ (* (get verification-count emergency) u100) VERIFICATION_THRESHOLD),
            funding-progress: (if (> (get verified-amount emergency) u0)
                                (/ (* (get verified-amount emergency) u100) (get requested-amount emergency))
                                u0),
            time-remaining: (if (> (get funding-deadline emergency) stacks-block-height)
                              (- (get funding-deadline emergency) stacks-block-height)
                              u0)
        })
        none
    )
)

(define-read-only (calculate-oracle-reputation (oracle-address principal))
    (match (map-get? oracles oracle-address)
        oracle (some {
            base-reputation: (get reputation oracle),
            verification-count: (get verifications-completed oracle),
            activity-score: (if (< (- stacks-block-height (get last-activity oracle)) u1008) u100 u50),
            overall-score: (+ (get reputation oracle) 
                             (/ (get verifications-completed oracle) u10))
        })
        none
    )
)