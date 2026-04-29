Feature: Credit Portal User, Authentication, Card, and Transaction Functional and Security Workflows

  # Background setup shared for API scenarios
  Background:
    Given the API base URL is "https://api.creditportal.com/v2"
    And the Accept header is "application/json"

  # Registration API Tests
  @api @registration
  Scenario Outline: User registration with valid data triggers email verification
    Given there is no pre-existing user with email <email>
    When I send a POST request to "/auth/register" with payload:
      """
      {
        "first_name": "<first_name>",
        "last_name": "<last_name>",
        "email": "<email>",
        "password": "<password>",
        "date_of_birth": "<date_of_birth>",
        "phone_number": "<phone_number>",
        "ssn_last4": "<ssn_last4>",
        "agree_terms": true
      }
      """
    Then the response status should be 201
    And the response should include "user_id" and "verification_token"
    And a verification email is sent to <email>

    Examples:
      | first_name | last_name | email                  | password               | date_of_birth | phone_number   | ssn_last4 |
      | John       | Smith     | john.smith@test.com    | S3curePassw0rd!@#      | 1985-01-01    | +14165551234   | 1234      |
      | Erica      | Lewis     | erica.lewis@test.com   | ComPlexPass123$        | 1990-06-15    | +18215557654   | 5678      |

  @api @registration @negative
  Scenario Outline: Registration fails with missing required fields
    Given there is no pre-existing user with email <email>
    When I send a POST request to "/auth/register" with payload:
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
    Then the response status should be 400
    And the response should contain a field-specific error message for <missing_field>
    And no user account is created
    And no verification email is sent

    Examples:
      | first_name | last_name | email               | password        | date_of_birth | phone_number | ssn_last4 | agree_terms | missing_field        |
      |            | Turner    | a.turner@test.com   | P@ssword12!     | 1992-09-02    | +14165551279 | 9999      | true        | first_name          |
      | Amy        |           | amy.r@test.com      | Passw0rd!$      | 1988-04-16    | +12225553456 | 1234      | true        | last_name           |
      | Mike       | Rowe      |                    | SecurePwd!11    | 1979-11-23    | +14165559999 | 9876      | true        | email               |
      | Alan       | Shaw      | alan.shaw@test.com  |                 | 1980-02-10    | +14165559876 | 1234      | true        | password            |
      | Lena       | Blake     | lena.blake@test.com | TestPwd12$$     |                | +14165559999 | 4321      | true        | date_of_birth       |
      | Sara       | James     | sara.james@test.com | Qwerty!123      | 1995-07-22    | +14165556789 | 7432      | false       | agree_terms         |

  # Login/Account Lockout API Tests
  @api @login @state-transition
  Scenario Outline: Login fails after 5 incorrect attempts, triggers account lock
    Given user "<email>" exists, account status is unlocked, and credentials are set
    When I attempt login with incorrect password "<wrong_password>" 5 times via POST "/auth/login"
    Then the response status for the fifth attempt should be 403
    And the response should include error "ACCOUNT_LOCKED" and "unlock_at" timestamp
    When I attempt a 6th login with incorrect password "<wrong_password>"
    Then the response status should be 403
    And the account remains locked
    When I attempt login with correct password "<correct_password>"
    Then the response status should be 403
    And access is denied until unlock_at
    And audit logs record the lockout event

    Examples:
      | email               | correct_password    | wrong_password    |
      | locked.user@test.com| Correct$Pass123     | Wrong!Pass777     |

  # Refresh Token Security API Tests
  @api @token @security
  Scenario Outline: Refresh token can be used only once, otherwise returns invalid
    Given user "<email>" is authenticated and has valid access_token and refresh_token
    When I send a POST request to "/auth/token/refresh" with payload:
      """
      {
        "refresh_token": "<refresh_token>"
      }
      """
    Then the response status should be 200
    And new access_token and refresh_token are returned
    When I send a POST request to "/auth/token/refresh" using the same invalidated "<refresh_token>"
    Then the response status should be 401
    And error should be "TOKEN_INVALID"
    And no new tokens are issued
    And audit logs record token replay attempt

    Examples:
      | email                   | refresh_token          |
      | tokenuser@test.com      | abcdefgh1234567890     |

  # Credit Application API Tests
  @api @application
  Scenario Outline: Start credit application with valid personal details
    Given user "<email>" is authenticated and email verified with no active application
    When I send a POST request to "/applications" with payload:
      """
      {
        "full_legal_name": "<full_legal_name>",
        "email": "<email>",
        "phone_number": "<phone_number>",
        "address": {
          "street": "<street>",
          "city": "<city>",
          "province": "<province>",
          "postal_code": "<postal_code>"
        },
        "id_type": "<id_type>",
        "id_number": "<id_number>"
      }
      """
    Then the response status should be 201
    And the response should include "application_id" and "session_token"

    Examples:
      | full_legal_name   | email                | phone_number  | street           | city    | province | postal_code | id_type         | id_number         |
      | Rachel Yu        | rachel.yu@test.com   | +14165551212  | 123 Main St      | Toronto | ON       | M6G1A1      | DRIVERS_LICENSE | ABCD123456        |

  @api @application @negative
  Scenario Outline: Prevent duplicate credit application for active user
    Given user "<email>" is authenticated and has active application in IN_PROGRESS status
    When I send a POST request to "/applications" with payload:
      """
      {
        "full_legal_name": "<full_legal_name>",
        "email": "<email>",
        "phone_number": "<phone_number>",
        "address": {
          "street": "<street>",
          "city": "<city>",
          "province": "<province>",
          "postal_code": "<postal_code>"
        },
        "id_type": "<id_type>",
        "id_number": "<id_number>"
      }
      """
    Then the response status should be 409
    And the response should include error "DUPLICATE_APPLICATION"
    And no new application or session_token is created

    Examples:
      | full_legal_name   | email                | phone_number  | street           | city    | province | postal_code | id_type         | id_number         |
      | Rachel Yu        | rachel.yu@test.com   | +14165551212  | 123 Main St      | Toronto | ON       | M6G1A1      | DRIVERS_LICENSE | ABCD123456        |

  @api @application
  Scenario Outline: Submit financial information triggers soft credit pull
    Given user "<email>" has valid session_token "<session_token>" and active application_id "<application_id>"
    When I send a POST request to "/applications/<application_id>/financial" with payload:
      """
      {
        "employment_status": "<employment_status>",
        "employer_name": "<employer_name>",
        "gross_annual_income": <gross_annual_income>,
        "monthly_rent": <monthly_rent>,
        "existing_debt_payments": <existing_debt_payments>,
        "sin_consent": true
      }
      """
      And the header "session_token" is set to "<session_token>"
    Then the response status should be 200
    And the response should include status "PENDING_REVIEW" and "fico_pull_id"
    And a soft credit pull is triggered

    Examples:
      | email                | session_token           | application_id | employment_status | employer_name | gross_annual_income | monthly_rent | existing_debt_payments |
      | rachel.yu@test.com   | tokentest9876543210     | app123456      | EMPLOYED         | Acme Corp     | 70000              | 1500         | 300                    |

  @api @application @security
  Scenario Outline: Session token expiry error on financial submission
    Given user "<email>" has application_id "<application_id>", and session_token "<session_token>" is expired or missing
    When I send a POST request to "/applications/<application_id>/financial" with payload:
      """
      {
        "employment_status": "<employment_status>",
        "employer_name": "<employer_name>",
        "gross_annual_income": <gross_annual_income>,
        "monthly_rent": <monthly_rent>,
        "existing_debt_payments": <existing_debt_payments>,
        "sin_consent": true
      }
      """
      And the header "session_token" is <token_option>
    Then the response status should be 401
    And the response should contain error "SESSION_EXPIRED"
    And no financial data is stored
    And no credit pull is triggered

    Examples:
      | email                | application_id | employment_status | employer_name | gross_annual_income | monthly_rent | existing_debt_payments | session_token           | token_option    |
      | rachel.yu@test.com   | app123456      | EMPLOYED         | Acme Corp     | 70000              | 1500         | 300                    | tokentest9876543210     | expired         |
      | rachel.yu@test.com   | app123456      | EMPLOYED         | Acme Corp     | 70000              | 1500         | 300                    |                        | missing         |
      | rachel.yu@test.com   | app123456      | EMPLOYED         | Acme Corp     | 70000              | 1500         | 300                    | invalidtok001           | invalid         |

  @api @application @state-transition
  Scenario Outline: Decision logic: approved, pending, declined based on FICO
    Given user "<email>" has completed Step 1 and Step 2 with valid session_token "<session_token>", application_id "<application_id>"
    And FICO score for application is stubbed to <fico_score>
    When I send a POST request to "/applications/<application_id>/decision" with payload:
      """
      {
        "card_product_id": "<card_product_id>",
        "e_signature": "<e_signature>",
        "marketing_opt_in": <marketing_opt_in>
      }
      """
    Then the response status should be 200
    And the application state is <decision>
    And the returned payload contains <expected_field>
    And further submissions are not permitted

    Examples:
      | email                | session_token       | application_id | fico_score | card_product_id | e_signature | marketing_opt_in | decision  | expected_field                  |
      | rachel.yu@test.com   | tokentest9876543210 | app123456      | 750        | prod1001        | sig123      | false           | APPROVED  | credit_limit, card_number_masked|
      | rachel.yu@test.com   | tokentest9876543210 | app123456      | 650        | prod1001        | sig123      | true            | PENDING   | review_eta_hours                |
      | rachel.yu@test.com   | tokentest9876543210 | app123456      | 599        | prod1001        | sig123      | false           | DECLINED  | reason_code                     |

  # Transaction API Tests
  @api @transaction
  Scenario Outline: Initiate web payment with valid amount and merchant details
    Given user "<email>" owns active account "<account_id>" with sufficient available credit
    When I send a POST request to "/transactions" with payload:
      """
      {
        "account_id": "<account_id>",
        "transaction_amount": <transaction_amount>,
        "merchant_name": "<merchant_name>",
        "merchant_id": "<merchant_id>",
        "mcc_code": "<mcc_code>",
        "currency_code": "<currency_code>",
        "transaction_type": "<transaction_type>",
        "description": "<description>"
      }
      """
    Then the response status should be 200
    And the response includes "transaction_id", "updated_available_credit", "auth_code"
    And transaction appears in history
    And "over_limit_flag" is only set if essential buffer used

    Examples:
      | email               | account_id | transaction_amount | merchant_name     | merchant_id | mcc_code | currency_code | transaction_type | description           |
      | pay.user@test.com   | acc10001   | 50.00             | Amazon Web Sales  | AWM3300     | 5411     | CAD           | PURCHASE        | Book purchase         |

  @api @transaction @negative
  Scenario Outline: Reject web payment with negative or zero amount
    Given user "<email>" owns active account "<account_id>" with available credit
    When I send a POST request to "/transactions" with payload:
      """
      {
        "account_id": "<account_id>",
        "transaction_amount": <transaction_amount>,
        "merchant_name": "<merchant_name>",
        "merchant_id": "<merchant_id>",
        "mcc_code": "<mcc_code>",
        "currency_code": "CAD",
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should be 422
    And the response contains error "INVALID_AMOUNT"
    And no transaction is created or posted
    And audit log records the rejection
    And account balance/statement is unchanged

    Examples:
      | email               | account_id | transaction_amount | merchant_name | merchant_id | mcc_code |
      | pay.user@test.com   | acc10001   | 0.00              | Walmart       | WAL123      | 5411     |
      | pay.user@test.com   | acc10001   | -100.00           | BestBuy       | BBY789      | 5732     |

  @api @transaction @boundary
  Scenario Outline: Foreign currency payment applies fee and conversion formula
    Given user "<email>" owns active account "<account_id>" with sufficient available credit
    When I send a POST request to "/transactions" with payload:
      """
      {
        "account_id": "<account_id>",
        "transaction_amount": <transaction_amount>,
        "merchant_name": "<merchant_name>",
        "merchant_id": "<merchant_id>",
        "mcc_code": "<mcc_code>",
        "currency_code": "<currency_code>",
        "exchange_rate": <exchange_rate>,
        "transaction_type": "PURCHASE"
      }
      """
    Then the response status should be 200
    And the response includes "cad_total" calculated as (<transaction_amount> × <exchange_rate>) × 1.03
    And "foreign_fee_amount" is itemized in details
    And available credit is updated correctly
    And transaction history and statement display fee and converted total separately

    Examples:
      | email               | account_id | transaction_amount | merchant_name | merchant_id | mcc_code | currency_code | exchange_rate |
      | pay.user@test.com   | acc10001   | 100.00            | eBay US       | EBAY2022    | 5940     | USD           | 1.36         |

  # Card State & Dashboard API Tests
  @api @card @freeze
  Scenario Outline: Freeze card with OTP verification and audit log
    Given user "<email>" owns card with status "Active"
    When I send a POST request to "/cards/<card_id>/freeze" with payload:
      """
      {
        "otp_code": "<otp_code>",
        "freeze_reason": "<freeze_reason>"
      }
      """
    Then if OTP is valid, card status changes to "Frozen"
    And response contains confirmation modal with new_status "Frozen"
    And audit log contains user_id, session_id, ip_address, timestamp
    But if OTP is invalid, response contains error "OTP_FAILED"
    And maximum retries are enforced
    And freeze reason is recorded
    When I attempt to freeze again, response contains error "INVALID_TRANSITION"
    And further freeze denied until unfreeze

    Examples:
      | email               | card_id  | otp_code | freeze_reason |
      | freeze.user@test.com| card8901 | 123456   | travel        |
      | freeze.user@test.com| card8901 | 654321   | suspicious    |

  # Lost Card/Replacement API Tests
  @api @card @block @e2e
  Scenario Outline: Report lost card triggers block and replacement workflow
    Given user "<email>" owns card with status "Active"
    When I send a POST request to "/cards/<card_id>/report_lost" with payload:
      """
      {
        "loss_type": "<loss_type>",
        "last_known_use": "<last_known_use>",
        "delivery_address": "<delivery_address>"
      }
      """
    Then card status is "Blocked"
    And all pending/future transactions are denied with error "CARD_BLOCKED"
    And response includes "new_card_eta", "case_number", "blocked_card_id"
    And fraud team is notified
    And notification sent to cardholder

    Examples:
      | email                | card_id   | loss_type | last_known_use       | delivery_address      |
      | blockcard@test.com   | card7766  | LOST      | 2024-06-18T16:22:00Z| 123 Main St, Toronto  |

  # PAN Security Masking API Tests
  @api @card @security
  Scenario Outline: PAN is always masked in browser, never transmitted full
    Given user "<email>" owns at least one card
    When I request GET "/cards/<card_id>" or view transaction/statement exported data
    Then the API response, downloadable documents, and audit logs only expose masked PAN ("**** **** **** <last4>")
    And the browser DOM, session storage and network requests do not contain full PAN
    And attempted access to full PAN is refused with error or masked/tokenized substitute

    Examples:
      | email             | card_id  | last4 |
      | maskuser@test.com | card9901 | 2471  |

  # UI Integration scenarios (for key workflows impacting API)
  @ui @registration
  Scenario Outline: Registration form validates input and displays errors for missing fields
    Given I am on the registration page
    When I fill "<first_name>" in first_name field
    And I fill "<last_name>" in last_name field
    And I fill "<email>" in email field
    And I fill "<password>" in password field
    And I fill "<date_of_birth>" in date_of_birth
    And I fill "<phone_number>" in phone_number field
    And I fill "<ssn_last4>" in ssn_last4 field
    And I <agree_action> for terms and conditions
    And I click "Submit"
    Then I should see error message "<expected_error>"

    Examples:
      | first_name | last_name | email              | password     | date_of_birth | phone_number | ssn_last4 | agree_action       | expected_error            |
      |            | Lee       | test@abc.com       | Passw0rd!    | 1995-05-12    | +14165551212 | 1234      | check_terms        | "First name required"     |
      | Anna       |           | atest@abc.com      | Passw0rd!    | 1995-05-12    | +14165551212 | 1234      | check_terms        | "Last name required"      |
      | Bob        | Carter    |                    | Passw0rd!    | 1995-05-12    | +14165551212 | 1234      | check_terms        | "Email required"          |
      | Dana       | Green     | dana@abc.com       |              | 1995-05-12    | +14165551212 | 1234      | check_terms        | "Password required"       |
      | Ethan      | Wood      | ethan@abc.com      | Passw0rd!    |               | +14165551212 | 1234      | check_terms        | "Date of birth required"  |
      | Fiona      | Hall      | fiona@abc.com      | Passw0rd!    | 1995-05-12    | +14165551212 |           | check_terms        | "SSN last 4 required"     |
      | George     | Brown     | george@abc.com     | Passw0rd!    | 1995-05-12    | +14165551212 | 1234      | do_not_check_terms | "You must agree to terms" |

  @ui @security
  Scenario Outline: Card details and transaction history displays masked PAN only
    Given I am logged in as user "<email>"
    And I am on "<page>" page
    When I view card display section
    Then I should see PAN in masked format ("**** **** **** <last4>")
    When I open transaction history
    Then I should see all PAN references masked
    When I download a statement
    Then downloaded document contains masked PAN only

    Examples:
      | email             | page         | last4 |
      | maskuser@test.com | Account      | 2471  |
      | maskuser@test.com | Transactions | 2471  |
