Feature: Aegis Web Portal Comprehensive Functional, API, Security, and E2E Test Scenarios

  # Background setup for API scenarios
  Background:
    Given the API base URL is "https://portal.aegiscard.com"
    And the Content-Type is "application/json"
    And the session uses valid JWT tokens when required

  # Registration and Authentication Tests

  @ui @api
  Scenario Outline: User registration with valid data (TC-AUTH-01)
    Given I am on the registration page
    When I enter "<first_name>", "<last_name>", "<email>", "<password>", "<date_of_birth>", "<phone>", "<ssn_last4>" into the registration form
    And I check the box to agree to the terms and conditions
    And I submit the registration form
    Then I should see a message confirming successful registration
    And the API should return HTTP 201 with user_id and verification_token
    And a verification email is sent to "<email>"

    Examples:
      | first_name | last_name  | email                | password              | date_of_birth | phone         | ssn_last4 |
      | Alice      | Smith      | alice.smith@test.io  | StrongPass!7Abc#      | 1995-01-22    | +14165551234  | 1234      |
      | Brian      | Williams   | brian.w@email.com    | PassWord!1234Qz#      | 1988-02-12    | +12025550111  | 9876      |

  @ui @api
  Scenario Outline: Registration fails for underage applicant (TC-AUTH-02)
    Given I am on the registration page
    When I enter valid registration details but <underage_dob> as date of birth
    And I submit the registration form
    Then I should see an error "Age must be at least 18 years"
    And the API should return HTTP 400 with error message specifying age must be >= 18
    And no verification email is sent

    Examples:
      | underage_dob |
      | 2010-03-14   |
      | 2007-08-30   |

  @ui @api
  Scenario Outline: Login with valid credentials and MFA (TC-AUTH-03)
    Given I am on the login page
    When I enter "<email>" and "<password>" and submit
    And I am prompted to enter MFA code
    And I enter a valid MFA code "<mfa_code>"
    Then I should be logged in successfully
    And the API should return HTTP 200 with access_token, refresh_token, expires_in

    Examples:
      | email                  | password           | mfa_code |
      | alice.smith@test.io    | StrongPass!7Abc#   | 123456   |
      | brian.w@email.com      | PassWord!1234Qz#   | 654321   |

  @api
  Scenario Outline: Rate limiting on login endpoint (TC-AUTH-04)
    Given valid credentials for "<email>"
    When I send POST /v2/auth/login requests <attempt_count> times within 1 minute from the same IP
    Then For attempts <= 10, API returns HTTP 200 or 401
    And For the 11th attempt, API returns HTTP 429 with error: RATE_LIMITED and 'retry_after' field

    Examples:
      | email                 | attempt_count |
      | alice.smith@test.io   | 11           |
      | brian.w@email.com     | 12           |

  @api
  Scenario Outline: Account lockout after failed login attempts (TC-AUTH-05)
    Given a user account "<email>" is registered and unlocked with MFA disabled
    When I submit 5 consecutive incorrect password logins for "<email>"
    Then Each failed attempt returns HTTP 401 with error: INVALID_CREDENTIALS
    When I attempt a 6th login (any password)
    Then API returns HTTP 403 with error: ACCOUNT_LOCKED and unlock_at

    Examples:
      | email                 |
      | alice.smith@test.io   |
      | brian.w@email.com     |

  @api
  Scenario Outline: JWT token refresh with valid refresh token (TC-AUTH-06)
    Given I have a valid, unexpired refresh_token "<refresh_token>"
    When I send POST /v2/auth/token/refresh with payload:
      """
      { "refresh_token": "<refresh_token>" }
      """
    Then API returns HTTP 200 with new access_token and refresh_token
    When I reuse the old refresh_token "<refresh_token>"
    Then API returns HTTP 400 or 401 error

    Examples:
      | refresh_token                          |
      | abcdef1234567890validtokenrefresh      |
      | uvwx987654lmnop4321validtokenrefresh   |

  # Session State and UI Timers

  @ui
  Scenario Outline: Session expiry after inactivity with warning modal (TC-AUTH-07)
    Given I am logged in and viewing the dashboard
    When I wait for 13 minutes without interaction
    Then I should see a 2-minute session expiry warning modal with countdown
    When I continue to wait until 15 minutes
    Then I should be logged out automatically, redirected to login, and session cookies are cleared

    Examples:
      | user_role |
      | customer  |
      | admin     |

  # Credit Application Flow

  @ui @api
  Scenario Outline: Initiate credit application step 1 with all required data (TC-APP-01)
    Given I am logged in and do not have an active application
    When I complete the application step 1 form with "<name>", "<email>", "<phone>", "<address>", "<id_type>", "<id_number>"
    And I submit the form
    Then API returns HTTP 201 with application_id and session_token
    And application advances to Step 2

    Examples:
      | name              | email                | phone         | address                                    | id_type          | id_number           |
      | Alice Smith       | alice.smith@test.io  | +14165551234  | 123 Main St, Toronto, ON, M5A1A1           | PASSPORT         | X123456789ABC       |
      | Brian Williams    | brian.w@email.com    | +12025550111  | 88 Bay St, Vancouver, BC, V6B 2L1           | DRIVERS_LICENSE  | DL983213123         |

  @api
  Scenario Outline: Prevent duplicate active application (TC-APP-02)
    Given I am logged in with an active (in-progress) application
    When I attempt to start a new application by POST /v2/applications/start with valid fields
    Then API returns HTTP 409 with error: DUPLICATE_APPLICATION

    Examples:
      | email                | application_status |
      | alice.smith@test.io  | ACTIVE            |
      | brian.w@email.com    | IN_PROGRESS       |

  @ui
  Scenario Outline: Auto-save application draft to localStorage (TC-APP-03)
    Given I am logged in and filling the credit application form
    When I enter data into the personal information fields and wait 60 seconds
    Then the draft data is auto-saved to localStorage
    When I update one field and wait another 60 seconds
    Then localStorage is updated with new draft
    When I refresh the browser
    Then the form restores data from localStorage and auto-save continues

    Examples:
      | user_role |
      | customer  |

  @api
  Scenario Outline: Step 2 financial submission with expired session token (TC-APP-04)
    Given Step 1 was completed and I have "<application_id>" and "<expired_token>"
    When I submit POST /v2/applications/<application_id>/financials with expired session token
    Then API returns HTTP 401 with error: SESSION_EXPIRED and no financials saved

    Examples:
      | application_id | expired_token            |
      | APPID101       | expired123tokenabc       |
      | APPID202       | oldtoken567expiredxyz    |

  @api
  Scenario Outline: Boundary test for maximum gross annual income (TC-APP-05)
    Given application_id "<application_id>" and valid session_token "<session_token>"
    When I submit gross_annual_income = <income> in POST /v2/applications/<application_id>/financials
    Then API returns <status> with <response>

    Examples:
      | application_id | session_token         | income         | status | response                             |
      | APPID101       | validtoken123         | 9999999.99     | 200    | financials accepted                   |
      | APPID101       | validtoken123         | 10000000.00    | 400    | error: "Invalid gross_annual_income"  |

  @api
  Scenario Outline: Decisioning logic for auto-approve, refer, decline (TC-APP-06)
    Given credit application in Step 3 with FICO score <fico>
    When I submit application and e_signature
    Then decision is <decision> and response fields match requirements

    Examples:
      | fico | decision     | card_number_masked       | reason_code   |
      | 700  | APPROVED     | **** **** **** 4821      |               |
      | 650  | PENDING      |                          |               |
      | 590  | DECLINED     |                          | LOW_FICO      |

  @api
  Scenario Outline: Reject credit application on missing e-signature (TC-APP-07)
    Given I am at Step 3 with "<application_id>" and "<session_token>"
    When I submit Step 3 application with "<e_signature>" as e_signature field
    Then API returns <status> with <error>

    Examples:
      | application_id | session_token  | e_signature            | status | error               |
      | APPID103       | validtoken8    |                       | 400    | SIGNATURE_REQUIRED   |
      | APPID104       | validtoken9    | invalidstring          | 400    | SIGNATURE_REQUIRED   |
      | APPID105       | validtoken10   | validbase64signature   | 200    | application accepted |

  # Transaction API Tests

  @api
  Scenario Outline: Initiate web payment with valid amount (TC-TRN-01)
    Given account_id "<account_id>", valid session, and sufficient available_credit
    When I submit POST /v2/accounts/<account_id>/transactions with
      """
      {
        "amount": <amount>,
        "currency": "<currency>",
        "merchant": "<merchant>",
        "type": "<type>"
      }
      """
    Then API returns HTTP 200 with transaction_id, available_credit, auth_code

    Examples:
      | account_id | amount   | currency | merchant        | type      |
      | ACC123     | 100.00   | CAD      | Amazon          | PURCHASE  |
      | ACC987     | 58.95    | CAD      | Air Canada      | TRAVEL    |

  @api
  Scenario Outline: Reject transaction for insufficient funds (TC-TRN-02)
    Given account_id "<account_id>" with available_credit <credit>
    When I submit transaction with amount <amount> greater than available_credit
    Then API returns HTTP 402 with error: INSUFFICIENT_FUNDS, available_credit

    Examples:
      | account_id | credit   | amount  |
      | ACC123     | 100.00   | 150.00  |
      | ACC987     | 58.95    | 99.99   |

  @api
  Scenario Outline: Essential service over-limit transaction handling (TC-TRN-03)
    Given account_id "<account_id>" and essential service MCC_code "<mcc_code>"
    When I submit transaction with amount exceeding credit limit by <=5%
    Then API returns HTTP 200 with transaction_id and over_limit_flag: true

    Examples:
      | account_id | mcc_code | amount   | credit_limit  |
      | ACC891     | 4813     | 1050.00  | 1000.00       |

  @api
  Scenario Outline: Foreign transaction fee calculation logic (TC-TRN-04)
    Given account_id "<account_id>" and available_credit in CAD
    When I submit foreign transaction with
      """
      {
        "amount": <amount>,
        "currency_code": "<currency>",
        "exchange_rate": <exchange_rate>
      }
      """
    Then API returns total_cad = (amount × exchange_rate) × 1.03, and foreign_fee_amount is itemized

    Examples:
      | account_id | amount | currency | exchange_rate |
      | ACC321     | 120.00 | USD      | 1.37          |
      | ACC654     | 100.00 | EUR      | 1.46          |

  @api
  Scenario Outline: Transaction frequency limit enforcement (TC-TRN-05)
    Given account_id "<account_id>", valid session, and 10 successful transactions posted in prior 60 minutes
    When I attempt to post the 11th transaction within the same window
    Then API returns HTTP 429 with error: FREQ_EXCEEDED, mfa_required: true

    Examples:
      | account_id |
      | ACC123     |
      | ACC987     |

  # Dashboard & Account Summary

  @api
  Scenario Outline: Get account summary as account owner (TC-DASH-01)
    Given valid account_id "<account_id>" and owner JWT token
    When I send GET /v2/accounts/<account_id>/summary
    Then API returns HTTP 200 with current_balance, available_credit, credit_limit, account_status, billing_cycle_end, points_balance

    Examples:
      | account_id |
      | ACC123     |
      | ACC987     |

  @api
  Scenario Outline: Reject summary fetch by non-owner (TC-DASH-02)
    Given account_id "<account_id>" owned by User A, and JWT token for User B
    When User B sends GET /v2/accounts/<account_id>/summary
    Then API returns HTTP 403 with error: FORBIDDEN

    Examples:
      | account_id |
      | ACC123     |
      | ACC987     |

  # Card Management (Freeze, Unfreeze, Lost/Stolen, PIN)

  @ui @api
  Scenario Outline: Freeze card with valid OTP (TC-DASH-03)
    Given I am logged in, own a card "<card_id>" in Active status, and receive OTP "<otp>"
    When I select freeze card and enter the OTP in the UI
    And I submit PATCH /v2/cards/<card_id>/status with otp "<otp>"
    Then API returns HTTP 200 with card_id and new_status="Frozen"
    And dashboard displays frozen status

    Examples:
      | card_id | otp    |
      | CARD888 | 123456 |
      | CARD777 | 654321 |

  @ui @api
  Scenario Outline: Reject freeze/unfreeze with invalid OTP (TC-DASH-04)
    Given I am logged in, own a card "<card_id>" and receive OTP "<otp>"
    When I attempt to freeze or unfreeze with invalid or expired OTP "<invalid_otp>"
    And I submit PATCH /v2/cards/<card_id>/status with OTP "<invalid_otp>"
    Then API returns HTTP 401 with error: OTP_FAILED and attempts_remaining

    Examples:
      | card_id | otp    | invalid_otp |
      | CARD888 | 123456 | 000000      |
      | CARD777 | 654321 | 999999      |

  @ui @api
  Scenario Outline: Report card lost/stolen triggers irreversible block (TC-DASH-05)
    Given I am logged in, not previously blocked, and own card "<card_id>"
    When I report lost/stolen with loss_type "<loss_type>" and last_known_use "<last_known_use>"
    And I submit POST /v2/cards/<card_id>/report-lost
    Then API returns HTTP 200 with blocked_card_id, new_card_eta, case_number
    And dashboard displays Blocked status, and further status changes are forbidden

    Examples:
      | card_id  | loss_type | last_known_use         |
      | CARD888  | LOST      | 2024-05-01T13:00:00Z   |
      | CARD777  | STOLEN    | 2024-06-12T23:48:00Z   |

  @ui @api
  Scenario Outline: Set new card PIN and validation (TC-DASH-06)
    Given I am logged in, own card "<card_id>" not blocked, and have valid OTP "<otp>"
    When I enter two matching 4-digit PINs "<pin1>" and "<pin2>", and OTP "<otp>" in the UI
    And I submit PUT /v2/cards/<card_id>/pin with payload:
      """
      { "pin": "<pin1>", "confirm_pin": "<pin2>", "otp": "<otp>" }
      """
    Then API returns HTTP 200 with success: true and updated_at timestamp
    And no plaintext PIN is exposed in UI/logs

    Examples:
      | card_id | pin1  | pin2  | otp    |
      | CARD888 | 1234  | 1234  | 123456 |
      | CARD777 | 8901  | 8901  | 654321 |

  # Billing & Payment

  @api
  Scenario Outline: Retrieve statement in PDF and JSON formats (TC-BILL-01)
    Given I am logged in and have access to account_id "<account_id>" and statement_id "<statement_id>"
    When I request statement in format "<format>" via GET /v2/accounts/<account_id>/statements/<statement_id>?format=<format>
    Then I receive file containing statement_date, total_spend, adb, interest_charged, late_fee, rewards_earned, minimum_payment_due, due_date

    Examples:
      | account_id | statement_id | format |
      | ACC123     | STMT202405   | JSON   |
      | ACC123     | STMT202405   | PDF    |

  @api
  Scenario Outline: Apply interest calculation using ADB method (TC-BILL-02)
    Given account_id "<account_id>" has statement_id "<statement_id>" where interest is applicable
    When I retrieve statement and note ADB <adb>, APR <apr>, days_in_cycle <days>
    Then interest_charged = (adb × apr / 365) × days and matches manually computed value

    Examples:
      | account_id | statement_id | adb      | apr   | days |
      | ACC123     | STMT202405   | 2500.00  | 0.229 | 30   |

  @api
  Scenario Outline: Test grace period enforcement logic (TC-BILL-03)
    Given prior statement_balance_paid_in_full = <paid_in_full> for account_id "<account_id>"
    When I retrieve the current statement
    Then grace period indicator reflects <grace_period_applied> and interest accrual is correct

    Examples:
      | account_id | paid_in_full | grace_period_applied |
      | ACC123     | true         | YES                  |
      | ACC123     | false        | NO                   |

  @api
  Scenario Outline: Late fee trigger when payment is overdue (TC-BILL-04)
    Given statement due_date "<due_date>" for account_id "<account_id>"
    When payment is received on "<received_date>"
    Then late_fee is <fee_applied> per business rules

    Examples:
      | account_id | due_date    | received_date      | fee_applied |
      | ACC123     | 2024-05-15  | 2024-05-15        | $0.00       |
      | ACC123     | 2024-05-15  | 2024-05-17        | $0.00       |
      | ACC123     | 2024-05-15  | 2024-05-18        | $35.00      |

  @api
  Scenario Outline: Rewards accrual for travel MCC and other categories (TC-BILL-05)
    Given account_id "<account_id>" with posted transaction MCC "<mcc_code>" and amount <amount>
    When I retrieve the statement after cycle end
    Then rewards_earned = floor(<amount> × <reward_multiplier>)

    Examples:
      | account_id | mcc_code | amount  | reward_multiplier |
      | ACC123     | 3000     | 200.00  | 3                |
      | ACC123     | 5411     | 150.00  | 1                |

  @api
  Scenario Outline: Submit payment with exact minimum payment amount (TC-BILL-06)
    Given account_id "<account_id>", statement minimum_payment_due "<min_payment>"
    When I submit payment with amount "<min_payment>" and payment_type "MINIMUM"
    Then API returns HTTP 200 with payment_id and new_balance_estimate; no error

    Examples:
      | account_id | min_payment |
      | ACC123     | 75.20      |
      | ACC987     | 112.00     |

  # Security, Compliance, and Notification Tests

  @ui @api @security
  Scenario Outline: PAN masking in browser display (TC-SEC-01)
    Given I am logged in as cardholder of "<card_id>"
    When I open dashboard and view card details
    Then PAN is displayed as masked (**** **** **** <last4>)
    And API never returns full PAN in any response or page source

    Examples:
      | card_id  | last4 |
      | CARD123  | 4821  |
      | CARD987  | 3319  |

  @ui @api @security
  Scenario Outline: Right to rescind account within 14 days (TC-SEC-02)
    Given account_id "<account_id>" is <days_since_issuance> days old
    When I attempt to DELETE /v2/accounts/<account_id>
    Then If <days_since_issuance> <= 14, API returns HTTP 200; otherwise, error and endpoint unavailable

    Examples:
      | account_id | days_since_issuance |
      | ACC123     | 10                  |
      | ACC987     | 15                  |

  @ui @security
  Scenario: TLS 1.3 enforced for all web forms (TC-SEC-03)
    Given I launch browser and access "https://portal.aegiscard.com"
    When I inspect network protocol for all form submissions and authentication
    Then All connections use TLS 1.3 and any downgrade is prevented

  @api @security
  Scenario Outline: Audit trail on credit limit change (TC-SEC-04)
    Given I have account_id "<account_id>" and request credit_limit change to <new_limit>
    When I submit API POST/PATCH to update credit_limit with OTP "<otp>"
    Then audit trail records user_id, session_id, ip_address, timestamp_utc
    And log entry is immutable

    Examples:
      | account_id | new_limit | otp    |
      | ACC123     | 8000.00   | 111111 |
      | ACC123     | 12000.00  | 222222 |

  @api @security
  Scenario Outline: CSRF token requirement for all state-changing endpoints (TC-SEC-05)
    Given I am authenticated and initiate action "<endpoint>" (state-changing)
    When I submit request with valid CSRF token in X-CSRF-Token header
    Then API returns HTTP 200
    When I submit request without or with invalid CSRF token
    Then API returns HTTP 401 or proper error and action is rejected

    Examples:
      | endpoint                        |
      | /v2/accounts/ACC123/payments    |
      | /v2/cards/CARD123/status        |

  # Notification Engine

  @api
  Scenario Outline: Notification delivery via email, SMS, in-app, push (TC-NOTIF-01)
    Given account_id "<account_id>", all notification channels enabled
    When I trigger event "<event>" causing alert_type "<alert_type>" delivery
    Then notification is delivered to in-app UI, email, SMS, push with correct formatting and severity

    Examples:
      | account_id | event             | alert_type             |
      | ACC123     | payment_submitted | PAYMENT_POSTED         |
      | ACC123     | card_frozen       | CARD_FROZEN            |
      | ACC123     | statement_ready   | STATEMENT_READY        |

  @api
  Scenario Outline: Reject unknown alert type or channel (TC-NOTIF-02)
    Given POST /v2/notifications/webhook with invalid alert_type "<alert_type>" or invalid channel "<channel>"
    When I submit the payload with idempotency_key "<key>"
    Then API returns HTTP 400 with error: INVALID_ALERT_TYPE and no notification is queued

    Examples:
      | alert_type   | channel           | key                                 |
      | ALIEN_HACK   | CARRIER_PIGEON    | fffe0011-9988-7766-6655-5544332211  |
      | TEST_INVALID | BEEP              | 99889977-8866-5511-2233-4422110055  |

  @api
  Scenario Outline: Prevent duplicate notifications with idempotency key (TC-NOTIF-03)
    Given I submit notification webhook twice with same idempotency_key "<key>"
    When first submission succeeds, second returns error
    Then API returns HTTP 409 with error: DUPLICATE_NOTIFICATION, only one delivery occurs

    Examples:
      | account_id | alert_type        | channel | key                               |
      | ACC123     | STATEMENT_READY   | EMAIL   | ccdd0010-2222-3333-4444-5555666655|

  # E2E Workflows and SPA-specific features

  @e2e
  Scenario Outline: Full user journey: registration to statement to payment (TC-E2E-01)
    Given I visit registration page for a new account
    When I fill registration, receive verification email, log in, complete credit application steps, select card, access dashboard, initiate payment, and review statement
    Then All workflow steps succeed; session, notifications, state transitions, and business rules all validated end-to-end

    Examples:
      | first_name | last_name  | email                | password              | mfa_code | id_type         | id_number         |
      | Alice      | Smith      | alice.smith@test.io  | StrongPass!7Abc#      | 123456   | PASSPORT        | X123456789ABC     |

  @e2e
  Scenario Outline: End-to-end credit card application and approval (TC-E2E-02)
    Given I am a registered, email-verified user
    When I complete 3-step application (personal info, financials, card selection), with session_token gating and auto-save drafts
    And FICO score is 720
    Then Application is approved, masked card number is shown, and completed state is displayed

    Examples:
      | email                | fico_score | id_type      | e_signature            |
      | alice.smith@test.io  | 720        | PASSPORT     | validbase64signature   |

  @e2e
  Scenario Outline: Session expires during credit application step (TC-E2E-03)
    Given I complete Step 1 and have application_id "<application_id>" and session_token "<session_token>"
    When session_token expires (>30 min elapsed)
    And I attempt Step 2 submission
    Then API returns error: SESSION_EXPIRED and UI prompts for session restart

    Examples:
      | application_id | session_token              |
      | APPID108      | expiredtoken9081           |

  @ui
  Scenario: Real-time transaction feed on dashboard (TC-E2E-04)
    Given I am logged in and viewing dashboard
    When I observe transaction stream via WebSocket endpoint
    Then New transactions appear live, auto-reconnect functions, only masked PAN is shown

  @ui
  Scenario: Session timeout modal in SPA with auto-logout (TC-E2E-05)
    Given I am logged into SPA with valid JWT in HttpOnly cookie
    When I am inactive for 13 minutes
    Then Session expiry warning modal is displayed for 2 minutes, and at 15 minutes I am logged out automatically with cookies cleared

