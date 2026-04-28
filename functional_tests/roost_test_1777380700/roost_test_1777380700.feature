Feature: Secure Card Detail Viewing Workflow

  # UI Tests
  @ui
  Scenario Outline: End-to-End Card Detail Viewing - Single and Multi-Card
    Given I am logged in with <number_of_cards> registered cards and my mobile number is updated
    And I have no session lock or max attempts reached
    When I navigate to 'Card Actions' and select 'View Card Details'
    And I <card_selection_step>
    And I proceed through the preparation screen
    And I click 'View Card Details' to trigger OTP
    And I enter OTP <otp_type> within allowed time and attempts
    Then I should see card details for <display_time> seconds, including card number, expiration date, CVV, and timer
    And action buttons are present
    And after <session_end_method>, session ends and I am returned to the card actions or dashboard

    Examples:
      | number_of_cards | card_selection_step             | otp_type      | display_time | session_end_method   |
      | 1               | select the only card            | correct OTP   | 90           | timer expiry         |
      | multiple        | select a card from the list     | correct OTP   | 90           | click 'Finish'       |

  @ui
  Scenario Outline: Negative - Error Handling for Incorrect OTP Entry
    Given I am logged in and have an eligible card for viewing
    And OTP is triggered and received via SMS
    When I enter an invalid OTP <invalid_otp_value> <attempts> time(s)
    Then I should see a clear red error message and the input field resets
    And after reaching maximum allowed attempts, a popup indicates session is locked, instructions to wait and retry are shown, and I am returned to dashboard

    Examples:
      | invalid_otp_value | attempts |
      | 123456            | 1        |
      | 000000            | 3        |
      | 999999            | 5        |

  @ui
  Scenario Outline: Alternative - User Resends OTP and Successfully Views Card Details
    Given I am logged in, card is eligible, phone is correct, and OTP was not received or expired
    When I click 'Resend OTP' by <channel> and receive new OTP
    And I enter the correct OTP within allowed timeframe
    Then I should see card details for 90 seconds
    And actionable feedback is shown for each resend attempt
    And if resend attempts exceed limit, user is locked and cannot proceed

    Examples:
      | channel      |
      | SMS          |
      | Voice        |

  @ui
  Scenario Outline: Edge Case - Viewing Card Details When No Cards are Registered or Newly Ordered is Unapproved
    Given I am logged in and have <card_state>
    When I attempt to access 'View Card Details' from main menu or after card ordering
    Then I should see <zero_state_message>
    And I am guided to <resolution_action>

    Examples:
      | card_state         | zero_state_message                      | resolution_action        |
      | no cards           | No cards found                          | order a new card        |
      | approval pending   | No details for newly ordered card       | retry after approval     |

  @ui
  Scenario: Accessibility and Privacy Compliance for Card Detail Workflow
    Given accessibility tools are enabled (screen reader, keyboard-only navigation)
    And I am logged in with an active session
    When I complete the full card detail workflow including OTP, error handling, and zero-state screens
    Then all UI elements are accessible (labeling, focus order, alt-text)
    And sensitive card data is masked/encrypted except during timer window
    And privacy warnings are displayed and session auto-ends at expiry
    And no unmasked data appears in logs or UI

  @ui
  Scenario Outline: Boundary - OTP Entry Field Validation
    Given I am logged in, eligible card selected, and OTP challenge screen presented
    When I enter OTP '<otp_input>' and press submit
    Then <validation_result> is displayed

    Examples:
      | otp_input     | validation_result            |
      | 1             | Error, rejected, input resets|
      | 12345         | Error, rejected, input resets|
      | 1234567       | Error, rejected, input resets|
      | abcdef        | Error, rejected, input resets|
      | 123456        | Accepted, proceeds to card detail|

  @ui
  Scenario Outline: Timer Expiry - Automatic Card Data Masking
    Given I have completed OTP authentication and entered the card detail screen with timer visible
    When I wait for the timer to expire with no action
    Then card detail UI is masked, session terminates, modal confirms expiry, and I am returned to safe screen
    And any back-navigation or copy actions after expiry yield masked or blank fields

    Examples:
      | timer_value |
      | 0           |
      | 1           |
      | 90          |

  @ui
  Scenario Outline: Error Modal - No Mobile Number on Record
    Given I am logged in, and have no mobile number registered
    When I attempt to trigger OTP for card detail viewing
    Then error modal appears stating 'No mobile on record'
    And further attempts are blocked until contact details are updated

    Examples:
      | api_error_code |
      | 31             |
      | 32             |

  @ui
  Scenario: Card Brand Logic - Amex Two-CVV Workflow
    Given I am logged in, have an eligible Amex card, and completed OTP authentication
    When I access 'View Card Details' for Amex
    Then two CVV fields (front and back) are shown and copy logic is enforced per brand requirements
    And timer masks data after expiry and UI transitions are smooth and compliant

  @ui
  Scenario: Session Masking - Back-Navigation After Card Viewing
    Given card detail viewing session has ended (expiry or finish)
    When I attempt to navigate back to card detail screen
    Then sensitive data (card number, CVV, expiration) is masked in UI and logs
    And clipboard or screenshots yield masked or blank fields

  @ui
  Scenario: Preparation Screen - Security, Privacy, and Timer Messaging Enforcement
    Given card is selected and I am on the preparation screen
    When I observe security/privacy warnings and timer guidance
    Then UI gating prevents bypass until I acknowledge and click 'View Card Details'
    And bypass attempts revert to previous step and show security messaging

  @ui
  Scenario Outline: Boundary - Card Number and CVV Disclosure and Masking per Brand
    Given OTP authentication complete and entered card detail screen for <brand>
    When I check card number and CVV fields
    Then card number is <card_digits> digits and CVV is <cvv_digits>, masking before/after viewing is enforced
    And copy/clipboard shows masked data outside timer window
    And Amex reveals two CVV fields as required

    Examples:
      | brand     | card_digits | cvv_digits       |
      | Visa      | 16          | 3               |
      | Mastercard| 16          | 3               |
      | Amex      | 15          | 4 (front), 3 (back)|

  @ui
  Scenario Outline: State Transition - User Blocked After Attempts Limit Exceeded
    Given I attempt to view card details and exceed <limit_type> limit for OTP <attempt_type>
    When maximum attempts are reached
    Then modal dialog blocks further actions with instructions
    And retry is disabled for <timeout_minutes> minutes
    And retry succeeds after timeout

    Examples:
      | limit_type | attempt_type | timeout_minutes |
      | send       | resend       | 10             |
      | entry      | invalid OTP  | 10             |

  @ui
  Scenario: End-to-End - Multi-Card Selection and Viewing Workflow
    Given I am logged in with multiple cards (Visa, Mastercard, Amex) registered
    When I select a card and proceed through preparation, OTP, card detail, and CVV screens
    Then timer is present, security messages enforced, and session ends securely after 'Finish'
    And UI, error handling, and masking are proper

  @ui
  Scenario: UI Gating and Button State Validation Across Card Detail Flow
    Given I progress through card selection, preparation, OTP, and card detail screens
    When I trigger a modal dialog (error or expiry) or reach timer expiry
    Then all workflow buttons (View, Copy, Finish, Resend OTP) are correctly enabled/disabled
    And during modal or expiry, actionable UI is blocked and buttons revert to disabled/hidden

  @ui
  Scenario: Combinatorial Timer Expiry with Incomplete CVV Viewing and Safe State Restoration
    Given I am viewing CVV during timer countdown in card detail screen
    When timer expires before switching back to card detail
    Then all sensitive data is masked, session ends, back-navigation displays only masked fields, and UI returns to dashboard

  @ui
  Scenario: Card List Display With Brand Images and Cardholder Name Validation
    Given I am logged in with at least two eligible cards registered
    When I navigate to card selection screen
    Then all cards display correct brand image, masked suffix, cardholder name per API response
    And only eligible cards appear and selection flows to preparation screen

  @ui
  Scenario: Card Detail Viewing - Copy-to-Clipboard Security and Masking
    Given I have accessed card details screen with timer running
    When I click 'Copy Card Number' or 'Copy CVV' during timer window
    Then clipboard contains unmasked value
    And after timer expiry or finish, clipboard is masked/cleared and logs show no sensitive data

  @ui
  Scenario Outline: Boundary Value - Cardholder Name and Card Suffix Display Length Handling
    Given cardholder name and suffix fields at boundary values
    When I view card selection screen
    Then fields display correctly for all lengths and no truncation or overflow occurs

    Examples:
      | cardholder_name                          | suffix   |
      | Al                                       | 1        |
      | Alexandria-Johnathan Maximilian Smith     | 4        |

  @ui
  Scenario: Mobile/Desktop Parity for Card Detail Viewing Workflow
    Given I am logged in on desktop and mobile web/app with eligible card
    When I complete card detail workflow on both platforms
    Then UI elements (brand image, masking, timer, modals, buttons) are consistent across platforms
    And no data persists or leaks between sessions/platforms

  @ui
  Scenario Outline: State Transition - Preparation to Card Detail Viewing with Device Context
    Given I am on the preparation screen and device is set as <device_context>
    When I attempt to proceed to card details viewing
    Then privacy guidance and UI gating are enforced per device context
    And bypass attempts block entry unless privacy warnings are acknowledged

    Examples:
      | device_context   |
      | single-user      |
      | multi-user       |

  @ui
  Scenario Outline: Preparation Screen Bypass Attempt and Security Messaging Enforcement
    Given I am on the preparation screen with eligible card
    When I attempt to bypass using <bypass_method>
    Then system blocks the bypass, privacy/security prompts are enforced, and modal warning appears

    Examples:
      | bypass_method      |
      | navigation away    |
      | reload page        |
      | URL manipulation   |
      | repeated clicks    |

  # API Tests
  @api
  Background:
    Given the API base URL is set in environment
    And authorization headers are properly configured

  @api
  Scenario Outline: API Contract for Card Selection Screen and Regulatory Compliance
    When I send a GET request to '/card-channel/web-order/card-account/cards/details' with headers:
      """
      {
        "partyAccounts.bankNumber": "<bankNumber>",
        "partyAccounts.branchNumber": "<branchNumber>",
        "partyAccounts.accountNumber": "<accountNumber>",
        "activityTypeCode": 902
      }
      """
    Then the response status should be <status>
    And the response should only include eligible cards and masked suffixes as per regulatory compliance

    Examples:
      | bankNumber | branchNumber | accountNumber | status |
      | 100        | 200          | 123456        | 200    |
      | 101        | 201          | 654321        | 200    |

  @api
  Scenario Outline: API OTP Generation, Verification, and Card Data Retrieval
    Given a selected card with required parameters
    When I send a POST request to '/api/cards/otp/generate' with payload:
      """
      {
        "cardId": "<cardId>",
        "requestType": "viewDetails"
      }
      """
    Then OTP is sent successfully and status is <generate_status>

    When I send a POST request to '/api/cards/otp/verify' with payload:
      """
      {
        "cardId": "<cardId>",
        "otp": "<otp_input>"
      }
      """
    Then OTP is <otp_result> and status is <verify_status>

    When I send a GET request to '/api/cards/<cardId>/details' with header:
      """
      {
        "Authorization": "Bearer <token>",
        "EncryptionKey": "<encryptionKey>"
      }
      """
    Then card details are retrieved, decrypted and status is <detail_status>
    And data is masked after timer expiry, with no sensitive info in cache

    Examples:
      | cardId | otp_input | generate_status | verify_status | otp_result | token        | encryptionKey | detail_status |
      | 1      | 123456    | 200             | 200           | valid      | token123     | encKeyABC     | 200           |
      | 2      | 000000    | 200             | 400           | invalid    | token456     | encKeyDEF     | 403           |

  @api
  Scenario Outline: API - Card Detail Masking Upon Timer Expiry
    Given user successfully viewed card details and timer expired
    When I send a GET request to '/api/cards/<cardId>/details'
    Then the response contains only masked fields (e.g., "****"), status is 403 or 200 with masked data

    Examples:
      | cardId | status |
      | 1      | 403    |
      | 2      | 200    |

  @api
  Scenario Outline: API - Card Brand Validation for Amex and CVV Handling
    Given card brandCode is <brandCode>
    When I send a GET request to '/api/cards/<cardId>/details'
    Then the response includes <cvvFields> and proper masking is applied per brand

    Examples:
      | cardId | brandCode | cvvFields     |
      | 3      | 3         | front, back   |
      | 1      | 1         | single        |

  @api
  Scenario Outline: API Error Handling - Backend Failure, Timeout, or Malformed Data
    When I send a <method> request to '<endpoint>' with payload:
      """
      <payload>
      """
    Then error modal is shown, UI masks all sensitive data, workflow locked until resolved, and retry is disabled

    Examples:
      | method | endpoint                                     | payload             |
      | GET    | /api/cards/<cardId>/details                  | {}                  |
      | POST   | /api/cards/otp/generate                      | {"cardId":"1"}      |
      | POST   | /card-channel/web-order/card-account/cards/details | {"account":"bad"} |

  @api
  Scenario Outline: API - Card List Boundary and New Card Approval Delay
    When I send a GET request to '/card-channel/web-order/card-account/cards/details' with header:
      """
      {
        "partyAccounts.bankNumber": "<bankNumber>",
        "partyAccounts.branchNumber": "<branchNumber>",
        "partyAccounts.accountNumber": "<accountNumber>",
        "activityTypeCode": 902
      }
      """
    Then the response contains <number_of_cards> eligible cards
    And newly issued card appears only after backend approval and delay
    And maximum boundary of card list is respected

    Examples:
      | bankNumber | branchNumber | accountNumber | number_of_cards |
      | 100        | 200          | 123456        | 0              |
      | 101        | 201          | 654321        | 5              |
      | 102        | 202          | 789012        | N              |

  @api
  Scenario Outline: API - Timer Synchronization and Masking Boundary Validation
    When card detail view timer starts at <start_time> and expires at <end_time>
    Then backend session status matches UI timer, data is masked upon expiry, and no drift occurs

    Examples:
      | start_time | end_time |
      | 0          | 90       |
      | 1          | 90       |
      | 89         | 90       |

  @api
  Scenario Outline: API - Cardholder Name and Suffix Field Length Boundaries
    When I send a GET request to '/card-channel/web-order/card-account/cards/details'
    Then cardholder name and suffix appear in response with length between <min_name_length> and <max_name_length>, <min_suffix_length> and <max_suffix_length>

    Examples:
      | min_name_length | max_name_length | min_suffix_length | max_suffix_length |
      | 2               | 40              | 1                | 4                |

  @api
  Scenario Outline: API Contract and Data Provenance Validation During Card Viewing
    When I initiate card viewing and inspect the network calls for:
      - POST '/card-channel/web-order/card-account/cards/details' with correct headers and activityTypeCode
      - POST '/api/cards/otp/generate' and '/api/cards/otp/verify' with correct parameters
      - GET '/api/cards/<cardId>/details' with authorization and encryptionKey
    Then all API contracts are validated, card data is decrypted, cache cleared after timer expiry, and logs/API responses remain masked and encrypted throughout

    Examples:
      | cardId | token        | encryptionKey |
      | 1      | token123     | encKeyABC     |
      | 2      | token456     | encKeyDEF     |

  # Negative & State-transition Tests
  @ui
  Scenario Outline: Negative Flow - OTP Resend Attempt Exceedance and Retry Disabling
    Given OTP challenge is active and resend counter is at threshold minus one
    When I click 'Resend OTP' <limit> times
    Then modal dialog is shown, resend UI is disabled, retry blocked for <timeout_minutes> minutes, modal text conforms to regulatory requirements

    Examples:
      | limit | timeout_minutes |
      | 5     | 10              |

  @ui
  Scenario Outline: State Transition - Automatic Session Ejection on OTP Expiry or Error
    Given OTP entry screen presented with code sent
    When OTP expires or I trigger error (missing phone or max attempts)
    Then system modal or error screen is shown, sensitive data is masked, session is ejected, and UI returns to dashboard or safe screen

    Examples:
      | error_type           |
      | OTP expiry           |
      | missing mobile       |
      | max attempts exceeded|

  @ui
  Scenario: End-of-Flow Completion and Safe Navigation Handoff
    Given I am viewing card details with timer visible
    When timer expires or I click 'Finish'
    Then end-of-session screen appears, sensitive data is masked, workflow cannot be reentered without restart, and user is routed to dashboard or action menu safely

