Feature: Cardholder Portal and API Functional, Negative, Boundary, Security, and End-to-End Scenarios

  # Background for API scenarios
  Background:
    Given the API base URL is "https://portal.aegiscard.com"
    And the Content-Type is "application/json"
    And authentication tokens are set where required

  # -------------------------------------------------------
  # Registration and Authentication - API & UI
  # -------------------------------------------------------

  @api @ui
  Scenario Outline: User registration flow validation
    Given I am on the registration page
    And I enter "<first_name>" and "<last_name>" as names
    And I provide the unique email "<email>"
    And I set password "<password>"
    And I enter date_of_birth "<date_of_birth>"
    And I enter phone number "<phone>"
    And I input SSN last four digits "<ssn4>"
    And I check 'agree_terms' checkbox
    When I submit the registration form
    Then the API POST "/v2/auth/register" is called with payload
      """
      {
        "first_name": "<first_name>",
        "last_name": "<last_name>",
        "email": "<email>",
        "password": "<password>",
        "date_of_birth": "<date_of_birth>",
        "phone": "<phone>",
        "ssn_last_four": "<ssn4>",
        "agree_terms": true
      }
      """
    And I expect a response status <status> and <result>
    And the UI displays <ui_feedback>
    And verification email is <email_status>
    And no sensitive data is exposed in localStorage or DOM
    And audit log records <audit_event>

    Examples:
      | first_name | last_name | email                | password            | date_of_birth | phone          | ssn4 | status | result                | ui_feedback                               | email_status            | audit_event     |
      | John       | Doe       | john.doe@xyz.com     | StrongPass1!@#      | 2000-01-01    | +12223334444   | 1234 | 201    | user_id & verification_token | Registration success, check email         | delivered               | registration    |
      | Jane       | Smith     | jane.smith@xyz.com   | StrongPass2@#A      | 2006-05-05    | +14445556677   | 9876 | 400    | error: underage         | Registration rejected: Age <18            | not_sent                | registration_fail|
      | Max        | Power     | max.power@xyz.com    | abcdefg123          | 1980-12-31    | +15551223344   | 5566 | 422    | error: WEAK_PASSWORD    | Password strength error                   | not_sent                | registration_fail|

  # -------------------------------------------------------
  # Authentication: Login, Rate-Limit, Lock - API
  # -------------------------------------------------------

  @api
  Scenario Outline: Login and account lockout scenarios
    Given the user is registered and email verified with "<user_status>" status
    When the user attempts login with email "<email>" and password "<pass>" for attempt <attempt>
    Then POST "/v2/auth/login" is called
    And API returns <http_status> with <response>
    And audit log contains <audit_event>

    Examples:
      | user_status | email                 | pass            | attempt | http_status | response                        | audit_event           |
      | Active      | john.doe@xyz.com      | StrongPass1!@#  | 1       | 200         | access_token, refresh_token     | login_success         |
      | Active      | john.doe@xyz.com      | wrongpass       | 1       | 401         | error: INVALID_CREDENTIALS      | login_fail            |
      | Active      | john.doe@xyz.com      | wrongpass       | 5       | 403         | error: ACCOUNT_LOCKED, unlock_at| account_locked        |

  @api
  Scenario Outline: Login rate limit boundary scenario
    Given the user is registered and account is not locked
    And requests come from IP "<ip>"
    When <request_count> login attempts are made within a minute
    Then API POST "/v2/auth/login" returns <api_status> and <api_response>
    And audit log records <log_event>

    Examples:
      | ip           | request_count | api_status | api_response                 | log_event         |
      | 192.168.1.1  | 10           | 200/401    | success or fail              | login_events      |
      | 192.168.1.1  | 11           | 429        | error: RATE_LIMITED,retry_after| rate_limited      |

  # -------------------------------------------------------
  # Token Refresh - API
  # -------------------------------------------------------

  @api
  Scenario Outline: Token refresh and reuse validation
    Given user session with valid access_token and refresh_token
    When user calls POST "/v2/auth/token/refresh" with refresh_token "<refresh_token>"
    Then API returns <status_code> and <token_result>
    And cookies are updated securely
    And audit log records token refresh
    When user reuses refresh_token "<refresh_token>"
    Then API returns 401 TOKEN_INVALID

    Examples:
      | refresh_token                  | status_code | token_result             |
      | valid_refresh_token_abc123     | 200         | new access_token,refresh_token |
      | reused_refresh_token_abc123    | 401         | error: TOKEN_INVALID     |

  # -------------------------------------------------------
  # Credit Application Step 1 - API & UI
  # -------------------------------------------------------

  @api @ui
  Scenario Outline: Start new credit application
    Given user is authenticated via the portal
    And has no existing active application
    And personal info entered: "<legal_name>", "<email>", "<phone>", "<address>", "<id_type>", "<id_number>"
    When user submits Step 1 form
    Then POST "/v2/applications/start" is called with payload
      """
      {
        "legal_name": "<legal_name>",
        "email": "<email>",
        "phone": "<phone>",
        "address": "<address>",
        "id_type": "<id_type>",
        "id_number": "<id_number>"
      }
      """
    And API returns <app_status> with <result_fields>
    And UI progresses to Step 2
    And audit log records "<audit_event>"

    Examples:
      | legal_name              | email            | phone         | address                   | id_type | id_number    | app_status | result_fields                      | audit_event         |
      | Johnathan D. Smith      | john@xyz.com     | +12223334444  | 123 Main St, Toronto ON   | DL      | D1234567     | 201        | application_id, session_token      | application_created |
      | Jane R. Doe             | jane@abc.com     | +15556667788  | 44 Baker St, Ottawa ON    | PASS    | P9876543     | 409        | error: DUPLICATE_APPLICATION       | duplicate_attempt   |

  # -------------------------------------------------------
  # Application Draft Auto-Save to localStorage - UI
  # -------------------------------------------------------

  @ui
  Scenario Outline: Application draft auto-save functionality
    Given logged in user is on credit application Step 1 form
    When partial data "<partial_data>" is entered
    And user pauses for "<wait_secs>" seconds
    Then draft is auto-saved to localStorage containing <fields_stored>
    And no sensitive fields are present in localStorage
    When application page is reloaded
    Then draft is restored on form
    And audit log may record draft save

    Examples:
      | partial_data             | wait_secs | fields_stored      |
      | legal_name, email        | 60        | name, address      |
      | legal_name, phone        | 60        | name, phone        |

  # -------------------------------------------------------
  # Application Financials Submission - API
  # -------------------------------------------------------

  @api
  Scenario Outline: Step 2 financial info submission and boundary test
    Given user is authenticated with session_token "<session_token>" and application_id "<application_id>"
    When user submits Step 2 financials with
      employment_status "<employment_status>"
      employer_name "<employer_name>"
      gross_annual_income "<income>"
      monthly_rent "<rent>"
      existing_debt_payments "<debts>"
      sin_consent "<sin_consent>"
    Then API POST "/v2/applications/<application_id>/financials" returns <status> and <response>
    And audit log records <audit_entry>

    Examples:
      | session_token        | application_id   | employment_status | employer_name | income        | rent  | debts | sin_consent | status | response                                          | audit_entry            |
      | session123           | app123           | EMPLOYED         | ACME Ltd      | 85000         | 1200  | 1000  | true        | 200    | status:PENDING_REVIEW, fico_pull_id               | credit_pull_event      |
      | session456           | app456           | EMPLOYED         | BigCorp       | 9999999.99    | 900   | 600   | true        | 200    | status:PENDING_REVIEW, fico_pull_id               | credit_pull_event      |
      | session789           | app789           | EMPLOYED         | SmallBiz      | 10000000.00   | 800   | 500   | true        | 400    | error: gross_annual_income exceeds maximum        | boundary_rejection     |

  @api
  Scenario Outline: Step 2 submission with expired session_token
    Given the session_token "<session_token>" is expired
    And application_id "<application_id>" is valid
    When user submits Step 2 financials
    Then API responds with HTTP 401 or 400 and error: SESSION_EXPIRED
    And no financial data is processed or stored
    And audit log records submission blocked

    Examples:
      | session_token          | application_id   | status | response              |
      | expired_token_abc      | app999           | 401    | error: SESSION_EXPIRED|

  # -------------------------------------------------------
  # Application Finalization - API
  # -------------------------------------------------------

  @api
  Scenario Outline: Application Step 3 outcomes (approved, declined, e-signature check)
    Given user is authenticated, application_id "<application_id>", session_token "<session_token>", credit pull is completed with FICO "<fico_score>"
    And a valid card_product_id "<card_product_id>" is selected
    When user submits Step 3 finalization with e_signature "<e_signature>"
    Then API POST "/v2/applications/<application_id>/submit" returns <status>, <decision>, and <extra_fields>
    And UI displays application decision feedback
    And audit log records <event>

    Examples:
      | application_id | session_token | fico_score | card_product_id | e_signature               | status | decision   | extra_fields                  | event             |
      | app321         | session321    | 700        | prodX           | QmFzZTY0VGVzdA==          | 200    | APPROVED   | credit_limit, card_number_masked| approved          |
      | app654         | session654    | 599        | prodY           | QmFzZTY0VGVzdA==          | 200    | DECLINED   | reason_code                   | declined          |
      | app987         | session987    | 690        | prodZ           |                           | 400    | error: SIGNATURE_REQUIRED |                    | signature_missing   |

  # -------------------------------------------------------
  # Payments - API & UI
  # -------------------------------------------------------

  @api @ui
  Scenario Outline: Initiate web payment and validate outcomes
    Given user is authenticated and owns account_id "<account_id>"
    When user initiates payment with amount "<amount>", merchant "<merchant_name>", merchant_id "<merchant_id>", mcc_code "<mcc_code>", currency "<currency>", transaction_type "<transaction_type>"
    Then POST "/v2/accounts/<account_id>/transactions" returns <payment_status> and <response_fields>
    And UI displays payment <ui_feedback>
    And audit log records <audit_event>

    Examples:
      | account_id | amount    | merchant_name | merchant_id | mcc_code | currency | transaction_type | payment_status | response_fields                             | ui_feedback             | audit_event        |
      | acc123     | 50.00     | BestBuy       | M12345      | 5812     | CAD      | PURCHASE        | 200           | transaction_id, updated_credit, auth_code    | Payment approved        | payment_record     |
      | acc456     | 2000.00   | GroceryGo     | M78910      | 5411     | CAD      | PURCHASE        | 200           | over_limit_flag:true, updated_credit         | Over limit, alert shown | over_limit_event   |
      | acc789     | 101.00    | CheapShop     | M33322      | 5691     | CAD      | PURCHASE        | 402           | error: INSUFFICIENT_FUNDS                    | Declined, insufficient funds | declined_payment  |
      | acc222     | 15.00     | EatSt         | M22211      | 5812     | CAD      | PURCHASE        | 403           | error: CARD_INACTIVE, card_status: Frozen    | Card not active         | frozen_card_attempt|
      | acc333     | 0.01      | MiniShop      | M44444      | 5814     | CAD      | PURCHASE        | 200           | transaction_id, updated_credit               | Payment success         | boundary_payment   |
      | acc333     | 0.00      | MiniShop      | M44444      | 5814     | CAD      | PURCHASE        | 422           | error: INVALID_AMOUNT                        | Amount below minimum    | boundary_rejection |

  @api
  Scenario Outline: Payment frequency MFA enforcement boundary
    Given user is authenticated and card status is Active
    When user initiates <transaction_count> transactions within 60 minutes
    Then API returns <api_status> and <api_response>
    When MFA code "<mfa_code>" is supplied for 11th transaction
    Then API returns 200 and processes transaction
    And audit log records MFA event

    Examples:
      | transaction_count | api_status | api_response                     | mfa_code   |
      | 10                | 200        | transaction_id, updated_credit   |            |
      | 11                | 429        | error: FREQ_EXCEEDED, mfa_required:true | 123456     |

  @api
  Scenario Outline: Foreign transaction fee calculation
    Given user is authenticated, card status is Active, available_credit is sufficient
    When user initiates payment of "<amount>" "<currency>" with exchange_rate "<exchange_rate>"
    Then POST "/v2/accounts/{account_id}/transactions" returns 200 and
    And response includes "total_cad"=(<amount> × <exchange_rate> × 1.03), "foreign_fee_amount"=(<amount> × <exchange_rate> × 0.03)
    And available_credit is reduced by total_cad
    And statement itemizes foreign_fee
    And audit log records fee calculation

    Examples:
      | amount | currency | exchange_rate | total_cad | foreign_fee_amount |
      | 100.00 | USD      | 1.35          | 139.05    | 4.05              |

  # -------------------------------------------------------
  # Account Summary & Access Control - API
  # -------------------------------------------------------

  @api
  Scenario Outline: Retrieve account summary
    Given user is authenticated and owns account_id "<account_id>"
    When user requests GET "/v2/accounts/<account_id>/summary" with include_rewards "<include_rewards>"
    Then API returns 200 and summary fields current_balance, available_credit, credit_limit, account_status, billing_cycle_end, points_balance if rewards requested
    And audit log records summary access

    Examples:
      | account_id | include_rewards |
      | acc123     | true           |
      | acc123     | false          |

  @api
  Scenario Outline: Account summary forbidden for non-owners
    Given user is authenticated with account_id "<other_account_id>" not owned
    When user requests account summary
    Then API returns 403 with error: FORBIDDEN
    And no sensitive data is returned
    And audit log records access denial

    Examples:
      | other_account_id |
      | acc999           |

  # -------------------------------------------------------
  # Card Status and Controls - API & UI
  # -------------------------------------------------------

  @ui @api
  Scenario Outline: Card freeze flow with OTP and audit logging
    Given user is authenticated, card status is Active
    When user initiates Freeze card action via UI
    And receives OTP "<otp>"
    And submits PATCH "/v2/cards/<card_id>/status" with new_status=Frozen and OTP
    Then API returns 200 and new_status Frozen
    And audit log contains user_id, session_id, timestamp_utc, reason
    And UI reflects Frozen state

    Examples:
      | card_id   | otp     |
      | card789   | 123456  |

  @api
  Scenario Outline: Card freeze attempt with expired OTP
    Given user is authenticated, card status is Active
    When user submits PATCH "/v2/cards/<card_id>/status" with new_status=Frozen and OTP "<otp>"
    And OTP is expired
    Then API returns 401 and error: OTP_FAILED with attempts_remaining
    And audit log records failed OTP attempt

    Examples:
      | card_id   | otp     |
      | card456   | 654321  |

  @api
  Scenario Outline: Invalid card status transition
    Given user owns card_id "<card_id>", session and CSRF tokens valid
    When user attempts to PATCH "/v2/cards/<card_id>/status" with new_status "<new_status>"
    Then API returns 400 and error: INVALID_TRANSITION, allowed_transitions listed
    And audit log records failed transition

    Examples:
      | card_id | new_status  |
      | card123 | Blocked     |
      | card123 | Closed      |

  @api @ui
  Scenario Outline: Report card lost triggers irreversible block
    Given user is authenticated with card status "<initial_status>"
    When user reports card lost as loss_type "<loss_type>" via POST "/v2/cards/<card_id>/report-lost"
    Then API returns 200, blocked_card_id, new_card_eta, case_number
    When any status change is attempted on blocked card
    Then API returns error: ALREADY_BLOCKED
    And audit log records block event and replacement initiation
    And UI displays blocked state and replacement ETA

    Examples:
      | card_id  | initial_status | loss_type |
      | card999  | Active         | LOST      |
      | card888  | Frozen         | LOST      |

  @api
  Scenario Outline: Set virtual PIN successfully
    Given user is authenticated, card status is Active, RSA-OAEP encryption established
    When user requests session OTP and submits PUT "/v2/cards/<card_id>/pin" with new_pin "<pin>", confirm_pin "<pin>", session_otp "<otp>"
    Then API returns 200, success true, updated_at
    And audit log records PIN set event (user_id, timestamp, masked_pan)
    When user attempts login or transaction using new PIN
    Then PIN is effective

    Examples:
      | card_id | pin   | otp     |
      | card321 | 1234  | 789456  |

  # -------------------------------------------------------
  # Billing and Statements - API
  # -------------------------------------------------------

  @api
  Scenario Outline: Retrieve statement in JSON format
    Given user is authenticated, account_id "<account_id>", statement_id "<statement_id>"
    When user calls GET "/v2/accounts/<account_id>/statements/<statement_id>?format=JSON"
    Then API returns 200 and JSON object with statement_date, total_spend, adb, interest_charged, late_fee, rewards_earned, minimum_payment_due, due_date
    And monetary values are accurate to two decimals
    And identifiers are masked (e.g., ****1234)
    And audit log records statement access

    Examples:
      | account_id | statement_id  |
      | acc111     | stmt123       |

  @api
  Scenario Outline: Statement not found returns error
    Given user is authenticated, account_id "<account_id>"
    When user calls GET "/v2/accounts/<account_id>/statements/<invalid_statement_id>"
    Then API returns 404 and error: NOT_FOUND
    And no statement or PII data is included in response
    And audit log records failed access attempt

    Examples:
      | account_id | invalid_statement_id |
      | acc111     | notexist-9876        |

  @api
  Scenario Outline: Billing statement interest calculation via ADB formula
    Given user has transaction activity and known APR, billing cycle days
    And ADB is "<adb>", APR is "<apr>", days_in_billing_cycle "<days>"
    When statement is generated
    Then API reported interest_charged is "<interest_expected>" (Interest = (ADB × APR / 365) × Days)
    And audit log records statement issuance

    Examples:
      | adb     | apr   | days | interest_expected |
      | 5000.00 | 0.21  | 30   | 86.30            |

  @api
  Scenario Outline: Grace period rule enforcement for payment in full
    Given user paid previous statement in full, new purchases made in current cycle
    When latest statement is generated
    Then API returns statement with interest_charged = 0 on new purchases
    And audit log records full payment and access

    Examples:
      | account_id |
      | acc222     |

  @api
  Scenario Outline: Late fee boundary check on payment timing
    Given statement due_date "<due_date>", payment date "<payment_date>"
    When payment is "<timing>"
    Then statement late_fee is <late_fee>
    And audit log shows payment and fee events

    Examples:
      | due_date    | payment_date  | timing         | late_fee |
      | 2023-06-10  | 2023-06-13    | >2 days late   | 35.00    |
      | 2023-06-10  | 2023-06-11    | <=2 days late  | 0.00     |

  @api
  Scenario Outline: Rewards calculation for travel MCC
    Given transactions at travel MCC "<mcc_code>" of "<spend>" CAD and at non-travel "<non_travel_spend>"
    When billing statement is generated
    Then rewards_earned is floor(travel_amt × 3 + non_travel_amt × 1)
    And audit log shows transaction and statement issuance

    Examples:
      | mcc_code | spend   | non_travel_spend | rewards_earned |
      | 4511     | 100.00  | 25.00            | 325            |
      | 5812     | 50.00   | 50.00            | 200            |

  @api
  Scenario Outline: Payment less than minimum triggers rejection
    Given open statement minimum_payment_due "<min_due>"
    When user attempts payment "<pay_amt>" via POST "/v2/accounts/<account_id>/payments"
    Then API returns 400 error: BELOW_MINIMUM with minimum_payment_due
    And audit log records failed payment attempt

    Examples:
      | account_id | min_due | pay_amt |
      | acc99      | 200.00  | 199.99  |

  # -------------------------------------------------------
  # Security - Masking, CSRF, TLS, Audit - API & UI
  # -------------------------------------------------------

  @ui @api
  Scenario Outline: Card PAN masking in browser and API
    Given user is authenticated with card_id "<card_id>", has statements and transactions
    When user views card details and statement via UI and API
    Then only masked PAN "<masked_pan>" is shown in UI, DOM, API responses
    And no full PAN is exposed anywhere
    And audit logs show no PAN leakage

    Examples:
      | card_id   | masked_pan          |
      | card999   | **** **** **** 1234 |
      | card888   | **** **** **** 5678 |

  @ui @api
  Scenario Outline: PCI-DSS L1 enforcement for TLS and tokenization
    Given user accesses card, payment, or PIN screens via web portal over HTTPS
    When inspecting form fields, network requests, and API payloads
    Then all requests use TLS 1.3
    And card entry fields are tokenized via PCI-compliant iframe
    And no PAN appears in DOM, JS, or payload
    When user attempts downgrade to TLS 1.2
    Then UI disables forms and displays compliance warning

    Examples:
      | screen           | card_field_behavior                  |
      | Make Payment     | iframe/token                         |
      | Set PIN          | iframe/token                         |

  @api
  Scenario Outline: Credit limit changes audited with full metadata
    Given privileged user submits credit limit change via UI/API for account "<account_id>"
    When change "<action>" of "<amount>" is requested
    Then API returns 200 and summary reflects new limit
    And audit log entry records user_id, session_id, ip_address, timestamp_utc

    Examples:
      | account_id | action   | amount |
      | acc555     | increase | 1000   |
      | acc555     | decrease | 500    |

  @api
  Scenario Outline: CSRF token required for state-changing API calls
    Given user initiates "<operation>" for account_id "<account_id>"
    When request is sent with <csrf_token_status>
    Then request <expected_result>
    And no state change occurs for invalid/missing token

    Examples:
      | operation       | account_id | csrf_token_status    | expected_result                                  |
      | payment         | acc999     | valid                | succeeds                                         |
      | freeze card     | card321    | missing              | rejected with error: CSRF_TOKEN_REQUIRED         |
      | set profile     | acc888     | expired              | rejected with error: CSRF_TOKEN_INVALID          |

  # -------------------------------------------------------
  # Security & Boundary - Session timeout (UI)
  # -------------------------------------------------------

  @ui
  Scenario Outline: Session timeout modal is shown after inactivity
    Given user is logged in to web portal
    When user remains inactive for <minutes> minutes
    Then at <modal_time> minutes, warning modal is shown
    And at <logout_time> minutes, user is logged out automatically
    And session tokens are invalidated
    When user attempts further interaction after logout
    Then portal redirects to login

    Examples:
      | minutes | modal_time | logout_time |
      | 13      | 13         | 15          |

  # -------------------------------------------------------
  # Notifications & Alerts - API
  # -------------------------------------------------------

  @api
  Scenario Outline: Real-time late payment alert via email
    Given user has overdue payment at least 2 days past due
    And email "<email>" is configured
    When LATE_PAYMENT event is triggered
    Then notification engine queues email with subject 'Late Payment'
    And email is delivered to "<email>" with correct amount and severity
    And audit log entry records notification event

    Examples:
      | email                |
      | john.doe@xyz.com     |
      | jane.smith@xyz.com   |

  @api
  Scenario Outline: Alert webhook rejects unknown alert_type
    Given API credentials are set
    When POST "/v2/notifications/webhook" is called with alert_type "<alert_type>"
    Then API returns 400 and error: INVALID_ALERT_TYPE
    And no notifications are queued or delivered

    Examples:
      | alert_type    |
      | UNKNOWN_TYPE  |
      | ALERT_123     |

  @api
  Scenario Outline: Duplicate notification idempotency_key triggers error
    Given API credentials and notification webhook
    And idempotency_key "<idempotency_key>" is used
    When POST "/v2/notifications/webhook" is sent first time
    Then API returns 200 and notification delivered
    When POST with same idempotency_key is sent again
    Then API returns 409 and error: DUPLICATE_NOTIFICATION
    And only one notification is delivered

    Examples:
      | idempotency_key        |
      | 8b6f7c6d-1234-9876-5555|
      | 2e4ad1d9-4432-2233-9999|

  @api
  Scenario Outline: Critical severity alert delivered via SMS
    Given user has mobile number "<mobile>" registered, SMS channel enabled
    When FRAUD_FLAG event with severity CRITICAL is triggered
    Then notification engine queues SMS alert to "<mobile>"
    And SMS is delivered with correct details
    And audit log records SMS sent event

    Examples:
      | mobile        |
      | +12223334444  |
      | +15556667788  |

  # -------------------------------------------------------
  # End-to-End Scenarios (UI & API)
  # -------------------------------------------------------

  @e2e @ui @api
  Scenario: End-to-end: registration through card dashboard access
    Given new user initiates registration flow
    When registration is submitted and email verification completed
    And user logs in with registered credentials
    And passes any MFA/TOTP prompt
    Then user is redirected to dashboard showing account summary
    And secure session cookie is set as HttpOnly and Secure
    And dashboard displays masked PAN only
    And audit log entry exists for onboarding event

  @e2e @ui @api
  Scenario: End-to-end: apply for card and make successful web payment
    Given activated portal user with no existing credit card initiates application
    When Step 1 (personal) and Step 2 (financial) are completed and approved
    And user selects card product and submits e-signature
    And receives approval and masked card details
    When user links bank account and makes web payment
    Then payment is processed, dashboard updated, and audit logs entries created

  @e2e @ui @api
  Scenario: End-to-end: billing, rewards, statement retrieval, payment flow
    Given user posts travel and non-travel transactions
    When billing cycle closes, statement is generated (JSON and PDF)
    Then statement includes total spend, ADB, interest, late fees, rewards (3x floored for travel MCC)
    And user makes minimum payment before and after due date, late fee logic applies
    And dashboard, history, and statements reflect accurate information and audit trail

  @e2e @ui @api
  Scenario: End-to-end: card status change, lost report, audit log verification
    Given user with active card initiates freeze, verifies via OTP, confirms Frozen state
    And audit log records freeze event with full metadata
    When user reports card as lost
    Then card status becomes Blocked irreversibly, replacement workflow initiates
    And dashboard displays ETA, case number, and masked PAN only
    And audit log records lost report event
    When user attempts transaction post-block
    Then error CARD_INACTIVE is returned
    And UI/API enforce allowed state transitions

  @e2e @ui @api
  Scenario: End-to-end: rescind account within eligibility window
    Given user with account less than 14 days old logs in
    When user triggers DELETE /v2/accounts/{id} via UI/API
    Then account is deleted without membership fee, access revoked, audit log entry created
    When user attempts deletion after 14 days
    Then API/UI rejects deletion with regulatory error
    And audit log records attempt

