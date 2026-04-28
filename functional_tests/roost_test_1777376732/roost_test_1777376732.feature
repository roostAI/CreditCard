gherkin
Feature: Credit Card Details Viewing and Security Workflow

  # UI and API Integration Tests: Secure credit card details viewing, error handling, session management, timer enforcement, and regulatory compliance.

  Background:
    Given the user is authenticated and audit logging is enabled

  # Positive, End-to-End: Credit Card Details Viewing - MasterCard Brand Workflow
  @ui @api @e2e
  Scenario Outline: Successful card details viewing for MasterCard with multi-card account and timer enforcement
    Given the user has at least two eligible cards available and one is a MasterCard
    When the user navigates to the main menu and selects "View credit card details"
    And the card list is presented with multiple cards, including a MasterCard
    And the user selects the '<cardBrand>' card and consent is given in the pre-view security modal showing privacy warning and timer info
    And the user requests OTP via '<otpChannel>' and enters a valid OTP
    And the encrypted payload is retrieved, decrypted, and card details screen is displayed showing masked card number, expiry, CVV, brand icon, and timer (90 seconds)
    And the user clicks the copy icon for masked data
    And the timer expires
    Then only masked PII is shown, session is terminated, audit event is recorded, and the user is returned to main menu or closure screen
    And MasterCard display elements are correct

    Examples:
      | cardBrand   | otpChannel |
      | MasterCard  | SMS        |
      | MasterCard  | Voice      |

  # Negative: Zero-State Handling - No Eligible Cards (HTTP 204/ID=31)
  @ui @api @negative
  Scenario: Zero-state workflow handling for no eligible cards and card issuance guidance
    Given the user has no eligible cards registered
    When the user launches "View credit card details" from the main menu
    And the backend returns HTTP 204 with ID=31
    Then the UI shows zero-state message "No cards found for your account"
    And the user clicks "Order new card" and is navigated to the card issuance workflow
    When the user repeats the workflow from post-card-issuance lobby
    And the backend returns HTTP 203 with ID=31
    Then the UI displays "New card details not available"
    And clicking "Try again" re-attempts but error persists
    And session remains secure and cleared; audit trail records attempts and user intent

  # Security/Negative: OTP Authentication Handling - Failed Attempts, Lockout, Recovery (SMS & Voice)
  @ui @api @negative @security
  Scenario Outline: OTP input failures with lockout modal and recovery for dual-channel OTP
    Given the user proceeds to OTP input with both SMS and voice numbers available
    When the user requests OTP via '<channel>'
    And enters incorrect OTP '<otp>' up to the maximum allowed attempts '<maxAttempts>'
    Then a lockout modal with ID=32 is displayed with timer (10 minutes) and guidance
    And audit record for lockout event is generated
    When the user attempts to restart process within lockout
    Then process is rejected and UI guidance shown
    When the timer expires
    And the user retries and requests OTP via '<alternateChannel>'
    And enters valid OTP
    Then access is granted and lockout guidance is cleared
    And all actions are audited; UI disables OTP input box during lockout

    Examples:
      | channel | alternateChannel | otp   | maxAttempts |
      | SMS     | Voice           | 12345 | 5           |
      | Voice   | SMS             | 54321 | 5           |

  # Integration/Boundary: Brand-Specific Display - American Express with Dual CVV & Timer
  @ui @api @boundary @integration
  Scenario: Amex card details display - dual CVV, masking, timer enforcement
    Given the user has an American Express card with two CVVs and PCI DSS config enabled
    When the user selects Amex card and consents via pre-view confirmation modal
    And requests and enters a valid OTP
    And receives encrypted payload with session-bound decryption
    Then UI displays masked card number, expiry, primary CVV, and brand icon; timer starts (90 seconds)
    And clicking 'View CVV' reveals second (back) CVV for Amex
    And both CVVs are masked appropriately with PCI DSS
    And copy action is tested for each CVV and masking persists to clipboard
    When 'Back to card details' is clicked, UI reverses to main details
    When timer expires, confirm session termination and return to closure screen
    And audit events are generated for every view and copy action

  # UI/Error: No Mobile Number – Error Modal, Audit, Guidance
  @ui @negative
  Scenario: Handling missing phone number for OTP generation
    Given the user account lacks mobile number and backend returns HTTP 203 with ID=31 for OTP request
    When the user progresses through card selection and triggers OTP generation
    Then error modal appears with regulatory guidance to update phone and warning of process abort
    And clicking 'Close' terminates session and UI returns to main menu
    And audit log records phone error and navigation
    When re-accessing "View credit card details", error persists until phone is updated

  # Boundary/Negative: Session Timeout During Card Data Viewing
  @ui @api @boundary
  Scenario: Timer expiry enforces session termination and disables UI interactions
    Given timer is set to 90 seconds during card data viewing
    When the user withholds actions and timer hits zero
    Then UI disables all sensitive actions, error modal/guidance appears, card fields become masked
    When the user attempts interaction (copy, view CVV, refresh) after timer expiry
    Then repeat access is blocked until new initiation; audit log records timeout and closure

  # Integration/State Transition: Return to Home from Card Selection
  @ui @integration
  Scenario: Navigation fidelity and session management when aborting from card selection screen
    Given user is at card selection screen with eligible cards
    When the user clicks 'Return to home'
    Then redirection to home/credit card dashboard occurs and session is cleared
    When user re-accesses "View credit card details"
    Then session and state are reset, no stale data remains, workflow is fresh
    And audit record reflects abort and navigation; no prior card data or state persists

  # Boundary/Positive: Multi-Card Account with Brand-Specific UI Elements
  @ui @boundary
  Scenario Outline: Card list fetch and brand-specific UI fidelity on multi-card accounts
    Given user has at least three eligible cards of different brands
    When the user launches "View credit card details" from main menu
    Then UI shows '<cardBrand>' with brand image and privacy context message
    When selecting '<cardBrand>', and reading contextual messaging
    And using back navigation switches card selection as per cache without re-fetching
    And clicking 'Return to home' aborts workflow
    Then audit log details card selection, navigation reversal, abort events

    Examples:
      | cardBrand   |
      | MasterCard  |
      | Visa        |
      | Isracard    |

  # Negative/State Transition: OTP Resend via Voice - Backend Failover, UI Error, and Recovery
  @ui @api @negative @integration
  Scenario Outline: OTP resend failover to voice, error handling, and retry logic
    Given user is at OTP input screen with valid phone
    When user clicks "Resend OTP via Voice"
    And backend simulates failure to deliver OTP via '<channel>'
    Then UI presents error modal with guidance copy regarding channel failure
    When switching back to alternate channel '<alternateChannel>'
    Then UI limits resend by attempt count
    When retrying after lockout timer (10 minutes) and entering OTP via alternate channel
    Then state persists and channel switch is honored; audit log tracks attempts

    Examples:
      | channel | alternateChannel |
      | Voice   | SMS             |
      | SMS     | Voice           |

  # Security/Boundary: PCI DSS Masking - Card Data Display and Copy Actions
  @ui @security @boundary
  Scenario: PCI DSS masking enforcement for card details and copy actions
    Given user progresses to card details screen for any brand
    When card number, CVV, expiry are presented
    Then all fields are partially masked per PCI DSS rules, never expose full PII
    When user clicks "Copy details"
    Then clipboard data contains only masked content
    When attempting to unmask CVV or after session error/abort
    Then masking persists post-error; audit logs record every copy/view action; no sensitive data exposed

  # Negative/Boundary: Pre-View Confirmation Modal – Abort and Session Clearance
  @ui @negative @boundary
  Scenario: Abort workflow in pre-view confirmation modal
    Given the user has arrived at pre-view confirmation modal after card selection
    When user clicks 'Back'
    Then UI redirects to card selection or home, session is cleared
    When re-entering 'View credit card details', state is cleared, no sensitive fields visible
    Then audit log records abort action, navigation, and compliance

  # Boundary/Integration: Card Data Display – Session-Bound Decryption for Isracard
  @ui @api @integration @boundary
  Scenario: Isracard-specific card data viewing with session-bound decryption and PCI DSS masking
    Given user selects Isracard and passes pre-view confirmation modal
    When a valid OTP is entered, encrypted card payload is retrieved and session-bound decryption key obtained
    Then masked card number, expiry, CVV, brand image, cardholder name are displayed and timer starts (90 seconds)
    When copy icon is clicked for card number/CVV, clipboard is inspected for masking
    When navigation is attempted during timer, session persists; timer expiry terminates session
    Then audit log records all viewing/copy actions; PCI DSS masking honored throughout

  # UI/Boundary: OTP Input Validation – Numerics Only, Field Focus, Clearing, Attempt Counting
  @ui @boundary
  Scenario Outline: OTP textbox accepts only numerics, rejects invalid, counts attempts, manages focus
    Given user is at OTP authentication screen after card selection
    When the user enters '<inputType>' in the OTP box
    Then UI only accepts numerics, rejects alphanumerics, incomplete codes are not accepted
    When entering incorrect numeric OTP, error modal is triggered, box clears and refocuses
    When attempts reach '<maxAttempts>' for lockout, input disables
    When interacting post-lockout, input box stays disabled
    Then audit log records every entry, error, and lockout action

    Examples:
      | inputType     | maxAttempts |
      | alphanumeric  | 5           |
      | incomplete    | 5           |
      | valid numeric | 5           |
      | incorrect     | 5           |

  # Integration/Edge Case: HTTP Error Handling – ID=32 on Card Fetch
  @ui @api @integration @edge
  Scenario: Error handling for card fetch ID=32 from post-issuance lobby
    Given workflow is initiated from post-issuance lobby with a new cardId
    When backend responds with HTTP 203 and ID=32
    Then UI displays regulatory modal with guidance to retry or order new card
    When user clicks 'Try again', repeat, and error persists
    And clicking 'Home' clears session and redirects
    Then re-entry from main menu shows state reset, audit log details modal, abort, navigation events

  # Positive/State Transition: Explicit Logout after Card Viewing - Session and Audit Enforcement
  @ui @api @positive @state
  Scenario: Logout terminates session, disables repeat access, and records audit
    Given user has viewed card details after authentication and timer is active
    When the user clicks "Logout" during or after details exposure
    Then backend session is terminated and UI requires re-authentication for any repeated access
    Then audit log covers logout, session closure, and card viewing history

  # Positive/Edge: Viewing Card Details After New Card Issuance – Delayed Appearance Logic
  @ui @api @positive @edge
  Scenario: New card appears in selection list only after backend approval (delayed appearance)
    Given user has just completed card order, card approval pending
    When backend returns HTTP 203 with ID=31 on card fetch
    Then UI displays "Try again later" delay message, prevents selection
    When retrying flow after <delayTime> minutes and card status is approved
    Then new card is visible; brand image matches; UI enables selection and pre-view confirmation modal
    Then audit log records retry and new card reveal events

    Examples:
      | delayTime |
      | 1         |

  # Boundary/Negative: Viewing Max Cards Per Account (Boundary Value)
  @ui @api @boundary @negative
  Scenario: UI and backend handle account with max allowed cards (e.g. 10), no overflow
    Given user has account with 10 eligible cards of various brands
    When system fetches card list
    Then UI renders max cards only, overflow (11th card) is blocked/not shown
    When selecting first, middle, and last cards, and navigating among them
    Then masking, cache, and audit logs are checked; 'Return to home' after viewing 3 cards ensures no leakage or stale states

  # Integration/Negative: Encrypted Payload Retrieval Failure - Error Modal, Session Abort
  @ui @api @integration @negative
  Scenario: Failure during encrypted card data retrieval triggers error modal and session abort
    Given user completes authentication and requests encrypted payload post-OTP
    When backend returns error (HTTP 500 or error code)
    Then UI displays error modal "Card details unavailable, try again later", session is aborted, modal timeout enforced
    When 'Close' is clicked, user is redirected to home
    When retrying from main menu, normal workflow resumes
    Then audit log records error, abort, and retry events; no partial data exposed

  # Positive/Boundary: Card Data Display - Minimum Field Boundary & Audit Logging
  @ui @boundary @positive
  Scenario: Minimum field values handled with masking and audit compliance
    Given user selects card with minimum field values (short expiry, single CVV, shortest name)
    When pre-view modal is confirmed, OTP is entered
    Then card details screen displays correct masking of short card number/CVV/expiry; timer disables actions after 90 seconds
    When copying details to clipboard, masking persists
    Then audit log records viewing and copying actions; UI is regulatory compliant

  # UI/Positive: Dual-Channel OTP Display and SMS/Voice Toggle
  @ui @positive
  Scenario: Dual-channel OTP toggle, masked phone display, and UI feedback
    Given user proceeds to OTP authentication screen with SMS/Voice toggle enabled and both phone channels
    When masked phone is displayed
    Then user clicks 'Send code via SMS', receives UI feedback
    When user clicks 'Send code via Voice', toggle feedback, timer, and guidance shown
    When attempt limit is reached on one channel and switches channel
    Then toggling allowed within attempt limits, audit log records each toggle, send, and entry event
    And regulatory guidance/copy is present; session honors channel switch rules

  # UI/Positive: Pre-View Confirmation Modal – Security Guidance & Timer
  @ui @positive
  Scenario: Modal displays security warning, timer (90s), visuals, consent logic before OTP
    Given user initiates 'View credit card details' workflow and selects eligible card
    When pre-view confirmation modal loads (Sc0004)
    Then privacy warning, timer, and icons are present; guidance to not copy/view with others; visuals load
    When 'Back' is clicked, navigation reverses to card selection, no retention
    When modal is re-entered and 'Proceed' is clicked, flow advances to OTP
    Then audit log records both actions; consent is enforced

  # Integration/Negative: Card Selection - Zero-State Handling for Non-Bank Cards
  @ui @integration @negative
  Scenario: Zero-state workflow for only non-bank cards present
    Given user account contains only non-bank cards
    When launching 'View credit card details' fetch returns solely non-bank cards
    Then UI displays zero-state message 'No eligible bank cards found', guidance to order a new card
    When 'Order new card' is clicked, verify navigation to issuance workflow
    When re-accessing before new card is issued, zero-state persists
    Then audit log records error encounter and navigation

  # UI/Boundary: Copy to Clipboard Handling Post-Timer Expiry
  @ui @boundary
  Scenario: Copy action disabled after session timeout; error modal and audit
    Given card details screen is visible with timer active
    When timer expires (90 seconds), user attempts 'Copy card details' or 'Copy CVV'
    Then UI feedback/modal displays guidance; clipboard is only masked/empty; audit log records invalid attempt and session expiry

  # Integration/Positive: Preventing Multiple Concurrent Credit Card Viewing Sessions
  @api @ui @integration @positive
  Scenario: Dual-session device validation enforces one session per device
    Given user starts credit card details viewing session in one browser/tab/device
    When opening a second browser/tab/device and attempts new session
    Then error modal states session already active; only one session allowed
    When timer expires on first session and retry is attempted
    Then UI updates, session state changes, session can be newly initiated
    Then audit log tracks concurrent access attempts, session expiry, navigation

  # Negative/Edge: OTP Expiration and Validation – Error Handling and Session State
  @ui @api @negative @edge
  Scenario: Handling expired OTP entry; disable input and abort session
    Given OTP validity window is expired
    When user enters expired OTP
    Then error modal displayed, input is cleared and disabled; guidance to restart process
    When modal is closed, workflow aborts to home/menu
    When immediate restart is attempted, audit log records expired code, error modal, abort, and re-initiation

  # Boundary/Negative: OTP Generation Attempt Limit – Modal, Lockout, Audit
  @ui @api @boundary @negative
  Scenario Outline: Max OTP generation attempts enforced with lockout modal and regulatory guidance
    Given user is at OTP generation screen and backend allows a maximum of '<maxAttempts>' requests
    When requesting OTP via SMS up to '<maxAttempts>' times
    When attempting a '<nthAttempt>' OTP generation (exceeds max)
    Then backend responds with HTTP 203 ID=32; UI displays error modal about excessive requests, disables resend/cancel actions
    When 'Close' is clicked, user is sent to main menu
    Then audit log records each OTP request, error modal, workflow abort

    Examples:
      | maxAttempts | nthAttempt |
      | 3           | 4          |

  # Positive/State Transition: Card Details Viewing via Lobby Completion – Workflow Recovery, Audit
  @ui @integration @positive @state
  Scenario: Recovery from zero-state after card issuance; timer, masking, audit for entry/exit
    Given user completes card order and remains in post-issuance lobby
    When 'View credit card details' is initiated and zero-state is presented
    When 'Try again' is clicked after status update, card appears in list
    When card is selected, pre-view modal confirmed, OTP entered
    Then card details, timer, masking, regulatory text shown; 'Finish' ends session
    When re-entering via lobby, session is reset, closure screen shows compliance
    Then audit logs detail every action and state transition

  # Security/Integration: Session-Bound Encryption Key Mis-match – Error Handling
  @ui @api @security @integration
  Scenario: Handling decryption failure due to session-bound key mismatch
    Given system requests encrypted card data with session key post-OTP authentication
    When backend returns mismatched key/error
    Then UI presents compliant error modal, disables sensitive actions, session is aborted
    When 'Close' or navigation is attempted, user is redirected to home/dashboard
    When workflow is restarted, normal operation resumes
    Then audit log records encryption failure, modal display, session abort, navigation recovery; no card data exposed

  # UI/Positive: Cardholder Name Field – Min/Max Length Boundary and Masking/Overflow Handling
  @ui @positive @boundary
  Scenario Outline: Cardholder name rendering at boundary values; masking, copy, UI visual, error handling, and audit
    Given cards with <nameLength> cardholder names are available
    When user selects card and reviews name field
    Then UI displays name correctly with masking, handles overflow/truncation gracefully
    When copying name to clipboard, masking remains enforced
    When triggering error flow (session timeout, navigation reversal) for each case
    Then audit logs record viewing/copy events, compliance at boundaries

    Examples:
      | nameLength   |
      | minimum      |
      | maximum      |

  # Integration/Negative: Backend HTTP 500 Service Failure During Card Fetch
  @ui @api @integration @negative
  Scenario: UI error modal and recovery for backend HTTP 500 during card fetch
    Given user requests eligible card list and backend returns HTTP 500
    Then UI displays error modal 'Unable to fetch card list, please retry later', disables sensitive operations
    When 'Try again' is clicked, error persists
    When 'Order new card' or 'Return to home' is selected, session resets and clean navigation is ensured
    Then audit log records failure, error modal, navigation, abort; retry after session reset resumes normal workflow

