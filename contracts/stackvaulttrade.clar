;; stack-vault-trade.clar
;; A multi-purpose STX vault, staking, and trading hub.

(define-constant ERR_NOT_ENOUGH_FUNDS (err u100))
(define-constant ERR_UNAUTHORIZED (err u101))
(define-constant ERR_ALREADY_STAKED (err u102))
(define-constant ERR_NOT_STAKED (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_NO_SUCH_ORDER (err u105))

;; === DATA STRUCTURES ===

;; User vault balances
(define-map user-balances
  { user: principal }
  { balance: uint })

;; User staking data
(define-map user-stakes
  { user: principal }
  { amount: uint, reward: uint, active: bool })

;; Trade offers between users
(define-map trade-orders
  { id: uint }
  { seller: principal, buyer: (optional principal), price: uint, active: bool })

;; === VARIABLES ===
(define-data-var total-orders uint u0)
(define-data-var total-staked uint u0)
(define-data-var admin principal tx-sender)

;; === ADMIN FUNCTION ===

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    (var-set admin new-admin)
    (ok new-admin)
  )
)

;; === VAULT FUNCTIONS ===

(define-public (deposit (amount uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (let ((current (default-to u0 (get balance (map-get? user-balances { user: tx-sender })))))
      (map-set user-balances { user: tx-sender } { balance: (+ current amount) })
      (ok (+ current amount))
    )
  )
)

(define-public (withdraw (amount uint))
  (let ((current (default-to u0 (get balance (map-get? user-balances { user: tx-sender })))))
    (if (< current amount)
        ERR_NOT_ENOUGH_FUNDS
        (begin
          (map-set user-balances { user: tx-sender } { balance: (- current amount) })
          (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
          (ok amount)
        )
    )
  )
)

;; === STAKING SYSTEM ===

(define-public (stake (amount uint))
  (let ((current (default-to u0 (get balance (map-get? user-balances { user: tx-sender })))))
    (asserts! (>= current amount) ERR_NOT_ENOUGH_FUNDS)
    (if (is-some (map-get? user-stakes { user: tx-sender }))
        ERR_ALREADY_STAKED
        (begin
          (map-set user-stakes { user: tx-sender } { amount: amount, reward: u0, active: true })
          (map-set user-balances { user: tx-sender } { balance: (- current amount) })
          (var-set total-staked (+ (var-get total-staked) amount))
          (ok "Stake successful")
        )
    )
  )
)

(define-public (claim-reward)
  (let ((stake-data (map-get? user-stakes { user: tx-sender })))
    (match stake-data
      data
      (if (get active data)
          (let ((reward (/ (get amount data) u10))) ;; 10% reward
            (map-set user-stakes { user: tx-sender } (merge data { reward: reward, active: false }))
            (try! (stx-transfer? reward (as-contract tx-sender) tx-sender))
            (ok reward)
          )
          ERR_NOT_STAKED
      )
      ERR_NOT_STAKED
    )
  )
)

;; === SIMPLE P2P TRADE SYSTEM ===

(define-public (create-trade (price uint))
  (let ((id (+ (var-get total-orders) u1)))
    (begin
      (map-set trade-orders { id: id }
        { seller: tx-sender, buyer: none, price: price, active: true })
      (var-set total-orders id)
      (ok id)
    )
  )
)

(define-public (accept-trade (id uint))
  (let ((order (map-get? trade-orders { id: id })))
    (match order
      data
      (if (get active data)
          (begin
            (try! (stx-transfer? (get price data) tx-sender (get seller data)))
            (map-set trade-orders { id: id } (merge data { buyer: (some tx-sender), active: false }))
            (ok "Trade successful")
          )
          ERR_NO_SUCH_ORDER
      )
      ERR_NO_SUCH_ORDER
    )
  )
)

(define-public (cancel-trade (id uint))
  (let ((order (map-get? trade-orders { id: id })))
    (match order
      data
      (begin
        (asserts! (is-eq tx-sender (get seller data)) ERR_UNAUTHORIZED)
        (map-set trade-orders { id: id } (merge data { active: false }))
        (ok "Trade cancelled")
      )
      ERR_NO_SUCH_ORDER
    )
  )
)

;; === READ-ONLY FUNCTIONS ===

(define-read-only (get-balance (user principal))
  (ok (default-to u0 (get balance (map-get? user-balances { user: user }))))
)

(define-read-only (get-stake (user principal))
  (map-get? user-stakes { user: user })
)

(define-read-only (get-order (id uint))
  (map-get? trade-orders { id: id })
)

(define-read-only (get-total-orders)
  (ok (var-get total-orders))
)

(define-read-only (get-admin)
  (ok (var-get admin))
)
