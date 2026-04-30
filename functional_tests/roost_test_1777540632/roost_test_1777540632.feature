Feature: Card Details Viewing, Authentication, Regulatory Compliance, and Audit – Comprehensive UI, API, Boundary, Negative, Performance, End-to-End and Audit Coverage

  # Background setup for UI and API scenarios
  Background:
    Given the user is authenticated in the portal or mobile app
    And eligible cards (Mastercard, VISA, AMEX, Isracard) are issued
    And session timer and audit logic are active

  # UI and API test scenarios for 'No Card Available' state
  @ui @api
  Scenario Outline: Main Menu Zero Card Handling – Regulatory Text, Navigation, and Audit Mapping
    Given user is logged in with no issued cards
    When user selects 'View Card Details' from main menu
    And API call to "/card-channel/web-order/card-account/cards/details" returns <status_code> and <id_value>
    Then UI displays 'No cards found' message with mandatory regulatory text
    And navigation buttons '<order_button>', '<home_button>' are visible and functional
    And clicking '<order_button>' launches new card order flow
    And clicking '<home_button>' redirects to homepage
    And audit event is logged for card view attempt and navigation
    And no card PII is displayed in UI or logs

    Examples:
      | status_code | id_value | order_button      | home_button       |
      | 204         | null     | Order new card    | Go to homepage    |
      | 203         | 31       | Order new card    | Go to homepage    |

  # Boundary and negative tests for OTP attempts, blocking, and retry restriction
  @ui @audit
  Scenario Outline: OTP Authentication – Excess Attempts Block, Regulatory Text, Timer and Audit
    Given user is at OTP authentication step for card details
    And maximum allowed OTP attempts is <max_attempts>
    When user enters invalid OTP code <attempts> times
    Then UI displays regulatory error blockscreen with timer ('Try again in <timer> minutes')
    And input and navigation are disabled during blockscreen
    And attempts counter persists across browser closes and navigation
    And audit events are logged for block, attempt count, and unblock
    And retry is only allowed after timer expiry

    Examples:
      | max_attempts | attempts | timer |
      | 3            | 3        | 10    |

  # End-to-end scenarios for multi-brand card details viewing, timer, masking, audit
  @ui @api @audit
  Scenario Outline: Full E2E Card Details View – Brand Differentiation, Masking, Timer, Audit
    Given user has issued cards for Mastercard, VISA, and AMEX
    When user selects <brand> card and completes privacy enforcement and OTP flow
    Then UI displays card details with proper branding/logo and masked PII
    And <cvv_fields> are displayed per brand logic
    And regulatory warning and timer (90 seconds) are enforced
    And copy-to-clipboard is allowed only when info visible and clipboard clears at expiry
    And user can complete using 'Finish' action; session ends and audit logs for each step

    Examples:
      | brand      | cvv_fields           |
      | Mastercard | Single CVV           |
      | VISA       | Single CVV           |
      | AMEX       | Dual CVV (front/back)|

  # Negative scenario: Missing phone for OTP (regulatory error dialog, UI block, audit)
  @ui @api @audit
  Scenario Outline: Missing Phone – Regulatory Error Dialog, UI Blocking, Onboarding, Audit
    Given user has issued cards but no mobile phone registered
    And API response is 203+ID=31
    When user attempts OTP authentication for card details
    Then error popup with regulatory language is shown ('No phone registered, update required')
    And UI disables input and process cannot continue
    And navigation options '<home_option>', '<contact_option>' are available
    And audit event is generated for missing phone

    Examples:
      | home_option        | contact_option      |
      | Go to homepage     | Contact banker      |

  # Functional scenario: Timer expiry triggers masking, UI block, clipboard clear, audit
  @ui @audit
  Scenario: Session Timer Expiry – Card Data Masking, Clipboard Clear, UI Block
    Given user completed OTP authentication and session timer countdown is active
    When timer reaches 90 seconds
    Then UI displays blockscreen with regulatory text
    And card details are instantly masked
    And clipboard is cleared immediately
    And navigation and retry are blocked until session restarted
    And audit log is recorded for session expiry and completion

  # UI and cache validation: Multi-card selection masking, navigation, audit log
  @ui @audit
  Scenario: Multi-Card Selection UI – Brand Differentiation, PII Masking, Cache and Navigation
    Given user has multiple issued cards (Mastercard, VISA)
    When user views card selection UI
    Then only user's cards are listed with correct branding and masked last 4 digits
    And no unauthorized cards or extra info displayed
    When user selects a card and navigates back
    Then cached card list appears masked
    And privacy enforcement applies for each selection
    And navigation options ('Home', 'Continue') are functional
    And audit logs are generated for selection and navigation

  # Negative scenario: Expired OTP, regulatory error, retry, session reset, audit
  @ui @audit
  Scenario Outline: Expired OTP Code Entry – Regulatory Error Dialog, Retry, Audit Logging
    Given OTP code sent via SMS with expiry logic enabled
    When user enters expired OTP code after <wait_time> minutes
    Then UI shows error dialog ('OTP expired, start over'), disables code entry
    And clicking retry initiates new session and new code sent
    And navigation or resend old code is restricted
    And audit logs record expired OTP and retry

    Examples:
      | wait_time |
      | 6         |

  # Boundary scenario: OTP input validation for under/over length and invalid format
  @ui @audit
  Scenario Outline: OTP Code Format – Digit Boundary, Input Validation, Error Handling, Audit
    Given user is at OTP code input stage for card details
    When user enters OTP code "<otp_code>"
    And attempts to proceed
    Then UI shows distinct regulatory error dialog for input format violation
    And code entry box restricts input or clears on error
    And audit logs capture failed attempt type

    Examples:
      | otp_code    |
      | 12345       |    # Under 6 digits
      | 1234567     |    # Over 6 digits
      | ab12!@      |    # Alphanumeric
      | 123 456     |    # Whitespace

  # Boundary scenario: OTP resend limit (SMS/voice), block, timer, audit
  @ui @audit
  Scenario Outline: OTP Resend Limit – Blocking, Timer, Regulatory Error, Audit
    Given user is at OTP entry stage with resend attempt tracking
    When user requests '<otp_type>' OTP resend <attempts> times
    And maximum allowed resend attempts is <max_attempts>
    Then UI displays regulatory popup ('Too many requests, wait <timer> minutes'), disables input and navigation
    And block persists across navigation/browser closure
    And audit logs are generated for resend, block, and unblock events
    When timer elapses and user retries
    Then new OTP is sent, session resumes

    Examples:
      | otp_type   | attempts | max_attempts | timer |
      | SMS        | 3        | 3            | 10    |
      | Voice      | 2        | 2            | 10    |

  # Negative scenario: Unauthorized card access, UI masking, regulatory dialog, navigation block, audit
  @ui @audit
  Scenario Outline: Unauthorized Card Access Attempt – Regulatory Error, Masking, Navigation Block, Audit
    Given user is at card selection UI with option to select unauthorized card <card_type>
    When user attempts to select card not registered to their name
    Then card info is masked and action buttons disabled
    And UI shows regulatory error dialog ('You may only view cards registered to your name')
    And navigation ('Home', 'Continue') is blocked
    And audit event is generated for unauthorized access attempt
    And PII masking enforced in UI and logs

    Examples:
      | card_type    |
      | Foreign      |
      | Test-Injected|

  # Copy-to-clipboard feature: Timer, masking, regulatory restrictions, audit
  @ui @audit
  Scenario Outline: Copy-to-Clipboard – Timer Enforcement, Masking, Audit Logging, Brand-Specific CVV
    Given card details screen is visible with timer active
    When user clicks 'Copy-to-clipboard' for <field>
    Then clipboard receives card info for permitted window
    When timer expires or user clicks 'Finish'
    Then clipboard is cleared immediately
    And copy is disallowed while UI masked or session ended
    And regulatory warning is shown
    And audit logs capture copy and clipboard clear actions
    And dual CVV flows for AMEX are handled

    Examples:
      | field        |
      | Card number  |
      | Expiry       |
      | CVV          |
      | AMEX-CVV1    |
      | AMEX-CVV2    |

  # End-to-end scenario: Actions Lobby Post-Issuance Flow, API codes, retry, caching, audit
  @ui @api @audit
  Scenario Outline: Actions Lobby – Card Not Available, Retry Logic, Regulatory Text, Cache, Audit
    Given user completes card ordering and arrives at actions lobby
    And API response is <status_code> (<id_value> if applicable)
    When user clicks 'View Card Details'
    Then UI shows regulatory 'No card found' state ('Card not yet ready, try again soon')
    And navigation options ('Retry', 'Go to homepage') are visible
    When user clicks 'Retry' after <interval> seconds
    And API call retries retrieval
    Then on success, card selection and privacy screens are shown with masked data and persistent cache
    And audit logs record issuance, retry, navigation, and successful view events
    And UI does not display new card PII until authorized

    Examples:
      | status_code | id_value | interval |
      | 203         | 31       | 5        |

  # UI masking scenario: Mobile number and PII masking in OTP screen
  @ui @audit
  Scenario Outline: Masked Mobile Number and PII Validation – Regulatory Compliance Across Brands/Channels
    Given user triggers OTP send at authentication stage
    When UI displays masked mobile number ("<masked>") on OTP screen
    Then UI does not display full phone number or other PII
    And all personal data masked in UI and audit logs
    And privacy overlays are active
    And audit log contains masked fields only

    Examples:
      | masked        |
      | 052-6***53    |

  # Functional scenario: State transition, block persistence, retry after timer
  @ui @audit
  Scenario Outline: Session Block Persistence – Timer, Navigation, Retry, Audit
    Given user session block is triggered due to <reason>
    And block timer is active
    When user closes browser or navigates away and returns
    Then block persists with regulatory text and timer
    And navigation within session ('back', 'home', 'retry') is blocked
    When timer expires and user retries
    Then session resets and new workflow permitted
    And audit logs record block, unblock, and retry transitions

    Examples:
      | reason         |
      | Timer expiry   |
      | Max OTP        |

  # Boundary scenario: Timer edge case for copy/navigation just before expiry
  @ui @audit
  Scenario Outline: Timer and Data Exposure – Copy/Navigation Edge Case Handling, Clipboard, Audit
    Given user is at card details screen with timer active
    When user attempts to copy card info at <boundary_time> seconds
    Or attempts navigation actions at <navigation_time> seconds
    Then UI immediately masks info and clipboard clears at timer expiry
    And navigation to card details is blocked post-expiry
    And audit logs show precise timing for actions
    And test is repeated across brands and channels

    Examples:
      | boundary_time | navigation_time |
      | 89            | 89.5            |

  # Performance scenario: Latency and exposure time for card details retrieval (API, UI, error, timer, audit)
  @performance @audit @api
  Scenario Outline: Latency SLAs – API Response, UI Rendering, Timer Countdown, Error Dialogs, Audit
    Given user initiates card details retrieval process via <channel>
    When API call to "/card-channel/web-order/card-account/cards/details" is made
    And UI renders card info, regulatory warning, timer, copy controls
    Then measured latency between request, UI display, timer start is <ui_latency> seconds
    And copy action occurs; clipboard updates within <copy_latency> seconds
    And error dialogs (e.g., expired OTP) appear within <error_latency> seconds
    And session timer expires; UI transitions immediately (<timer_latency> seconds)
    And all major audit events have timestamp accuracy for session start/end, copy, error, session end

    Examples:
      | channel    | ui_latency | copy_latency | error_latency | timer_latency |
      | Web        | <1         | <1           | <2            | <1           |
      | Mobile     | <1         | <1           | <2            | <1           |

  # Audit scenario: Comprehensive audit trail for card access workflow, masking, regulatory compliance
  @audit
  Scenario Outline: Audit Trail – Multi-Step Authentication, Card Access, Navigation, Regulatory Compliance
    Given user progresses through card details workflow stage <action>
    When audit logic is active
    Then audit event is logged for stage <action> with regulatory data, masking, timestamp
    And all personal fields are masked in audit logs
    And regulatory mandates for financial services are met

    Examples:
      | action                  |
      | Card selection          |
      | Privacy enforcement     |
      | OTP send/resend         |
      | OTP validation          |
      | Card view               |
      | Copy-to-clipboard       |
      | Session end             |
      | Error/block screen      |
      | Navigation              |

  # Functional: Voice OTP flow, masking, resend, error popup, audit (brands, channels)
  @ui @api @audit
  Scenario Outline: Voice OTP Flow – Masking, Resend Limit, UI Differences, Regulatory Text and Audit
    Given user requests voice call OTP for <brand> via <channel>
    When UI displays masked phone number and regulatory text for voice
    And user enters received OTP
    Then authentication succeeds with regulatory compliance
    When user uses 'Resend voice call OTP' <attempts> times
    Then regulatory popup appears at max resend, input blocked
    When failed call or API error occurs
    Then regulatory error popup is shown
    And audit logs capture each send/resend, entry, error, navigation

    Examples:
      | brand      | attempts | channel    |
      | Mastercard | 2        | Web        |
      | VISA       | 2        | Mobile     |
      | AMEX       | 2        | Web        |

  # Boundary: Card Details API error codes, decision table mapped to UI/error – regulatory compliance, masking, audit
  @ui @api @audit
  Scenario Outline: Card Details API Error Codes – Regulatory UI Mapping, Masking, Navigation, Audit
    Given user triggers card details retrieval via API returning <status_code> (<id_value>)
    When UI error mapping is performed
    Then regulatory error or blockscreen is shown per code
    And masking enforced for card info
    And navigation options '<nav_option1>', '<nav_option2>' are visible per code
    And audit event recorded for the error
    And UI and error mapping meet regulatory table requirements

    Examples:
      | status_code | id_value | nav_option1 | nav_option2 |
      | 203         | 31       | Retry       | Home        |
      | 203         | 32       | Home        | Back        |
      | 204         | null     | Order card  | Home        |
      | 400         | null     | Retry       | Home        |
      | 500         | null     | Retry       | Home        |

  # End-to-end scenario: Mobile channel integration – card view, authentication, responsive UI, audit
  @ui @api @audit
  Scenario Outline: Mobile Channel Integration – Card Details, Responsive UI, Timer, Copy, Masking, Audit
    Given user launches <channel> and selects card <brand>
    When user progresses through privacy screen, OTP authentication, card details view
    Then responsive UI renders card info with regulatory text, masking, timer, copy controls
    And copy-to-clipboard actions permitted only when info is visible
    When timer expires, UI blocks and clipboard clears
    When user navigates back to card selection or privacy screen
    Then masking/caching is handled per regulatory logic
    And audit logs document all events

    Examples:
      | channel        | brand      |
      | Mobile app     | Mastercard |
      | Mobile app     | VISA      |
      | Mobile app     | AMEX      |
      | Mobile app     | Isracard  |
      | Mobile web     | VISA      |
      | Mobile web     | AMEX      |

  # Negative scenario: Invalid authentication – birthdate/name mismatch, regulatory error, masking, audit
  @ui @audit
  Scenario Outline: Invalid Authentication – Regulatory Error Dialog, Masking, Navigation Block, Audit
    Given user enters invalid <auth_field> (<input_value>) during authentication step
    When user proceeds to OTP send/validation
    Then UI displays regulatory error dialog ('Authentication failed, please verify your details')
    And input fields are masked with no sensitive info exposed
    And navigation ('Home', 'Retry', 'Back') is blocked until correct input provided
    And guidance for retry/onboarding displayed
    And audit log records failed authentication and navigation

    Examples:
      | auth_field   | input_value          |
      | birthdate    | mismatched date      |
      | name         | mismatched name      |

  # Performance scenario: Session timeout/API failover – regulatory UI, masking, recovery, audit
  @ui @api @performance @audit
  Scenario Outline: Session Timeout & API Failover – Regulatory Error, Masking, Recovery, Latency, Audit
    Given session timer active or API/network outage during card details workflow
    When session times out or API fails (simulated latency <failover_latency>)
    Then UI displays regulatory error screen immediately (<error_latency> seconds)
    And all card data and clipboard are cleared
    And navigation only permits return to main menu or retry after service is restored
    And PII masking enforced in all screens and logs
    And audit logs record failover, recovery action, and latency

    Examples:
      | failover_latency | error_latency |
      | <2               | <1           |

  # Functional: Card selection cache and state transition post-session expiry/manual finish
  @ui @audit
  Scenario Outline: Card Selection State Transition – Cache, Masking, Regulatory Text, Audit
    Given user completes card details session via <session_end> (timer/manual)
    When user navigates back to card selection UI
    Then previously selected card appears masked with privacy overlays active
    And cache retains state for non-PII only
    And selecting another card triggers privacy and OTP flow anew
    And audit logs record session end, navigation, and card re-selection

    Examples:
      | session_end |
      | Timer      |
      | Manual     |

  # Boundary: Conditional CVV display for brands, UI, error handling, masking, audit
  @ui @audit
  Scenario Outline: Card Details Exposure – Brand CVV Display Logic, Masking, Conditional Permissions, Audit
    Given user views card details for <brand>
    When user navigates to CVV screen
    Then UI displays <cvv_display> per brand logic, regulatory wording present
    And copy/mask permissions applied per regulatory rules
    And masking enforced for each CVV permutation
    When timer expires, all CVV fields are masked
    And audit logs record CVV access, display, masking, navigation

    Examples:
      | brand      | cvv_display          |
      | Mastercard | Single CVV          |
      | VISA       | Single CVV          |
      | Isracard   | Conditional CVV     |
      | AMEX       | Dual CVV            |

  # Negative: API timeout during card details retrieval, error dialog, masking, recovery navigation, audit
  @ui @api @audit
  Scenario Outline: Failed Card Details Retrieval – API Timeout, Regulatory Dialog, Masking, Recovery, Audit
    Given user initiates card details retrieval and API times out
    When UI transitions to regulatory error dialog ('Timeout occurred, please retry')
    Then no card data is displayed or cached
    And navigation options ('Retry', 'Go to homepage') are available
    When user clicks 'Retry', API call is reattempted
    And direct access to card details UI is blocked, masking persists
    And audit logs record retrieval failure, error, retry, navigation

    Examples:
      | error_type |
      | API timeout|

  # Functional: Explicit navigation return, session closure, masking, regulatory text, audit
  @ui @audit
  Scenario Outline: Return from Card Details/CVV View – Session Closure, Masking, Regulatory Text, Audit
    Given user is viewing card details or CVV info with session timer running
    When user clicks '<nav_button>' to exit details view before timer expiry
    Then system masks card data, closes session, displays regulatory guidance
    When user attempts to return to card details, session remains closed and UI masked
    And attempt to copy card info fails, regulatory guidance shown
    And cache does not retain exposed data post-navigation
    And audit logs include navigation, session closure, masking

    Examples:
      | nav_button           |
      | Return to main menu  |
      | Back to card selection|

  # Boundary: Input validation for OTP, card suffix, birthdate – whitespace, symbols, error dialog, audit
  @ui @audit
  Scenario Outline: Input Validation – OTP, Card Suffix, Birthdate – Whitespace, Invalid Characters, Error Dialog, Audit
    Given user enters <input_type> with invalid value "<input_value>"
    When user attempts to proceed in card details authentication
    Then UI shows distinct regulatory error dialog for invalid input
    And input fields are cleared for new input
    And navigation options ('Back', 'Continue') are blocked until valid input
    When user enters valid numeric input, progression succeeds
    And audit logs record invalid input attempts and errors

    Examples:
      | input_type   | input_value    |
      | OTP          | " 123456"      |
      | CardSuffix   | "7890 "        |
      | Birthdate    | "01-01-19!@#"  |
      | OTP          | "12 3456"      |
      | CardSuffix   | "78$90"        |


  # Brand-specific: AMEX UI, dual CVV flow, regulatory text, timer compliance, masking, audit
  @ui @audit
  Scenario: AMEX Brand-Specific UI and Dual CVV Display – Regulatory Enforcement, Masking, Timer, Audit
    Given user selects AMEX card and completes privacy enforcement and OTP authentication
    When UI displays AMEX card details screen with dual CVV fields (front and back)
    Then regulatory text instructions for AMEX are shown
    And masking is enforced for both CVVs and card info
    And timer controls are active, copy-to-clipboard permitted only per rules
    When timer expires, session ends and card data masked
    And navigation (back, finish) operates per AMEX flow
    And audit logs capture all AMEX session actions

  # Functional: Privacy enforcement screen, regulatory warning, timer info, UI elements, audit
  @ui @audit
  Scenario: Pre-View Privacy Enforcement Screen – Regulatory Wording, Images, Navigation, Timer, Audit
    Given user selects a card for viewing
    When privacy enforcement screen is shown
    Then regulatory warning text is displayed ('No one else should view the screen', 'Do not store card info')
    And branded card image, privacy icon, explanatory tooltip are visible
    And timer info explains 90-second exposure
    And navigation buttons ('Back', 'View Card Details') are displayed
    When user clicks 'Back', returns to selection screen
    When user clicks 'View Card Details', proceeds to card details and audit log is created for privacy event
