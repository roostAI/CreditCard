Feature: Aegis Credit Card Portal - API and UI Functional, Security, Boundary, Audit, Performance, and E2E Tests

  # API Tests
  Background:
    Given the API base URL is 'https://api.aegiscard.com'
    And the system is accessible via HTTPS with valid authentication and CSRF token as required

  @api
  Scenario Outline: User Registration - Happy Path and Validation Boundaries
    Given no account exists for email '<email>'
    When I send a POST request to '/v2/auth/register' with payload
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
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | email                    | first_name | last_name | password           | date_of_birth | phone_number     | ssn_last4 | agree_terms | status | result             | additional_checks                                                       |
      | test+1001@example.com    | Jane       | Doe       | Aa1!bcdefghij      | 2001-04-10    | +14165550101     | 1234      | true        | 201    | user_id, verification_token | Email verification triggered, fields valid, email unique                   |
      | test+1002@example.com    | Jane       | Doe       | Aa1!bcdefghij      | 2002-05-19    | +14165550101     | 1234      | true        | 409    | EMAIL_EXISTS          | No duplicate account, email verification not triggered                      |
      | test+1003@example.com    | Jane       | Doe       | Aa1!bcdefghij      | 2001-06-01    | +14165550101     | 1234      | true        | 201    | user_id, verification_token | Registration accepted with minimum password complexity                      |
      | test+1003@example.com    | Jane       | Doe       | Aa1bcdefghij       | 2001-06-01    | +14165550101     | 1234      | true        | 422    | WEAK_PASSWORD         | Registration rejected for missing symbol                                   |
      | test+1003@example.com    | Jane       | Doe       | AA1!bcdefghij      | 2001-06-01    | +14165550101     | 1234      | true        | 422    | WEAK_PASSWORD         | Registration rejected for missing lower case                               |
      | test+1003@example.com    | Jane       | Doe       | aa1!bcdefghij      | 2001-06-01    | +14165550101     | 1234      | true        | 422    | WEAK_PASSWORD         | Registration rejected for missing upper case                               |
      | test+1003@example.com    | Jane       | Doe       | Aa1!bcdefghi       | 2001-06-01    | +14165550101     | 1234      | true        | 422    | WEAK_PASSWORD         | Registration rejected for too short password                               |

  @api
  Scenario Outline: Login with MFA, Failures, Lockout, and Session Controls
    Given a registered user '<email>' with MFA setting '<mfa_enabled>' and known password '<correct_password>'
    When I send a POST request to '/v2/auth/login' with payload
      """
      {
        "email": "<email>",
        "password": "<password>",
        "mfa_code": "<mfa_code>",
        "device_id": "<device_id>",
        "remember_me": <remember_me>
      }
      """
    Then the response status should be <status>
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | email                 | mfa_enabled | correct_password    | password            | mfa_code | device_id                  | remember_me | status | result                  | additional_checks                                                        |
      | test+1004@example.com | true        | TestPassword#2024   | TestPassword#2024   | 123456   | c1530944-7c88-4120-ba33-cd0e350792fc | false      | 200    | access_token, refresh_token, expires_in | MFA must be correct, token TTL = 15 min unless remember_me true         |
      | test+1005@example.com | false       | TestPassword#2024   | WrongPass001        | ""       | ""                         | false      | 401    | INVALID_CREDENTIALS     | Lockout after five attempts, 6th returns ACCOUNT_LOCKED                  |
      | test+1005@example.com | false       | TestPassword#2024   | TestPassword#2024   | ""       | ""                         | false      | 403    | ACCOUNT_LOCKED, unlock_at| Login only possible after unlock_at timestamp                            |
      | test+1006@example.com | false       | TestPassword#2024   | WrongPassword2024   | ""       | ""                         | false      | 401    | INVALID_CREDENTIALS     | One failed attempt does not lock account                                 |

  @api
  Scenario Outline: Token Refresh and Session Invalidation
    Given user '<email>' with valid 'refresh_token'
    When I send a POST request to '/v2/auth/token/refresh' with payload
      """
      {
        "refresh_token": "<refresh_token>"
      }
      """
    Then the response status should be <status>
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | email                 | refresh_token                    | status | result                  | additional_checks                                      |
      | test+1007@example.com | abcdef1234567890refresh          | 200    | access_token, refresh_token | Old refresh token cannot be reused, session continuity |
      | test+1007@example.com | abcdef1234567890refresh          | 401    | TOKEN_INVALID            | Old token is invalidated, can’t be reused              |

  @api
  Scenario Outline: Logout Invalidates Session Tokens
    Given user '<email>' is logged in with valid access_token and refresh_token
    When I send a request to '/v2/auth/logout' endpoint
    Then the response status should be <status>
    And session tokens are immediately invalidated
    And API calls using old tokens are rejected

    Examples:
      | email                 | status |
      | test+1008@example.com | 200    |

  @api
  Scenario Outline: Credit Application Step 1 - Happy Path, Duplicate, and Sequential Step Enforcement
    Given authenticated user '<email>' with valid session
    When I send a POST request to '/v2/applications/start' with payload
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
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | email                  | full_legal_name | phone_number     | street         | city    | province | postal_code | id_type           | id_number      | status | result                  | additional_checks                                                                       |
      | test+1009@example.com  | Jane Doe        | +14165550102     | 987 Test Ave   | Toronto | ON       | M1B 2W3     | DRIVERS_LICENSE   | DL12345678     | 201    | application_id, session_token | New application progresses to Step 2, session_token usable for next steps                |
      | test+1010@example.com  | John Smith      | +14165550103     | 455 Main St    | Toronto | ON       | M2N 7E2     | DRIVERS_LICENSE   | DL87654321     | 409    | DUPLICATE_APPLICATION      | No new application, existing workflow unchanged, system rejects duplicate                |

  @api
  Scenario Outline: Submit Financials - Field Validation, Session Token Expiry, Out-of-Order Steps
    Given application_id '<application_id>' and session_token '<session_token>' are available for Step 2
    When I send a POST request to '/v2/applications/<application_id>/financials' with payload
      """
      {
        "employment_status": "<employment_status>",
        "employer_name": "<employer_name>",
        "gross_annual_income": <gross_annual_income>,
        "other_income": <other_income>,
        "monthly_rent": <monthly_rent>,
        "existing_debt_payments": <existing_debt_payments>,
        "sin_consent": <sin_consent>
      }
      """
    And I set the 'X-App-Session' header to '<session_token>'
    Then the response status should be <status>
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | application_id | session_token                  | employment_status | employer_name         | gross_annual_income | other_income | monthly_rent | existing_debt_payments | sin_consent | status | result                | additional_checks                                                          |
      | app-valid-01   | sess-valid-01                  | EMPLOYED         | Aegis Test Inc.       | 85000.00           | 5000.00      | 1800.00      | 300.00                 | true        | 200    | status:PENDING_REVIEW, fico_pull_id | Credit pull initiated, all data valid                                   |
      | app-valid-01   | sess-valid-01                  | EMPLOYED         |                      | 85000.00           | 5000.00      | 1800.00      | 300.00                 | true        | 400    | FIELD_VALIDATION_ERROR | Error for missing required field (employer_name)                         |
      | app-valid-01   | sess-expired-01                | EMPLOYED         | Aegis Test Inc.       | 85000.00           | 5000.00      | 1800.00      | 300.00                 | true        | 401    | SESSION_EXPIRED      | No credit pull, session expired, no data updated                          |

  @api
  Scenario Outline: Application Step 3 - Approval, Decline, Signature Errors, Idempotency
    Given session_token '<session_token>' and application_id '<application_id>' for Step 3
    When I send a POST request to '/v2/applications/<application_id>/submit' with payload
      """
      {
        "card_product_id": "<card_product_id>",
        "e_signature": "<e_signature>",
        "marketing_opt_in": <marketing_opt_in>
      }
      """
    And I set the 'X-App-Session' header to '<session_token>'
    Then the response status should be <status>
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | application_id  | session_token   | card_product_id | e_signature          | marketing_opt_in | status | result                         | additional_checks                                                                         |
      | app-approve-01  | sess-valid-01   | AEGIS_GOLD      | dGVzdHNpZ25hdHVyZQ== | false            | 200    | decision:APPROVED, credit_limit, card_number_masked | FICO > 680 score, card_number_masked format, no full PAN exposed                        |
      | app-decline-01  | sess-valid-01   | AEGIS_GOLD      | dGVzdHNpZ25hdHVyZQ== | false            | 200    | decision:DECLINED, reason_code              | FICO < 600, no approval info present, boundary test repeated with FICO=599              |
      | app-nosign-01   | sess-valid-01   | AEGIS_GOLD      |                      | false            | 400    | SIGNATURE_REQUIRED               | No decision, approval or decline, signature missing/invalid                             |

  @api
  Scenario Outline: Enforce Sequential Application Step Order
    Given application_id '<application_id>' and session_token '<session_token>' in incomplete state
    When I attempt to perform application step '<step>' out of order
    Then the response status should be <status>
    And the error should be '<error>'
    And only valid sequential flows are accepted

    Examples:
      | application_id | session_token   | step      | status | error                 |
      | dummy-id-01    | sess-invalid-01 | financials| 400    | STEP_PRECONDITION     |
      | app-valid-01   | sess-valid-01   | submit    | 400    | STEP_PRECONDITION     |
      | app-valid-01   | sess-valid-01   | financials| 200    |                       |

  # UI Tests (Autosave Draft, Masked PAN, TLS/DOM, Session Modal)
  @ui
  Scenario Outline: Autosave Drafts During Application
    Given I am logged in to the portal and on the '<step>' application form
    When I partially fill the form and wait '<wait_seconds>' seconds
    Then localStorage should contain a draft object for '<form_type>'
    And only allowed (non-sensitive) fields are stored
    When I reload the page or close and reopen the browser
    Then the form restores from the saved draft for '<form_type>'
    And sensitive fields (PAN, full SSN) are never present

    Examples:
      | step    | wait_seconds | form_type    |
      | Step 1  | 60           | application  |
      | Step 2  | 60           | financials   |

  @ui
  Scenario Outline: Masked PAN Display in Browser UI and DOM
    Given I am logged in as cardholder and viewing my card details page
    When the card data is fetched via GET '/v2/cards/<card_id>/details'
    Then I should see card number displayed as '<masked_pan>' in the UI and DOM
    And the full PAN must not be found anywhere in DOM, localStorage, or JS console

    Examples:
      | card_id      | masked_pan             |
      | card-4242    | **** **** **** 1234    |

  @ui
  Scenario Outline: TLS 1.3 and PCI Iframe Tokenisation on Web Forms
    Given I access the registration or payment form on portal
    When I submit card data via the browser
    And I inspect the network request and browser security panel
    Then the connection is secured with TLS 1.3
    And card fields are rendered via PCI-compliant iframe tokenisation
    And no raw PAN is seen in outbound requests or page source

    Examples:
      | form        | card_input_field        |
      | registration| stripe_iframe           |
      | payment     | stripe_iframe           |

  @ui
  Scenario Outline: Session Timeout Warning Modal Shown 2 Minutes Prior
    Given I am logged in to the portal with a session idle for '<idle_minutes>' minutes
    When I view the dashboard UI
    Then a session timeout warning modal is visible
    And modal displays '<message>'
    And user can choose to extend the session

    Examples:
      | idle_minutes | message                              |
      | 13           | Session expires in 2 minutes.         |

  # API Tests - Transaction Processing, Fee, Query, Security
  @api
  Scenario Outline: Web Payment Transaction Processing (Standard/Essential/Over-limit/Decline/Frequency/Foreign Fee/Query)
    Given authenticated user '<email>' and account_id '<account_id>' with available_credit <available_credit>
    When I send a POST request to '/v2/accounts/<account_id>/transactions' with payload
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
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | email                      | account_id        | available_credit | transaction_amount | merchant_name      | merchant_id | mcc_code | currency_code | exchange_rate | transaction_type | status | result                       | additional_checks                                                               |
      | test+pay01@example.com     | acc-001           | 5000.00         | 200.00            | WebPay Test        | TST10001    | 5999     | CAD          | 1.0           | PURCHASE       | 200    | transaction_id, available_credit, auth_code | Available credit updated, transaction in history, ISO 8583: 00        |
      | test+paybuf01@example.com  | acc-essbuf01      | 1000.00         | 1050.00           | Wireless Util      | UTIL1002    | 4814     | CAD          | 1.0           | PURCHASE       | 200    | transaction_id, over_limit_flag:true        | Essential service, over-limit buffer, available_credit zero/negative   |
      | test+decline01@example.com | acc-002           | 100.00          | 150.00            | Online Shop        | SHOP2231    | 5732     | CAD          | 1.0           | PURCHASE       | 402    | INSUFFICIENT_FUNDS, available_credit        | No new transaction or history, error as required, retry shows same outcome |
      | test+freqcap04@example.com | acc-003           | 2000.00         | 10.00             | TestShop           | TEST123     | 5999     | CAD          | 1.0           | PURCHASE       | 200    | transaction_id                    | First 10 transactions succeed, 11th triggers FREQ_EXCEEDED + mfa_required |
      | test+freqcap04@example.com | acc-003           | 2000.00         | 10.00             | TestShop           | TEST123     | 5999     | CAD          | 1.0           | PURCHASE       | 429    | FREQ_EXCEEDED, mfa_required:true | No transaction_id, audit log shows rate-limit breach                      |
      | test+fee01@example.com     | acc-fee01         | 3000.00         | 100.00            | IntlStore          | US123       | 5311     | USD          | 1.35          | PURCHASE       | 200    | total_cad:139.05, foreign_fee_amount:4.05 | Itemized fee, available_credit debited by 139.05, no fee for CAD       |
      | test+feeitem02@example.com | acc-eur01         | 5000.00         | 200.00            | EuroShop           | EURO123     | 5411     | EUR          | 1.50          | PURCHASE       | 200    | total_cad:309.00, foreign_fee_amount:9.00 | Fee itemization for EUR, absent for CAD, fee transparent                |

  @api
  Scenario Outline: List Transactions for Billing Cycle Dates, Forbidden Access
    Given user '<email>' and account_id '<account_id>' for transaction history query
    When I send a GET request to '/v2/accounts/<account_id>/transactions' with query params from_date='<from_date>', to_date='<to_date>', page=1, per_page=25
    Then the response status should be <status>
    And transaction[] array matches date range (>= from_date, <= to_date)
    And page, total_count, total_pages fields are correct
    And <additional_checks>

    Examples:
      | email                     | account_id         | from_date   | to_date    | status | additional_checks                                     |
      | test+cyclequery01@example.com | acc-ttrans01      | 2026-02-01  | 2026-02-28 | 200    | transactions only in date range, category field present                  |
      | test+unauth02@example.com | acc-ttrans02       | 2026-02-01  | 2026-02-28 | 403    | No transaction[] returned, error: FORBIDDEN, audit trail includes attempt|

  @api
  Scenario Outline: Retrieve Account Summary and Conditional Rewards / Access Control
    Given user '<email>' and account_id '<account_id>' for summary retrieval
    When I send a GET request to '/v2/accounts/<account_id>/summary' with include_rewards='<include_rewards>'
    Then the response status should be <status>
    And the response should <rewards_expectation>
    And <additional_checks>

    Examples:
      | email                    | account_id | include_rewards | status | rewards_expectation      | additional_checks                           |
      | test+dash01@example.com  | acc-dash01 | false           | 200    | not contain points_balance| Other summary fields present                |
      | test+dash01@example.com  | acc-dash01 | true            | 200    | contain points_balance   | points_balance matches rewards, no leakage   |
      | test+dashsec02@example.com| acc-dash02 | false           | 403    | not contain points_balance| No summary fields, error: FORBIDDEN         |

  @api
  Scenario Outline: Freeze Card with Valid OTP / Invalid Transition / Lost Card / Already Blocked
    Given user '<email>', card_id '<card_id>', and valid confirm_otp '<confirm_otp>'
    When I send a PATCH request to '/v2/cards/<card_id>/status' with payload
      """
      {
        "status": "<status_value>",
        "confirm_otp": "<confirm_otp>",
        "reason": "<reason>"
      }
      """
    Then the response status should be <status_code>
    And the response or log contains '<result>'
    And <additional_checks>

    Examples:
      | email                       | card_id      | confirm_otp | status_value | reason                 | status_code | result              | additional_checks                                    |
      | test+freeze01@example.com   | card-8724    | 872435      | Frozen       | Travel abroad for security. | 200        | card_id, new_status:Frozen, updated_at | Cards cannot transact while frozen, audit log present        |
      | test+cardstneg02@example.com| card-5127    | 872435      | Blocked      | Routine test           | 400        | INVALID_TRANSITION, allowed_transitions | Only Active/Frozen allowed, card status unchanged           |

  @api
  Scenario Outline: Report Lost Card and Trigger Re-Issue / Already Blocked Errors
    Given user '<email>' owns card_id '<card_id>' in status '<status_value>'
    When I send POST request to '/v2/cards/<card_id>/report-lost' with payload
      """
      {
        "loss_type": "<loss_type>",
        "last_known_use": "<last_known_use>"
      }
      """
    Then the response status should be <status_code>
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | email                      | card_id      | status_value | loss_type | last_known_use                | status_code | result                  | additional_checks                                           |
      | test+lost01@example.com    | card-8834    | Active       | LOST      | 2026-03-20T12:00:00Z          | 200         | blocked_card_id, new_card_eta, case_number | Card status: Blocked, replacement scheduled                |
      | test+lost01@example.com    | card-8834    | Blocked      | LOST      | 2026-03-14T17:12:00Z          | 409         | ALREADY_BLOCKED         | No new card, audit log not created for duplicate report     |

  @api
  Scenario Outline: PIN Set and Mismatch Validation
    Given user '<email>' is authenticated and card_id '<card_id>' is active
    When I send PUT request to '/v2/cards/<card_id>/pin' with payload
      """
      {
        "new_pin": "<new_pin>",
        "confirm_pin": "<confirm_pin>",
        "session_otp": "<session_otp>"
      }
      """
    Then the response status should be <status_code>
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | email                    | card_id      | new_pin | confirm_pin | session_otp | status_code | result                | additional_checks                                  |
      | test+pin01@example.com   | card-7242    | 1234    | 1234        | 384620      | 200         | success:true, updated_at | Transmission encrypted, no PIN in logs/DOM          |
      | test+pinneg02@example.com| card-5128    | 5312    | 1245        | 461027      | 400         | PIN_MISMATCH           | No PIN update, no audit log for pin update          |

  @api
  Scenario Outline: Retrieve Statement in JSON / Not Found Error
    Given user '<email>' and account_id '<account_id>' and statement_id '<statement_id>'
    When I send GET request to '/v2/accounts/<account_id>/statements/<statement_id>?format=JSON'
    Then the response status should be <status_code>
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | email                    | account_id           | statement_id                    | status_code | result    | additional_checks                                           |
      | test+stmt01@example.com  | ACC-447a3c88-xxxx    | STMT-908d8a3b-xxxx-xxxx         | 200         | statement_date, total_spend, adb, interest_charged, late_fee, rewards_earned, minimum_payment_due, due_date | No sensitive info, statement sum matches transaction totals |
      | test+stmt02@example.com  | ACC-17fda7c2-xxxx    | STMT-01020304-xxxx-xxxx         | 404         | NOT_FOUND | No statement data, no info leak                            |

  @api
  Scenario Outline: Billing Statement Calculations (Interest, Grace Period, Late Fee, Rewards Rounding)
    Given user '<email>', account_id '<account_id>', billing cycle, and payment timing
    When I retrieve statement or submit payment as per billing cycle rules
    Then the response status should be <status_code>
    And the response contains '<result>'
    And <additional_checks>

    Examples:
      | email                    | account_id         | cycle_length | creation_date | apr     | adb     | payment_date        | status_code | result          | additional_checks                                           |
      | test+bill01@example.com  | ACC-8c899a3e-xxxx | 30           | 2026-03-01    | 19.99   | 1500.00 | NA                  | 200         | interest_charged:24.65 | Matches ADB formula, ±$0.01 tolerance, correct fields         |
      | test+bill02@example.com  | ACC-2e33a51d-xxxx | 30           | 2026-03-01    | 19.99   | 1500.00 | NA                  | 200         | grace_period:21 days, due_date | Provided if prev_statement_paid=true; branch for false        |
      | test+bill03@example.com  | ACC-77bc545b-xxxx | 30           | 2026-03-01    | 19.99   | 1500.00 | 2026-04-02          | 200         | late_fee:35.00    | Applied only if payment > due_date+2, alert LATE_PAYMENT sent |
      | test+bill04@example.com  | ACC-8172b2c6-xxxx | 30           | 2026-03-01    | 19.99   | 1500.00 | NA                  | 200         | rewards_earned:347 | Rewards floor rounded (travel MCC: 99.75×3=299; non-travel:48.99×1=48) |

  @api
  Scenario Outline: Payment Submission Minimum, Below Minimum Due Error
    Given user '<email>' and account_id '<account_id>', minimum_payment_due '<min_due>'
    When I send a POST request to '/v2/accounts/<account_id>/payments' with payload
      """
      {
        "payment_amount": <payment_amount>,
        "payment_type": "<payment_type>",
        "bank_account_id": "<bank_account_id>"
      }
      """
    Then the response status should be <status_code>
    And the response should contain '<result>'
    And <additional_checks>

    Examples:
      | email                      | account_id       | payment_amount | payment_type | bank_account_id      | min_due | status_code | result                | additional_checks                                  |
      | test+pay01@example.com     | ACC-8ae4c29e-xxxx| 1.00           | CUSTOM       | BA-5447ed2f-xxxx-xxxx| 1.00 | 200         | payment_id, scheduled_date, new_balance_estimate | Payment accepted for minimum of $1.00               |
      | test+pay01@example.com     | ACC-8ae4c29e-xxxx| 0.99           | CUSTOM       | BA-5447ed2f-xxxx-xxxx| 1.00 | 400         | BELOW_MINIMUM         | Payment rejected below $1.00                        |
      | test+pay02@example.com     | test-account-002 | 100.00         | CUSTOM       | test-bank-003        | 125.00 | 400         | BELOW_MINIMUM, minimum_payment_due:125.00 | Payment rejected below min due; $125.00 boundary accepted|

  # Security, Audit, Resilience, Performance Tests
  @api
  Scenario Outline: PAN Masking Enforcement, Audit Logs Privacy, CSRF/SameSite, Session Expiry/Timeout, Notification Idempotency
    Given system is running with secure cookie, logging, and notification facilities
    When I perform '<action>' as '<role>' on '<endpoint>' with or without required tokens and sensitive values
    Then the response status should be <status_code>
    And the response/log contains '<result>'
    And <security_checks>

    Examples:
      | action                      | role        | endpoint                                | status_code | result                      | security_checks                                   |
      | view_card_details           | cardholder  | /v2/cards/{card_id}/details             | 200         | masked_pan                  | full PAN never appears, PCI compliance enforced    |
      | change_credit_limit         | admin       | /v2/accounts/{account_id}/credit_limit  | 200         | audit_log:user_id, session_id, ip_address, timestamp_utc | No PAN/SSN in log, immutability asserted           |
      | state_changing_no_csrf      | user        | PATCH/POST endpoints                    | 403         | CSRF_REQUIRED               | Without X-CSRF-Token header, actions rejected      |
      | access_summary_other_account | user        | /v2/accounts/{account_id}/summary       | 403         | FORBIDDEN                   | No fields exposed, audit trail records access      |
      | cross_origin_cookie         | user        | session cookie inspection               | 200         | SameSite=Strict, Secure, HttpOnly | Cookies not sent on cross-origin request           |
      | session_expiry              | user        | session valid 15 min inactivity         | 401         | SESSION_EXPIRED             | Session cookie purged, must re-authenticate        |
      | duplicate_notification      | system      | /v2/notifications/webhook               | 409         | DUPLICATE_NOTIFICATION      | Only one alert per idempotency_key/account/channel |
      | performance_api_latency     | loadtool    | /v2/accounts/{account_id}/summary       | 200         | latency_p95<=1500ms         | SLA met, error rate within tolerance               |

  @api
  Scenario Outline: Audit Trail for Card Status and Re-Issue Events
    Given authenticated user '<email>' and card_id '<card_id>' for audit testing
    When I change card status or report lost for '<card_id>' with reason '<reason>'
    Then an audit log entry is created with user_id, session_id, ip_address, timestamp_utc, and reason (≤255 chars)
    And the entry is immutable and retrievable
    And no PAN/SSN appears in log

    Examples:
      | email                     | card_id      | reason                                 |
      | test+auditcard01@example.com | card-8241    | Travel abroad for security.            |
      | test+auditcard01@example.com | card-8241    | Back from vacation.                    |
      | test+auditcard01@example.com | card-8241    | Card misplaced at airport.             |

  # E2E Full User Journey Scenario
  @e2e
  Scenario: Full User Journey from Registration to Account Closure
    Given no prior user with email 'test+e2e01@example.com'
    When I register a new user via API with valid details
    And complete email verification workflow
    And initiate and submit a multi-step credit application (personal info, financials, e-signature)
    And receive auto-approval with masked card number and credit_limit
    And activate card and set PIN via API
    And make a successful purchase transaction, receive notifications via IN_APP and EMAIL
    And retrieve billing statement for cycle, reconciling transactions
    And submit payment for statement balance
    And perform account closure within allowed window via DELETE endpoint
    Then each stage returns correct responses, triggers notifications and audit logs, and account is closed with session invalidated
