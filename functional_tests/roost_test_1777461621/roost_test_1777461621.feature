Feature: Credit Card Portal - End-to-End API and UI, Security, Audit, Performance, Notification, and Regulatory Testing

  # Background for API scenarios requiring authentication and CSRF
  Background:
    Given the API base URL is "https://api.portal.com"
    And a valid Bearer token is acquired via login
    And a valid X-CSRF-Token is obtained for the session

  # Registration API Tests
  @api @registration
  Scenario Outline: User registration submits valid and invalid data
    Given no existing account with email "<email>"
    And the test environment can send emails
    When I send a POST request to "/v2/auth/register" with payload
      """
      {
        "first_name": "<first_name>",
        "last_name": "<last_name>",
        "email": "<email>",
        "password": "<password>",
        "date_of_birth": "<date_of_birth>",
        "phone_number": "<phone_number>",
        "ssn_last4": "<ssn_last4>",
        "agree_terms": <agree_terms>
      }
      """
    Then the response status should be <status>
    And the response body should contain <expected_fields>
    And if <verify_email>, a verification email is sent to "<email>"
    And if <error_code>, the response body contains error code "<error_code>"

    Examples:
      | first_name | last_name | email                        | password           | date_of_birth | phone_number    | ssn_last4 | agree_terms | status | expected_fields           | verify_email | error_code         |
      | Alice      | Smith     | alice.smith1990@example.com  | Secure@Passw0rd1   | 2000-03-10    | +14165551234    | 8421      | true        | 201    | user_id,verification_token | true         |                   |
      | John       | Duplicate | john.dup@example.com         | Secure@Passw0rd1   | 1992-02-20    | +14165556457    | 2350      | true        | 409    |                           | false        | EMAIL_EXISTS      |
      | Minor      | User      | minor.user@example.com       | Secure@Passw0rd1   | 2009-03-22    | +14165559001    | 9810      | true        | 422    |                           | false        | AGE_REQUIREMENT   |
      | Weak       | Pass      | weak.pass@example.com        | password123        | 2000-03-10    | +14165557655    | 5621      | true        | 422    |                           | false        | WEAK_PASSWORD    |

  # Authentication API Tests
  @api @auth
  Scenario Outline: Login attempt with correct and incorrect credentials
    Given a registered user with email "<email>" and correct/incorrect password "<password>"
    And the user is email-verified and enabled
    When I send a POST request to "/v2/auth/login" with payload
      """
      {
        "email": "<email>",
        "password": "<password>"
      }
      """
    Then the response status should be <status>
    And the response body should contain <fields_or_error>

    Examples:
      | email                       | password        | status | fields_or_error                                  |
      | user@example.com            | CorrectPa$$123  | 200    | access_token,refresh_token,expires_in           |
      | user@example.com            | WrongP@ssw0rd   | 401    | error: INVALID_CREDENTIALS                      |

  @api @auth
  Scenario: Account lockout after 5 failed logins
    Given a user account exists and is not locked
    When the user attempts to log in with incorrect password 5 times
    Then the fifth response status should be 403
    And the response body should contain error "ACCOUNT_LOCKED" and field "unlock_at"
    When the user attempts to log in a sixth time with the correct password
    Then the response status should be 403
    And the response body should contain error "ACCOUNT_LOCKED"

  @api @auth
  Scenario: Login rate limiting enforced per IP
    Given I submit 10 login requests within one minute from the same IP
    When I submit an 11th login request within the same minute
    Then the response status should be 429
    And the response body should contain error "RATE_LIMITED" and "retry_after"

  # Token Refresh API Scenarios
  @api @token
  Scenario Outline: Token refresh with valid and invalid refresh_token
    Given the user is authenticated and has access_token and refresh_token
    When I send a POST request to "/v2/auth/token/refresh" with payload
      """
      {
        "refresh_token": "<refresh_token>"
      }
      """
    Then the response status should be <status>
    And the response body should contain <fields_or_error>
    When I try to reuse "<refresh_token>" in another POST request after rotation
    Then the response status should be <reuse_status>
    And the response body should contain error "<reuse_error>"

    Examples:
      | refresh_token     | status | fields_or_error                        | reuse_status | reuse_error      |
      | valid_token_abc   | 200    | access_token,refresh_token             | 401          | TOKEN_INVALID    |
      | used_token_abc    | 401    | error: TOKEN_INVALID                   | 401          | TOKEN_INVALID    |

  # Session Expiry and Warning Modal Scenarios
  @api @session
  Scenario: Session expires after 15 minutes inactivity
    Given a user is logged in to the web portal and has a valid session and access token
    And no interaction occurs for 14 minutes
    When the user attempts to access a protected resource after 14 minutes
    Then the session is still active for 1 more minute
    When the user remains inactive for a total of 15 minutes
    Then the session expires
    And access to protected resources returns 401 error "SESSION_EXPIRED"
    When the user attempts to refresh token with expired session
    Then the response is rejected
    When the user logs in again
    Then access is restored

  @ui @session
  Scenario: Session timeout warning modal is displayed before expiry
    Given the user is authenticated and has been inactive for 13 minutes
    When I am on any portal page and have not interacted for 13 minutes
    Then I should see a warning modal stating "You will be logged out in 2 minutes due to inactivity"
    When I interact with the modal
    Then the session timer is reset and session remains active
    When I do not interact and reach 15 minutes inactivity
    Then the session expires and I am logged out, requiring re-authentication

  # Credit Card Application Workflow Tests - Step 1, Step 2, Step 3, Session Token Expiry
  @api @credit_application
  Scenario Outline: Step 1 - Personal info submission, duplicate application, session expiry
    Given user is authenticated with a valid session_token and application_id (if required)
    When I send a POST request to "/v2/applications/start" with payload
      """
      {
        "full_legal_name": "<full_legal_name>",
        "email": "<email>",
        "phone_number": "<phone_number>",
        "residential_address": {
          "street": "<street>",
          "city": "<city>",
          "province": "<province>",
          "postal_code": "<postal_code>"
        },
        "id_type": "<id_type>",
        "id_number": "<id_number>"
      }
      """
    Then the response status should be <status>
    And the response body should contain <fields_or_error>

    Examples:
      | full_legal_name | email                  | phone_number   | street         | city      | province | postal_code | id_type        | id_number       | status | fields_or_error                  |
      | Jane Smith      | jane.smith@example.com | +14165550123   | 123 Main St    | Toronto   | ON       | K1A 0B1     | DRIVERS_LICENSE | D123456789      | 201    | application_id,session_token     |
      | Jane Smith      | jane.smith@example.com | +14165550123   | 123 Main St    | Toronto   | ON       | K1A 0B1     | DRIVERS_LICENSE | D123456789      | 409    | error: DUPLICATE_APPLICATION     |

  @api @credit_application
  Scenario Outline: Step 2 - Financials submission and session expiry
    Given user has completed Step 1 with valid session_token and application_id
    When I send a POST request to "/v2/applications/<application_id>/financials" with payload
      """
      {
        "employment_status": "<employment_status>",
        "employer_name": "<employer_name>",
        "gross_annual_income": "<gross_annual_income>",
        "other_income": "<other_income>",
        "monthly_rent": "<monthly_rent>",
        "existing_debt_payments": "<existing_debt_payments>",
        "sin_consent": <sin_consent>
      }
      """
    And session_token header is "<session_token>"
    Then the response status should be <status>
    And the response body should contain <fields_or_error>

    Examples:
      | application_id | session_token           | employment_status | employer_name | gross_annual_income | other_income | monthly_rent | existing_debt_payments | sin_consent | status | fields_or_error        |
      | app-uuid-step2 | valid_session_token     | EMPLOYED         | Acme Corp     | 66000.00            | 5000.00      | 1200.00      | 400.00                 | true        | 200    | status:PENDING_REVIEW,fico_pull_id |
      | app-uuid-step2 | expired_session_token   | EMPLOYED         | Acme Corp     | 66000.00            | 5000.00      | 1200.00      | 400.00                 | true        | 401    | error: SESSION_EXPIRED |

  @api @credit_application
  Scenario Outline: Step 3 - Decision logic for FICO boundary
    Given user completed Steps 1 and 2 with valid application_id, session_token, and fico_pull_id
    When I send a POST request to "/v2/applications/<application_id>/submit" with payload
      """
      {
        "card_product_id": "<card_product_id>",
        "e_signature": "<e_signature>",
        "marketing_opt_in": <marketing_opt_in>
      }
      """
    And FICO score is "<fico_score>"
    Then the response status should be 200
    And the response body should contain <decision_fields>
    And auto-approval or auto-decline logic is correctly applied

    Examples:
      | application_id | card_product_id | e_signature   | marketing_opt_in | fico_score | decision_fields                              |
      | app-uuid-step3 | AEGIS_GOLD     | John Smith    | false            | 701        | decision: APPROVED,credit_limit,card_number_masked |
      | app-uuid-step3 | AEGIS_GOLD     | John Smith    | false            | 599        | decision: DECLINED,reason_code                |
      | app-uuid-step3 | AEGIS_GOLD     | John Smith    | false            | 580        | decision: DECLINED,reason_code                |

  # Transaction Tests - Payment, Over-Limit, Insufficient Funds, Boundaries, Frozen Card, Frequency Cap
  @api @transactions
  Scenario Outline: Transaction request with normal, over-limit, insufficient funds, invalid amount, card state, and frequency cap
    Given user is authenticated and has account_id "<account_id>" and card_id "<card_id>" with status "<card_status>"
    And available_credit is <available_credit>
    When I send a POST request to "/v2/accounts/<account_id>/transactions" with payload
      """
      {
        "transaction_amount": <transaction_amount>,
        "merchant_name": "<merchant_name>",
        "merchant_id": "<merchant_id>",
        "mcc_code": "<mcc_code>",
        "currency_code": "<currency_code>",
        "exchange_rate": <exchange_rate>,
        "transaction_type": "<transaction_type>"
      }
      """
    Then the response status should be <status>
    And the response body should contain <fields_or_error>
    And if "frequency cap" applies and transaction count > 10 in 60 min, response includes mfa_required:true

    Examples:
      | account_id | card_id | card_status | available_credit | transaction_amount | merchant_name  | merchant_id | mcc_code | currency_code | exchange_rate | transaction_type | status | fields_or_error                             |
      | acc-1001   | card-001| Active      | 2000.00         | 100.00            | Store ABC      | ABC123      | 5411     | CAD           | null          | PURCHASE        | 200    | transaction_id,available_credit,auth_code   |
      | acc-2002   | card-002| Active      | 1000.00         | 1050.00           | Hydro One      | HONE001     | 4900     | CAD           | null          | PURCHASE        | 200    | transaction_id,over_limit_flag:true         |
      | acc-1001   | card-001| Active      | 100.00          | 150.00            | Test Merchant  | TM001       | 5411     | CAD           | null          | PURCHASE        | 402    | error: INSUFFICIENT_FUNDS,available_credit  |
      | acc-1001   | card-001| Active      | 100.00          | 0.00              | Zero Shop      | ZR001       | 5411     | CAD           | null          | PURCHASE        | 422    | error: INVALID_AMOUNT                      |
      | acc-1001   | card-001| Active      | 100.00          | -0.01             | Neg Shop       | NEG001      | 5411     | CAD           | null          | PURCHASE        | 422    | error: INVALID_AMOUNT                      |
      | acc-3003   | card-003| Frozen      | 500.00          | 50.00             | Freeze Mart    | FRZ001      | 5411     | CAD           | null          | PURCHASE        | 403    | error: CARD_INACTIVE,card_status:Frozen     |
      | acc-4004   | card-004| Active      | 550.00          | 50.00             | Freq Merchant  | FM001       | 5411     | CAD           | null          | PURCHASE        | 429    | error: FREQ_EXCEEDED,mfa_required:true      |

  @api @transactions
  Scenario Outline: Foreign transaction fee calculation and exchange_rate boundary
    Given user is authenticated with account_id "<account_id>", card Active, available_credit sufficient
    When I send a POST request to "/v2/accounts/<account_id>/transactions" with payload
      """
      {
        "transaction_amount": <amount>,
        "merchant_name": "<merchant_name>",
        "merchant_id": "<merchant_id>",
        "mcc_code": "<mcc_code>",
        "currency_code": "<currency_code>",
        "exchange_rate": <exchange_rate>,
        "transaction_type": "<transaction_type>"
      }
      """
    Then the response status should be <status>
    And the response body should contain <fields_or_error>
    And if currency_code ≠ "CAD" and exchange_rate present, foreign_fee and total_CAD are calculated and itemised
    And if invalid exchange_rate precision, response contains error "INVALID_EXCHANGE_RATE"

    Examples:
      | account_id | amount  | merchant_name | merchant_id | mcc_code | currency_code | exchange_rate  | transaction_type | status | fields_or_error                                       |
      | acc-1001   | 100.00  | US Store      | US123       | 5411     | USD           | 1.32           | PURCHASE        | 200    | transaction_id,available_credit,foreign_fee_amount:3.96,total_CAD:135.96 |
      | acc-1001   | 200.00  | EU Merchant   | EU456       | 5411     | EUR           | 1.123456       | PURCHASE        | 200    | transaction_id,foreign_fee_amount                     |
      | acc-1001   | 200.00  | EU Merchant   | EU456       | 5411     | EUR           | 1.1234567      | PURCHASE        | 422    | error: INVALID_EXCHANGE_RATE                         |
      | acc-1001   | 200.00  | Large FX     | FX999       | 5411     | EUR           | 12345678.123456| PURCHASE        | 422    | error: INVALID_EXCHANGE_RATE                         |

  # Transaction History Retrieval - Pagination and Date Range
  @api @transactions
  Scenario Outline: Paginated and date-ranged transaction history retrieval
    Given user wants to retrieve transaction history for account_id "<account_id>" and is authenticated
    When I send a GET request to "/v2/accounts/<account_id>/transactions" with parameters page="<page>", per_page="<per_page>", from_date="<from_date>", to_date="<to_date>"
    Then the response status should be <status>
    And the response body should contain <fields_or_error>
    And for forbidden account access, response is 403

    Examples:
      | account_id | page | per_page | from_date    | to_date    | status | fields_or_error                                              |
      | acc-1001   | 1    | 25       |             |            | 200    | transactions[],total_count,page,total_pages                  |
      | acc-1001   | 2    | 10       |             |            | 200    | transactions[],total_count,page,total_pages                  |
      | acc-1001   | 1    | 25       | 2026-04-01  | 2026-03-01 | 400    | error: INVALID_DATE_RANGE                                    |
      | acc-9999   | 1    | 25       |             |            | 403    | error: FORBIDDEN                                             |

  # Dashboard Summary Retrieval and Rewards Point Display
  @api @dashboard
  Scenario Outline: Account dashboard summary and rewards retrieval
    Given user is authenticated and owns account_id "<account_id>"
    When I send a GET request to "/v2/accounts/<account_id>/summary" with include_rewards="<include_rewards>"
    Then the response status should be <status>
    And the response body should contain <fields_or_error>
    And for unauthorized account, response is 403

    Examples:
      | account_id | include_rewards | status | fields_or_error                                                     |
      | acc-1001   | true            | 200    | current_balance,available_credit,credit_limit,account_status,billing_cycle_end,points_balance |
      | acc-1002   | false           | 200    | current_balance,available_credit,credit_limit,account_status,billing_cycle_end               |
      | acc-9999   | true            | 403    | error: FORBIDDEN                                                    |

  # Card Management - Freeze/Unfreeze, Lost/Stolen Report, PIN Setting
  @ui @card_management
  Scenario Outline: Web card freeze/unfreeze workflow and PIN setting
    Given the user is logged in to the portal with valid session
    When I navigate to 'Card Management' and select card with status "<card_status>"
    And I click "<action_button>" and enter "<otp>" as OTP
    And I enter "<new_pin>" and "<confirm_pin>" for PIN setting/reset if action is "Set PIN"
    And I optionally submit a reasonString "<reasonString>" for action
    Then the API response status should be <status>
    And if action is "Freeze" or "Unfreeze", card status changes appropriately
    And if action is "Set PIN", PIN is set only if match and valid format
    And confirmation/alert is shown in UI

    Examples:
      | card_status | action_button   | otp        | new_pin | confirm_pin | reasonString          | status |
      | Active      | Freeze Card     | 123456     |         |             | Travel security       | 200    |
      | Frozen      | Unfreeze Card   | 654321     |         |             | Return from trip      | 200    |
      | Active      | Set PIN         | 222222     | 1234    | 1234        |                      | 200    |
      | Active      | Set PIN         | 222222     | 1234    | 2345        |                      | 400    |
      | Active      | Set PIN         | 222222     | 123     | 123         |                      | 400    |

  @api @card_management
  Scenario Outline: Lost or stolen card reporting and rejection
    Given user is authenticated with card_id "<card_id>" and status "<card_status>"
    When I send a POST request to "/v2/cards/<card_id>/report-lost" with payload
      """
      {
        "loss_type": "<loss_type>",
        "last_known_use": "<last_known_use>",
        "delivery_address": "<delivery_address>"
      }
      """
    Then the response status should be <status>
    And the response body should contain <fields_or_error>

    Examples:
      | card_id   | card_status | loss_type | last_known_use | delivery_address     | status | fields_or_error                                       |
      | card-001  | Active      | LOST      | 2026-03-01     | 111 Queen St, Toronto| 200    | blocked_card_id,new_card_eta,case_number              |
      | card-002  | Blocked     | STOLEN    | 2026-03-01     | 222 King St, Toronto | 409    | error: ALREADY_BLOCKED                                |

  # Billing Statement Retrieval and Error Handling
  @api @billing
  Scenario Outline: Billing statement retrieval and not found handling
    Given user is authenticated with account_id "<account_id>", owns account, and has valid statement_id "<statement_id>"
    When I send a GET request to "/v2/accounts/<account_id>/statements/<statement_id>" with format "<format>"
    Then the response status should be <status>
    And the response body should contain <fields_or_error>

    Examples:
      | account_id | statement_id   | format | status | fields_or_error                                             |
      | acc-1001   | st-2026-06     | JSON   | 200    | statement_date,total_spend,adb,interest_charged,late_fee,rewards_earned,minimum_payment_due,due_date |
      | acc-1001   | st-2026-06     | PDF    | 200    | PDF download                                                |
      | acc-1001   | st-missing     | JSON   | 404    | error: NOT_FOUND                                            |
      | acc-1001   | st-future      | JSON   | 404    | error: NOT_FOUND                                            |

  # Financial Statement Calculation and Boundary Logic
  @api @billing
  Scenario Outline: Interest, grace period, late fee, rewards boundary scenarios
    Given user is authenticated with account_id "<account_id>", has statement data for scenario
    When I retrieve statement for period and examine fields
    And I compute expected values based on "<scenario>"
    Then API-calculated values match expected
    And rewards, interest, late fee are applied as specified per boundary and rounding rules

    Examples:
      | account_id | statement_id   | scenario                         | expected_interest | expected_grace | expected_late_fee | expected_rewards |
      | acc-1001   | st-2026-06     | ADB=2000,APR=19.99,Days=30       | 32.86            |               |                  |                 |
      | acc-2002   | st-2026-07     | Grace period,prev paid in full   |                  | 21 days       |                  |                 |
      | acc-3003   | st-2026-08     | Late payment,3 days overdue      |                  |               | 35.00            |                 |
      | acc-4004   | st-2026-09     | Rewards boundary, travel/retail  |                  |               |                  | travel:89,retail:12 |

  # Linked Bank Payment API Tests
  @api @payments
  Scenario Outline: Payment with valid, below minimum, and minimum due
    Given user is authenticated and bank_account_id "<bank_account_id>" is linked and active
    And account_id "<account_id>" has minimum_payment_due <minimum_payment_due>
    When I send a POST request to "/v2/accounts/<account_id>/payments" with payload
      """
      {
        "payment_amount": <payment_amount>,
        "payment_type": "<payment_type>",
        "bank_account_id": "<bank_account_id>"
      }
      """
    Then the response status should be <status>
    And the response body should contain <fields_or_error>

    Examples:
      | account_id | bank_account_id | minimum_payment_due | payment_amount | payment_type | status | fields_or_error                             |
      | acc-1001   | bank-001        | 50.00               | 150.00         | CUSTOM       | 200    | payment_id,scheduled_date,new_balance_estimate |
      | acc-1002   | bank-002        | 60.00               | 40.00          | CUSTOM       | 400    | error: BELOW_MINIMUM,minimum_payment_due     |

  # Regulatory - Delete account within allowed window
  @api @regulatory
  Scenario Outline: Account deletion within and after 14-day window
    Given user is authenticated and owns account_id "<account_id>" with issuance_timestamp "<issuance_timestamp>"
    When I send a DELETE request to "/v2/accounts/<account_id>"
    Then the response status should be <status>
    And the account becomes inactive/closed after successful deletion
    And no membership fee transaction is present

    Examples:
      | account_id | issuance_timestamp     | status |
      | acc-1001   | 2026-05-02T09:00:00Z  | 204    |
      | acc-2002   | 2026-04-01T10:00:00Z  | 400    |

  # Security Tests - PAN Masking, PCI Tokenisation, CSRF, Cookie Policy
  @ui @security
  Scenario: PAN masking and PCI-DSS protection in browser and DOM
    Given a user is logged in and has access to card detail and payment screens
    When I inspect the UI and DOM
    Then only masked PAN (**** **** **** 1234) is displayed
    And card input fields are served via PCI-compliant iframe tokenisation
    And no full PAN is present in DOM, JavaScript, or browser storage
    And all network transmissions use TLS 1.3

  @ui @security
  Scenario: CSRF protection and SameSite=Strict cookie policy
    Given the user is authenticated via web portal
    When I inspect session cookies using browser dev tools
    Then all session-identifying cookies are set with SameSite=Strict
    When I attempt cross-site or cross-origin requests for authenticated APIs
    Then cookies are not transmitted cross-site

  @api @security
  Scenario Outline: CSRF token requirement for state-changing endpoints
    Given user is authenticated with Bearer token "<token>", CSRF token "<csrf_token>"
    When I send a <method> request to "<endpoint>" with <csrf_header>
    Then the response status should be <status>
    And the request is accepted only with CSRF token header

    Examples:
      | token         | csrf_token    | method | endpoint                   | csrf_header          | status |
      | valid_token   | valid_csrf    | PATCH  | /v2/cards/card-001/status  | X-CSRF-Token header  | 200    |
      | valid_token   | valid_csrf    | PATCH  | /v2/cards/card-001/status  | missing              | 403    |
      | valid_token   | valid_csrf    | POST   | /v2/accounts/acc-1001/payments | X-CSRF-Token header | 200    |
      | valid_token   | valid_csrf    | POST   | /v2/accounts/acc-1001/payments | missing              | 403    |

  # Audit Trail Logging
  @audit
  Scenario Outline: Audit trail logs for credit_limit changes and card events
    Given a compliance or admin user is logged in and has access to audit endpoints
    When a PATCH request changes credit_limit or card status with reasonString "<reasonString>" for <event_type>
    Then an audit trail entry is logged with user_id, session_id, ip_address, timestamp_utc, reasonString (max 255 chars), event_type, card_id (if applicable)
    And audit entries are immutable and retrievable
    When attempting to modify or delete the audit entry
    Then the operation is forbidden

    Examples:
      | event_type         | reasonString       |
      | credit_limit       | Increased to meet customer needs |
      | card_status_change | Travel security    |
      | card_status_change | Return from trip  |
      | card_lost_report   | Left in taxi      |

  # Performance Tests
  @performance
  Scenario: API p95 latency ≤ 1500 ms under load
    Given the system is deployed to performance environment
    When I run a load test of 3,000 RPS to GET "/v2/accounts/<account_id>/summary" for 10 minutes
    Then p95 latency for all HTTP 200 responses does not exceed 1,500 ms
    And error rate does not exceed 1%
    And performance log captures the highest p95 latency

  @performance
  Scenario: API gateway sustains 5,000 concurrent requests/sec with auto-scaling
    Given cloud monitoring for CPU and auto-scaling is enabled
    When I run a load test with 5,000 concurrent RPS to GET "/v2/accounts/<account_id>/summary"
    And CPU utilization crosses 70%
    Then auto-scaling triggers and new nodes/containers are added
    And throughput is sustained with error rate ≤ 1%
    And performance logs record scaling events

  # Notification Webhook Alert Delivery, Idempotency, and Error
  @api @notification
  Scenario Outline: Notification webhook delivers LATE_PAYMENT alert to all channels
    Given all notification channels are enabled for user account "<account_id>"
    And a unique idempotency_key "<idempotency_key>" is generated
    When I send a POST request to "/v2/notifications/webhook" with payload
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
    Then the response status should be 200
    And the response body contains notification_id, delivered_at, channel
    And notification is delivered to <channel> for account

    Examples:
      | account_id | alert_type    | channel   | message_body              | severity | idempotency_key        |
      | acc-1001   | LATE_PAYMENT  | EMAIL     | Payment overdue warning   | WARNING  | notif-uuid-1234        |
      | acc-1001   | LATE_PAYMENT  | PUSH      | Payment overdue warning   | WARNING  | notif-uuid-1234        |
      | acc-1001   | LATE_PAYMENT  | IN_APP    | Payment overdue warning   | WARNING  | notif-uuid-1234        |
      | acc-1001   | LATE_PAYMENT  | SMS       | Payment overdue warning   | WARNING  | notif-uuid-1234        |

  @api @notification
  Scenario Outline: Idempotency key prevents duplicate notifications
    Given a unique idempotency_key "<idempotency_key>" is generated
    When I send two POST requests to "/v2/notifications/webhook" with identical payload and idempotency_key "<idempotency_key>"
    Then the first response status should be 200 and notification is delivered
    And the second response status should be 409 with error "DUPLICATE_NOTIFICATION"
    When I retry with a new idempotency_key
    Then the response is 200 and a new notification is delivered

    Examples:
      | idempotency_key      |
      | notif-uuid-duplicate |
      | notif-uuid-new       |

  @api @notification
  Scenario Outline: Notification error handling for unknown alert type
    Given notification system supports only defined alert_types and channels
    When I send a POST request to "/v2/notifications/webhook" with alert_type "<alert_type>" and channel "<channel>"
    Then the response status should be <status>
    And the response body contains error: INVALID_ALERT_TYPE
    And no notification is sent

    Examples:
      | alert_type      | channel   | status |
      | INVALID_TYPE    | EMAIL     | 400    |
      | LATE_PAYMENT    | UNKNOWN   | 400    |
