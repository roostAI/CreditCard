Feature: Comprehensive API and UI Test Scenarios for Credit Card Management Portal

  # API Test Scenarios - Authentication & Registration

  @api
  Scenario Outline: Register user via API with varied inputs (valid, invalid, duplicate)
    Given the POST /v2/auth/register endpoint is accessible
    And no existing user account with email '<email>' (unless testing duplicate case)
    When I register with the following JSON payload:
      """
      {
        "first_name": "<first_name>",
        "last_name": "<last_name>",
        "email": "<email>",
        "password": "<password>",
        "date_of_birth": "<dob>",
        "phone_number": "<phone_number>",
        "ssn_last4": "<ssn_last4>",
        "agree_terms": true
      }
      """
    Then the API response status should be <status_code>
    And the response <response_validation>

    Examples:
      | first_name | last_name | email                   | password         | dob         | phone_number    | ssn_last4 | status_code | response_validation                                               |
      | John       | Doe       | john.doe+1@email.com    | Abcd1234$efgh    | 1995-04-12  | +14165551234    | 1234      | 201         | should contain user_id and verification_token                      |
      | Anna       | Smith     | anna.smith@email.com    | Password123$abc  | 2009-07-20  | +14165554321    | 4321      | 400         | should contain error for age constraint and message 'age >= 18'    |
      | Eric       | Dupont    | duplicate@email.com     | Dupont123$abc    | 1990-11-22  | +14165556789    | 9876      | 409         | should contain error: EMAIL_EXISTS                                 |

  @api
  Scenario Outline: Login behavior with and without MFA, lockout and rate limit
    Given a user account with email '<email>' and password '<password>' exists and is in state '<account_state>'
    When I attempt login via POST /v2/auth/login with credentials:
      """
      {
        "email": "<email>",
        "password": "<attempt_password>",
        "mfa_code": "<mfa_code>"
      }
      """
    Then the response status should be <status>
    And the response <result>

    Examples:
      | email                 | password           | attempt_password    | mfa_code | account_state | status | result                                                                      |
      | valid.user@email.com  | ValidPass2025      | ValidPass2025       |          | verified      | 200    | contains access_token, refresh_token, expires_in, portal access granted     |
      | mfa.user@email.com    | MFApass2026        | MFApass2026         | 123456   | mfa-enabled   | 200    | contains access_token, refresh_token, expires_in, MFA required, access when correct code |
      | lockuser@email.com    | SafePwd2026        | Incorrect1          |          | active        | 200    | should show failed login count incremented (repeat 5 times)                 |
      | lockuser@email.com    | SafePwd2026        | SafePwd2026         |          | locked        | 403    | contains error: ACCOUNT_LOCKED, unlock_at                                   |

  @api
  Scenario Outline: Login is rate-limited by IP address after excessive attempts
    Given a user and valid credentials exist
    And all requests are sent from IP '<ip_address>' within one minute
    When I send <attempt_num> POST /v2/auth/login requests in rapid succession
    Then the response status for the <attempt_num>th request should be <status>
    And the response <assertion>

    Examples:
      | ip_address   | attempt_num | status | assertion                                                          |
      | 10.0.0.1     | 10          | 200    | should return normal response                                      |
      | 10.0.0.1     | 11          | 429    | should contain error: RATE_LIMITED and retry_after                 |
      | 10.0.0.1     | 12          | 429    | should contain error: RATE_LIMITED                                 |

  # UI & State-Transition - Session Expiry and Warning Modal

  @ui
  Scenario: Session warning modal and auto-logout after inactivity
    Given I am logged into the portal dashboard with a valid session token
    When I remain inactive for 13 minutes
    Then I should see a session warning modal with a 2-minute countdown
    When I reach 15 minutes of inactivity
    Then I should be automatically logged out and redirected to login page

  @ui
  Scenario: Session warning modal displays exactly at 13 minutes inactivity
    Given I am logged into the portal and navigate to the account dashboard
    When I remain idle for 13 minutes
    Then I should see only a 2-minute warning modal, but no auto logout yet

  # API - Refresh Token Rotation and Session Renewal

  @api
  Scenario Outline: Refresh token rotation and single-use enforcement
    Given a valid user session with access_token and refresh_token
    When access_token expires and I POST /v2/auth/token/refresh using <refresh_token>
    Then the response status should be <status_code>
    And the response <result>

    Examples:
      | refresh_token   | status_code | result                                                    |
      | validToken1     | 200         | contains new access_token and refresh_token; old token invalidated |
      | validToken1     | 401         | contains error: TOKEN_INVALID; old refresh_token cannot renew session |

  # API - Credit Application Start and Duplication Prevention

  @api
  Scenario Outline: Start new credit application and prevent duplicates
    Given an authenticated user with email '<email>'
    And application status is '<existing_application_status>'
    When I POST /v2/applications/start with valid personal info:
      """
      {
        "full_legal_name": "<full_legal_name>",
        "email": "<email>",
        "phone_number": "<phone_number>",
        "residential_address": {
          "street": "123 Main St",
          "city": "Toronto",
          "province": "ON",
          "postal_code": "M4C 1A5"
        },
        "id_type": "<id_type>",
        "id_number": "<id_number>"
      }
      """
    Then the response status should be <status>
    And the response <result>

    Examples:
      | email                    | existing_application_status | full_legal_name   | phone_number   | id_type         | id_number        | status | result                                                  |
      | charlene.lee@email.com   | none                       | Charlene Lee      | +14165550123   | DRIVERS_LICENSE | DL1234567890XYZ  | 201    | contains application_id and session_token               |
      | charlene.lee@email.com   | active                     | Charlene Lee      | +14165550123   | DRIVERS_LICENSE | DL1234567890XYZ  | 409    | contains error: DUPLICATE_APPLICATION; no new app/session_token |

  # API - Credit Application Financials Submission & Boundaries

  @api
  Scenario Outline: Submit financials, reject expired session, and test income boundary
    Given a valid application_id and session_token
    When I POST /v2/applications/<application_id>/financials with financial details:
      """
      {
        "employment_status": "EMPLOYED",
        "employer_name": "Acme Corp",
        "gross_annual_income": <income>,
        "other_income": 5000.00,
        "monthly_rent": 1200.00,
        "existing_debt_payments": 500.00,
        "sin_consent": true
      }
      """
    And session_token used is <token_state>
    Then the response status should be <status>
    And the response <assertion>

    Examples:
      | application_id | income         | token_state | status | assertion                                                  |
      | A1001          | 55000.00       | valid       | 200    | contains status: PENDING_REVIEW and fico_pull_id           |
      | A1001          | 9999999.99     | valid       | 200    | financials accepted; queued for credit pull                |
      | A1001          | 10000000.00    | valid       | 400    | contains field validation error for gross_annual_income    |
      | A1001          | 55000.00       | expired     | 401    | contains error: SESSION_EXPIRED; financials not saved      |

  # API - Application Submit and Decision Logic (Approval/Decline)

  @api
  Scenario Outline: Submit application with e-signature; auto-approve, decline logic
    Given credit application in state '<state>' with FICO score <fico_score>
    And valid card_product_id and session_token
    When I POST /v2/applications/<application_id>/submit with:
      """
      {
        "application_id": "<application_id>",
        "card_product_id": "<card_product_id>",
        "e_signature": "<e_signature>"
      }
      """
    Then the response status should be <status>
    And the response <decision_result>

    Examples:
      | application_id | card_product_id | e_signature       | state   | fico_score | status | decision_result                                             |
      | AP2001         | CP3001          | cGFuYXNpZ25lZA==  | step3   | 700        | 200    | includes decision: APPROVED, credit_limit, card_number_masked |
      | AP2002         | CP3001          | cGFuYXNpZ25lZA==  | step3   | 590        | 200    | includes decision: DECLINED, reason_code                   |

  # UI - Draft Autosave To localStorage

  @ui
  Scenario Outline: Application draft autosave and recovery
    Given I am authenticated and on credit application step '<step>'
    And localStorage is empty before starting
    When I enter personal info and wait <wait_time> seconds
    Then the draft entry appears in localStorage
    When I refresh the page
    Then the form recovers state from localStorage
    When I submit the application or clear localStorage
    Then no draft remains

    Examples:
      | step | wait_time |
      | 1    | 60        |
      | 2    | 120       |

  # API - Transaction Initiation, Limits, and Errors

  @api
  Scenario Outline: Initiate payment, handle buffer, invalid and frequency errors
    Given an authenticated user with account_id '<account_id>' and available_credit <available_credit>
    And merchant classified as '<merchant_type>' with mcc_code '<mcc_code>'
    When I POST /v2/accounts/<account_id>/transactions with payload:
      """
      {
        "transaction_amount": <transaction_amount>,
        "merchant_name": "<merchant_name>",
        "merchant_id": "<merchant_id>",
        "mcc_code": "<mcc_code>",
        "transaction_type": "<transaction_type>",
        "currency_code": "<currency_code>"
      }
      """
    Then the response status should be <status>
    And the response <result>

    Examples:
      | account_id | available_credit | merchant_type | mcc_code | transaction_amount | merchant_name | merchant_id | transaction_type | currency_code | status | result                                                           |
      | ACC1001    | 1000.00         | retail        | 5732     | 250.00            | BestBuy       | M8001       | PURCHASE        | CAD           | 200    | contains transaction_id, available_credit, auth_code             |
      | ACC1001    | 150.00          | retail        | 5310     | 200.00            | Amazon        | M8002       | PURCHASE        | CAD           | 402    | contains error: INSUFFICIENT_FUNDS, available_credit             |
      | ACC1001    | 1000.00         | essential     | 4900     | 1040.00           | UtilityCo     | M8010       | PURCHASE        | CAD           | 200    | over_limit_flag: true                                            |
      | ACC1001    | 1000.00         | essential     | 4900     | 1051.00           | UtilityCo     | M8010       | PURCHASE        | CAD           | 402    | contains error: INSUFFICIENT_FUNDS                               |
      | ACC1001    | 1000.00         | retail        | 5732     | 0.00              | BestBuy       | M8001       | PURCHASE        | CAD           | 422    | contains error: INVALID_AMOUNT                                   |
      | ACC1001    | 1000.00         | retail        | 5732     | -10.00            | BestBuy       | M8001       | PURCHASE        | CAD           | 422    | contains error: INVALID_AMOUNT                                   |

  @api
  Scenario Outline: Enforce transaction frequency limit
    Given user '<user_id>' has initiated <txn_count> transactions in past hour
    When I POST /v2/accounts/<account_id>/transactions for the <next_txn>th payment
    Then the response status should be <status>
    And the response <result>

    Examples:
      | user_id | account_id | txn_count | next_txn | status | result                                         |
      | U1001   | ACC1001    | 10        | 11       | 429    | contains error: FREQ_EXCEEDED, mfa_required: true |

  # API - List Transactions with Pagination and Authorization

  @api
  Scenario Outline: List transactions with pagination/filter and forbidden access
    Given user '<user_id>' is authenticated with JWT token
    And account_id '<account_id>' is <ownership_status>
    When I GET /v2/accounts/<account_id>/transactions with query:
      """
      from_date=<from>
      to_date=<to>
      page=<page>
      per_page=<per_page>
      """
    Then the response status should be <status>
    And the response <fields>

    Examples:
      | user_id | account_id | ownership_status | from         | to           | page | per_page | status | fields                                 |
      | U1002   | ACC1002    | owned           | 2024-01-01   | 2024-04-01   | 1    | 20       | 200    | contains paginated array, total_count, page, total_pages |
      | U1002   | ACC1002    | owned           | 2024-01-01   | 2024-04-01   | 2    | 20       | 200    | contains next segment of results                       |
      | U1003   | ACC9999    | not-owned       | 2024-01-01   | 2024-04-01   | 1    | 20       | 403    | contains error: FORBIDDEN; no transaction data         |

  # API - Foreign Transaction Fee Calculation

  @api
  Scenario Outline: Apply 3% foreign transaction fee for non-CAD payments
    Given account_id '<account_id>' with sufficient available_credit and currency_code '<currency>'
    When I POST /v2/accounts/<account_id>/transactions with:
      """
      {
        "transaction_amount": <amount>,
        "currency_code": "<currency>",
        "exchange_rate": <rate>
      }
      """
    Then the response status should be 200
    And the response includes itemised foreign_fee_amount and total_cad as per formula

    Examples:
      | account_id | amount | currency | rate | foreign_fee_amount | total_cad |
      | ACC2001    | 100.00 | USD      | 1.34 | 4.02              | 137.02    |

  # API - Dashboard Summary

  @api
  Scenario Outline: Get account summary and points with owner-only access
    Given user '<user_id>' is authenticated
    And account_id '<account_id>' is <ownership_status>
    When I GET /v2/accounts/<account_id>/summary?include_rewards=true
    Then the response status should be <status>
    And the response <fields>

    Examples:
      | user_id | account_id | ownership_status | status | fields                                               |
      | U1001   | ACC2001    | owned           | 200    | includes current_balance, available_credit, account_status, billing_cycle_end, points_balance |
      | U1002   | ACC9999    | not-owned       | 403    | contains error: FORBIDDEN                            |

  # API - Card Freeze, Transition, Lost Reporting & PIN Setup

  @api
  Scenario Outline: Freeze card, invalid transitions, report lost
    Given card_id '<card_id>' owned by user with status '<card_status>'
    And valid OTP '<otp>' is available
    When I PATCH /v2/cards/<card_id>/status or POST /v2/cards/<card_id>/report-lost with payload:
      """
      {
        "status": "<new_status>",
        "confirm_otp": "<otp>",
        "reason": "<reason>",
        "loss_type": "<loss_type>"
      }
      """
    Then the response status should be <status>
    And the response <result>

    Examples:
      | card_id | card_status | new_status | otp    | reason                | loss_type | status | result                                                                   |
      | C5001   | Active      | Frozen     | 123456 | User proactive freeze |           | 200    | contains card_id, new_status: Frozen, updated_at; audit trail entry      |
      | C5002   | Active      | Blocked    | 654321 |                      |           | 400    | error: INVALID_TRANSITION; allowed_transitions: [Active, Frozen]         |
      | C5003   | Active      |            |        |                      | LOST      | 200    | blocked_card_id, new_card_eta, case_number; irreversible; Blocked state  |
      | C5004   | Blocked     |            |        |                      | LOST      | 409    | error: ALREADY_BLOCKED; no workflow triggered                            |

  @api
  Scenario Outline: Set PIN, validate blocked card error
    Given card_id '<card_id>' with status '<card_status>'
    And valid session_otp '<otp>' is available
    When I PUT /v2/cards/<card_id>/pin with payload:
      """
      {
        "new_pin": "<new_pin>",
        "confirm_pin": "<confirm_pin>",
        "session_otp": "<otp>"
      }
      """
    Then the response status should be <status>
    And the response <result>

    Examples:
      | card_id | card_status | new_pin | confirm_pin | otp    | status | result                                                                |
      | C6001   | Active      | 4827    | 4827        | 123456 | 200    | success: true; updated_at timestamp; audit log entry                  |
      | C6002   | Blocked     | 4567    | 4567        | 654321 | 403    | error: CARD_BLOCKED; PIN not changed; audit log shows rejection       |

  # API - Billing Statement Retrieval and Validation

  @api
  Scenario Outline: Retrieve statement in JSON and PDF format, validate fields and calculations
    Given account_id '<account_id>' is owned by user, and statement_id '<statement_id>' is valid
    When I GET /v2/accounts/<account_id>/statements/<statement_id> with formatEnum='<format>'
    Then the response status should be <status>
    And the response <result>

    Examples:
      | account_id | statement_id | format | status | result                                                                                             |
      | ACC1001    | S1001        | JSON   | 200    | JSON response includes all required fields: statement_date, total_spend, adb, interest_charged      |
      | ACC1001    | S1001        | PDF    | 200    | content-type 'application/pdf', downloadable PDF with statement details                             |
      | ACC1001    | S9999        | JSON   | 404    | error: NOT_FOUND                                                                                   |

  @api
  Scenario Outline: Validate statement field accuracy and interest/late fee calculations
    Given account_id '<account_id>' and statement_id '<statement_id>' with posted transactions
    When I GET /v2/accounts/<account_id>/statements/<statement_id>
    Then total_spend should equal sum of transactions within ±$0.01
    And interest_charged and late_fee field should match calculated values as per rules

    Examples:
      | account_id | statement_id | adb     | apr   | days | expected_interest | due_date     | payment_date   | expected_late_fee |
      | ACC2001    | S2001        | 1000.00 | 0.24  | 30   | 19.73             | 2026-03-15   | 2026-03-18     | 35.00             |
      | ACC2001    | S2001        | 1000.00 | 0.24  | 30   | 19.73             | 2026-03-15   | 2026-03-17     | 0.00              |

  # API - Rewards Accrual Floor Logic

  @api
  Scenario: Rewards accrual with floor rounding for Travel/Other MCC
    Given card is Active and user is authenticated
    When I make a purchase of $123.45 to MCC 4411 (Travel) and $99.99 to MCC 5311 (Retail)
    Then the subsequent statement should show rewards_earned of 370 points for Travel and 99 for Retail, using floor() logic

  # API - Payments and Minimum Payment Validation

  @api
  Scenario Outline: Make payment and reject below minimum required
    Given account_id '<account_id>' is active with statement minimum_payment_due <minimum_due>
    And bank_account_id '<bank_account_id>' is linked
    When I POST /v2/accounts/<account_id>/payments with payload:
      """
      {
        "payment_amount": <payment_amount>,
        "payment_type": "<payment_type>",
        "bank_account_id": "<bank_account_id>",
        "scheduled_date": "<scheduled_date>"
      }
      """
    Then the response status should be <status>
    And the response <result>

    Examples:
      | account_id | bank_account_id | minimum_due | payment_amount | payment_type     | scheduled_date | status | result                                                            |
      | acc123     | ba456           | 75.00       | 250.00         | STATEMENT_BALANCE| today          | 200    | payment_id, scheduled_date, new_balance_estimate, audit log entry |
      | acc123     | ba456           | 75.00       | 50.00          | MINIMUM          | today          | 400    | error: BELOW_MINIMUM, minimum_payment_due                         |

  # Security UI/Network - PAN Masking and Tokenisation

  @ui
  Scenario Outline: Card number masking compliance (PAN extraction)
    Given user is logged in and views card details in the web portal UI
    When I inspect the card number display
    Then only the masked format "<masked_pan>" should be visible in UI and DOM
    And no full PAN should be present in DOM, in network responses, or frontend code

    Examples:
      | masked_pan            |
      | **** **** **** 9876   |

  @ui
  Scenario Outline: Card entry fields rendered with PCI-compliant iframe tokenization
    Given user accesses card application/payment form on the portal
    When I inspect the card entry fields
    Then all card fields should be rendered inside iframe elements
    And no raw PAN data should exist in browser DOM or memory
    And only tokenized values are transmitted in network requests

    Examples:
      | field         |
      | card_number   |
      | expiry_date   |
      | cvv           |

  # API - Allow Account Closure within 14 Days Post Issuance

  @api
  Scenario Outline: Account deletion allowed within 14 days, forbidden after
    Given account '<account_id>' created <days_since_issuance> days ago and user is authenticated
    When I DELETE /v2/accounts/<account_id>
    Then the response status should be <status>
    And the response <result>

    Examples:
      | account_id | days_since_issuance | status | result                                       |
      | acc789     | 10                  | 200    | account deleted and success returned         |
      | acc789     | 15                  | 400    | error: right to rescind expired, account remains active |

  # Security - CSRF Token Enforcement

  @api
  Scenario Outline: Enforce CSRF token on state-changing endpoints
    Given valid authentication and available CSRF token '<csrf_token>'
    When I call <method> /v2/<resource>/<id> with or without X-CSRF-Token header
    Then the response status should be <status>
    And SameSite=Strict cookie should be verified

    Examples:
      | method | resource      | id    | csrf_token      | status |
      | POST   | accounts      | acc123| valid_token     | 200    |
      | POST   | accounts      | acc123| <missing>       | 401    |
      | PATCH  | cards/status  | C5001 | valid_token     | 200    |
      | PATCH  | cards/status  | C5001 | <missing>       | 401    |
      | DELETE | accounts      | acc789| valid_token     | 200    |
      | DELETE | accounts      | acc789| <missing>       | 401    |

  # Security - Audit Log Enforcement on Credit Limit Changes

  @api
  Scenario: Audit log created for credit limit change
    Given account is active and eligible for credit limit modification
    When I PATCH /v2/accounts/{id}/credit-limit to increase credit limit from $2,000 to $2,500
    Then the audit log should contain entry with user_id, session_id, ip_address, timestamp_utc, action_type 'CREDIT_LIMIT_CHANGE'
    And entry should be immutable and non-editable

  # Boundary - API Gateway Scalability & Rate Limits

  @api
  Scenario: API gateway rate-limits and auto-scaling under heavy load
    Given load test infrastructure can generate up to 5,000 concurrent requests/sec
    When I ramp up POST /v2/accounts/{id}/summary to 5,000 RPS
    Then all responses should be successful with p95 latency ≤1,500ms until 5,000 RPS
    When CPU usage exceeds 70%
    Then auto-scaling events should trigger and system should continue processing
    When exceeding gateway rate-limits, throttling or HTTP 429 must be enforced

  # API - Notifications & Alert Webhooks (Event Triggers and Validations)

  @api
  Scenario Outline: Notification delivery via webhook for all event types, validation and boundaries
    Given user account '<account_id>' and notification engine is operational
    When I POST /v2/notifications/webhook with payload:
      """
      {
        "account_id": "<account_id>",
        "alert_type": "<alert_type>",
        "channel": "<channel>",
        "message_body": "<message_body>",
        "severity": "<severity>",
        "idempotency_key": "<idempotency_key>"
      }
      """
    Then the response status should be <status>
    And response should contain notification_id (UUID), delivered_at (UTC), and channel
    And logs/audit confirm delivery as per event, with one notification per event

    Examples:
      | account_id | alert_type        | channel   | message_body                              | severity   | idempotency_key         | status | event_verification                                                                              |
      | ACC3001    | LATE_PAYMENT      | EMAIL     | Payment overdue                            | WARNING    | UUID-late-1            | 200    | alert delivered to email and in-app, logs confirm correct content                                |
      | ACC3001    | PIN_LOCKED        | IN_APP    | PIN attempts exceeded                      | CRITICAL   | UUID-pin-1             | 200    | alert delivered in-app with CRITICAL severity                                                   |
      | ACC3002    | FRAUD_FLAG        | SMS       | Suspicious transaction detected            | CRITICAL   | UUID-fraud-1           | 200    | SMS notification delivered with correct fields                                                  |
      | ACC3002    | FRAUD_FLAG        | PUSH      | Suspicious transaction detected            | CRITICAL   | UUID-fraud-2           | 200    | PUSH notification delivered with correct fields                                                 |
      | ACC3003    | OVER_LIMIT        | EMAIL     | Your account exceeded credit limit         | WARNING    | UUID-over-1            | 200    | OVER_LIMIT alert delivered to user with WARNING severity                                        |
      | ACC3004    | STATEMENT_READY   | IN_APP    | Your new statement is available            | INFO       | UUID-stmt-1            | 200    | in-app notification delivered, fields correct                                                   |
      | ACC3005    | LATE_PAYMENT      | EMAIL     | <500 char string                           | WARNING    | UUID-late-2            | 200    | message_body within 500 chars, notification delivered                                           |
      | ACC3005    | LATE_PAYMENT      | EMAIL     | <501 char string                           | WARNING    | UUID-late-3            | 400    | error for exceeding character limit; notification rejected                                      |
      | ACC4001    | MAINTENANCE_ALERT | SMS       | Attempt unsupported alert type              | INFO       | UUID-invalid-1         | 400    | error: INVALID_ALERT_TYPE, no notification delivered                                            |
      | ACC4002    | XSS_ATTACK        | EMAIL     | Another unsupported alert type              | WARNING    | UUID-invalid-2         | 400    | error: INVALID_ALERT_TYPE, no notification delivered                                            |
      | ACC4003    | OVER_LIMIT        | PUSH      | Exceeded credit limit                      | WARNING    | UUID-over-dup          | 200    | notification delivered                                                                         |
      | ACC4003    | OVER_LIMIT        | PUSH      | Exceeded credit limit                      | WARNING    | UUID-over-dup          | 409    | error: DUPLICATE_NOTIFICATION; no duplicate notification sent                                    |

  @api
  Scenario Outline: Notification metadata verification
    Given a notification with valid payload is POSTed to /v2/notifications/webhook
    When API returns notification_id and delivered_at
    Then delivered_at should match actual delivery UTC timestamp
    And notification_id is unique per alert

    Examples:
      | payload_type | notification_id_format | channel | delivered_at_format |
      | LATE_PAYMENT | UUID                   | EMAIL   | UTC timestamp       |

  @api
  Scenario Outline: Notification triggers required for all enumerated alert types
    Given system event of type '<alert_type>' occurs for account '<account_id>'
    When Notification Engine triggers POST /v2/notifications/webhook
    Then the response status should be 200
    And logs/audit confirm one notification per event

    Examples:
      | alert_type        | account_id |
      | LATE_PAYMENT      | ACC5001    |
      | PIN_LOCKED        | ACC5001    |
      | FRAUD_FLAG        | ACC5002    |
      | OVER_LIMIT        | ACC5001    |
      | STATEMENT_READY   | ACC5003    |
