Feature: Card Details Viewing and Security Compliance Workflow

  # Background: Common setup for authenticated user card details API/UI interactions
  Background:
    Given the user is authenticated
    And cards are available (as per scenario)
    And mobile phone registration status is as described
    And user language preference is set ("English" or "Hebrew")

  # Positive Scenario: Successful Card Details Viewing Flow
  @ui @api
  Scenario Outline: End-to-end card details viewing from main menu with positive flow
    Given the user navigates to 'View Card Details' from the main menu
    When the user selects a card '<cardBrand>' and views privacy/security guidance
    And initiates OTP authentication and receives code '<otpCode>'
    And enters correct OTP within the valid timer window
    And card details are retrieved via API and displayed with correct masking and branding ('<cardBrand>')
    Then card details screen is visible for 90 seconds only, fields properly masked except during timer
    And correct card image/logo is shown
    And session ends or data is erased when timer expires
    And privacy guidance is visible
    And cache integrity is maintained for back navigation, erased on timer/session close

    Examples:
      | cardBrand    | otpCode | sessionStatus |
      | VISA         | 123456  | TimerExpiry   |
      | MasterCard   | 654321  | ManualFinish  |
      | Amex         | 111222  | TimerExpiry   |
      | Isracard     | 333444  | ManualFinish  |

  # Negative Scenario: No Cards Found via API Response
  @api @ui
  Scenario Outline: Handle no cards present with regulatory zero-state error screens
    Given the user launches 'View Card Details' from the main menu
    When backend API returns status code <status> and errorId <errorId>
    Then a zero-state screen with illustration and correct messaging ('<language>'/<textDirection>) is displayed
    And 'Order new card' and 'Try again' buttons appear
    When the user clicks 'Try again'
    Then backend updates card data and UI refreshes
    When the user clicks 'Order new card'
    Then navigation goes to the card order flow
    And error messages comply with UX/regulatory standards
    And no PII is exposed
    And back navigation returns to the originating menu

    Examples:
      | status | errorId | language | textDirection |
      | 204    | 0       | English  | LTR           |
      | 203    | 31      | Hebrew   | RTL           |
      | 203    | 32      | English  | LTR           |

  # Boundary: OTP Attempt Boundary and Lockout Handling
  @ui @api
  Scenario Outline: OTP entry boundary, lockout, and recovery
    Given the user is prompted to enter OTP after initiating card details viewing
    When the user enters OTP value '<otpInput>' (<validity>)
    And repeats up to '<attemptCount>' times
    Then error message '<errorMessage>' is shown for incorrect entries
    And after exceeding max attempts, lockout popup and timer appears
    When user tries 'Resend code' during lockout
    Then error for blocked session is shown
    When timeout period '<lockoutTimeout>' ends and correct OTP '<correctOTP>' is entered
    Then session resumes and workflow completes if allowed
    And no card data exposed during lockout

    Examples:
      | otpInput | validity | attemptCount | errorMessage          | lockoutTimeout | correctOTP |
      | 111111   | wrong    | 5            | Incorrect OTP code    | 10min          | 222222     |
      | abcd12   | invalid  | 1            | Non-numeric OTP       | 0              | 123456     |
      | 12345    | invalid  | 1            | Too short (5 digits)  | 0              | 654321     |

  # Integration: Real-Time API Failure Handling & Data Refresh on Retry
  @api @ui
  Scenario Outline: Error propagation and retry logic for card details API failures
    Given the user selects a card to view details
    When backend API returns status code <status> and errorId <errorId>
    Then error screen/message '<uiErrorScreen>' is shown per decision table
    When the user clicks 'Try again'
    Then backend returns success and card details are displayed
    And cache is updated for back navigation and erased on session end
    And all regulatory masking rules are enforced

    Examples:
      | status | errorId | uiErrorScreen         |
      | 500    | 0       | Generic error popup   |
      | 203    | 31      | Zero-state screen     |
      | 203    | 32      | Lockout error popup   |
      | 203    | 33      | Expired OTP error     |
      | 403    | 0       | Permission denied     |

  # Role/Permission-Based: Access Control Non-Cardholder Handling
  @api @ui
  Scenario Outline: Enforcement of strict access control for non-cardholders
    Given a non-cardholder or unauthorized user attempts to view card details
    When API returns status code <status> and errorId <errorId>
    Then UI displays zero-state error screen with full masking for PII
    And retry and 'Order new card' buttons shown only if permitted
    And no card details or PII exposed or persisted in cache

    Examples:
      | status | errorId | userRole      |
      | 203    | 32      | NotCardholder |
      | 204    | 0       | Unauthorized  |
      | 403    | 0       | Unauthorized  |

  # State-Transition: Back Navigation Cache Redaction
  @ui
  Scenario Outline: Back navigation from card details screen before timer expiry
    Given the user viewed card details and timer '<timer>' is active
    When the user clicks 'Back' navigation before timer expiry
    Then user is returned to prior screen
    And all card data cache is fully wiped
    And card number, CVV, and other sensitive fields are masked per PCI DSS

    Examples:
      | timer    |
      | 90sec    |
      | 45sec    |
      | 10sec    |

  # Negative: Invalid Card Brand Codes
  @api @ui
  Scenario Outline: Handle unknown brandCode in card details rendering
    Given backend returns invalid brandCode '<brandCode>' after OTP authentication
    When the client attempts to render details screen
    Then fallback to generic branding image occurs
    And all card fields are masked
    And regulatory-compliant error message is displayed
    And retry or finish buttons are available

    Examples:
      | brandCode |
      | 99        |
      | 0         |
      | null      |

  # Boundary: Timer and Sensitive Data Erasure
  @ui
  Scenario Outline: Timer expiry enforces data erasure for card details
    Given card details screen timer starts at '<timerStart>'
    When timer reaches '<timerEnd>'
    Then sensitive fields (number, CVV, expiration) are erased
    And client cache is purged
    And user cannot copy or retrieve card info post-expiry

    Examples:
      | timerStart | timerEnd |
      | 90         | 0        |
      | 60         | 0        |

  # Localization: Multilingual & Directionality Rendering
  @ui
  Scenario Outline: Privacy and error message rendering in Hebrew (RTL) and English (LTR)
    Given user launches 'View Card Details' with language '<language>' and text direction '<direction>'
    When privacy guidance and timer/error popups are displayed
    Then all text and guidance complies with '<direction>' formatting
    And regulatory requirements for localization are met

    Examples:
      | language | direction |
      | Hebrew   | RTL       |
      | English  | LTR       |

  # Integration: Real-Time Card List Update and Ownership Filtering
  @ui @api
  Scenario Outline: Card list real-time update after new card order
    Given user completes card order and triggers API card list refresh
    When card selection screen is updated
    Then only user-owned cards are shown and selectable
    And newly ordered card '<newCardSuffix>' appears in list
    And selection filtering is enforced

    Examples:
      | newCardSuffix |
      | 1234          |
      | 5678          |

  # Boundary: Copy Card Details and PCI Masking
  @ui
  Scenario Outline: Copy-to-clipboard during timer, masking, and audit verification
    Given user views card details with timer '<timer>' running
    When 'Copy' button is clicked for '<field>' at '<timePoint>'
    Then clipboard contains '<clipboardValue>' as per PCI masking rules
    And audit log entry is created
    When timer expires
    Then clipboard contains only masked or empty value

    Examples:
      | timer | field         | timePoint    | clipboardValue |
      | 90    | cardNumber    | duringTimer  | **** **** **** 1234 |
      | 90    | cvv           | afterExpiry  | ***                |
      | 90    | expirationDate| afterExpiry  | masked            |

  # Negative: No Registered Mobile Phone - OTP Initiation Block
  @api @ui
  Scenario Outline: Block OTP initiation with no registered mobile phone
    Given user initiates OTP authentication without mobile number registered
    When API returns status <status> and errorId <errorId>
    Then error popup with guidance is displayed
    And no OTP screen appears
    And session is aborted, no card details or PII exposed

    Examples:
      | status | errorId |
      | 203    | 31      |

  # State-Transition: Multiple Card Filtering & Real-Time Update
  @ui
  Scenario Outline: Card selection with multiple cards, branding, and filter integrity
    Given card selection screen displays multiple cards with branding
    When user attempts to select non-owned card '<cardOwnership>'
    Then selection is disabled or blocked
    When new card is ordered and backend propagates update
    Then UI refreshes and new card '<newCardSuffix>' appears with correct branding
    And only owned cards are selectable

    Examples:
      | cardOwnership | newCardSuffix |
      | NonOwned      | 9999          |
      | Owned         | 8888          |

  # Boundary: Amex CVV Reveal and Multi-CVV Display
  @ui
  Scenario Outline: Amex dual-CVV display, timer, and PCI masking
    Given user selects Amex card and timer '<timerCVV>' starts
    When 'Reveal CVV Front' or 'Reveal CVV Back' is clicked
    Then CVV field '<cvvType>' is shown for timer duration
    And CVV can be copied only during timer
    And fields are masked after timer expiry
    And navigation between CVV screens works

    Examples:
      | timerCVV | cvvType      |
      | 16       | cvvFront     |
      | 16       | cvvBack      |

  # Positive: Session Finish Screen and Completion
  @ui
  Scenario Outline: Session finish screen displays contextual info and actions
    Given session ends by timer expiry or 'Finish' button
    When finish screen displays
    Then card suffix '<cardSuffix>' and regulatory text shown
    And action buttons allow navigation and ordering new card
    And errors surfaced on invalid navigation post-session
    And all card details are masked and cache redacted

    Examples:
      | cardSuffix   |
      | 5678         |
      | 4321         |

  # Positive: Preparation Screen Privacy and Security Guidance Rendering
  @ui @api
  Scenario Outline: Preparation screen displays API-driven privacy/security info
    Given privacy guidance, security advice, and timer info are received from API
    And language preference is '<language>'
    When preparation screen is shown before OTP
    Then guidance, images, and timer info appear in '<language>' and correct format
    And 'Back' navigation wipes all sensitive data

    Examples:
      | language |
      | English  |
      | Hebrew   |

  # Positive: Resend OTP by Voice with Boundary Timer and Error Handling
  @ui @api
  Scenario Outline: Resend OTP by voice, timer, and lockout logic
    Given user is on OTP screen
    When user clicks 'Resend OTP by Voice' and backend triggers smsByVoice
    And repeats up to '<resendAttempts>' times
    Then voice OTP info and timer are displayed
    And after max attempts error popup is shown
    When lockout timer '<lockoutDuration>' ends and user requests resend, new OTP is generated

    Examples:
      | resendAttempts | lockoutDuration |
      | 5              | 10min           |
      | 3              | 10min           |

  # Negative: CVV Expired Code Recovery and New OTP Issue
  @ui @api
  Scenario Outline: Handle expired OTP code, error and restart workflow
    Given user entered OTP code '<otpCode>' after expiry
    When API returns status <status> and errorId <errorId>
    Then error message '<errorText>' appears in red and input is disabled
    When user clicks 'Restart process'
    Then backend issues new OTP and workflow resumes
    And error and masking enforced throughout

    Examples:
      | otpCode | status | errorId | errorText                 |
      | 111111  | 203    | 33      | OTP expired, restart      |
      | 666666  | 203    | 33      | OTP expired, restart      |

  # Boundary: Card Selection Screen Maximum Cards and UI Overflow
  @ui @api
  Scenario Outline: Card selection handles maximum cards and overflow
    Given user account loaded with '<cardCount>' cards
    When selection screen displays all cards
    Then UI renders all entries without overflow errors
    And branding and ownership filtering works for each entry
    When new card is added via API refresh
    Then new card appears and is selectable if owned

    Examples:
      | cardCount |
      | 20        |
      | 18        |
      | 10        |

  # State-Transition: Concurrent Session Handling Multi-Device
  @ui @api
  Scenario Outline: Concurrent sessions on multiple devices with cache integrity
    Given user initiates card details workflow on device '<deviceType>'
    When OTP authentication and timer '<timer>' are active on each device
    Then session cache and masking are independent per device
    And abort on one device enforces masking globally
    And no cross-session data leaks occur

    Examples:
      | deviceType | timer |
      | Desktop    | 90    |
      | Mobile     | 90    |

  # Negative: API Timeout and Session Recovery for Card Details Retrieval
  @api @ui
  Scenario Outline: API timeout handling, masking, and retry logic
    Given user initiates card details workflow and enters valid OTP
    When API request times out (<timeout>)
    Then timeout error popup is shown as per regulatory guidance
    And all sensitive fields are masked
    When retry is pressed
    Then fresh API request retrieves card details and timer is activated

    Examples:
      | timeout |
      | 408     |
      | client  |

  # Negative: Attempt Copy Card Info After Session Timeout
  @ui
  Scenario Outline: Copy-to-clipboard after timer expiry masks all values
    Given timer expired/session closed after viewing card details
    When user tries to copy '<field>'
    Then clipboard contains only masked or empty value
    And navigation does not restore any card data

    Examples:
      | field        |
      | cardNumber   |
      | cvv          |
      | expirationDate|

  # Boundary: Minimum Timer for CVV Screen and Early Finish
  @ui
  Scenario Outline: Minimum timer boundary and early session finish for CVV screen
    Given CVV screen timer starts at minimum boundary '<timerSec>'
    When user presses 'Finish' before timer completes
    Then client cache for CVV and card details is cleared and masked
    And copy action is disabled or masked
    And user is redirected to session finish screen, no sensitive info shown

    Examples:
      | timerSec |
      | 16       |
      | 14       |

  # State-Transition: Switching Between Cards During Viewing Session
  @ui
  Scenario Outline: Switching cards mid-session triggers masking and workflow restart
    Given user has viewed first card with timer running
    When user attempts to switch to second card during session
    Then UI prompts for session abort and masking
    And old card cache is wiped, API triggers new workflow for second card
    And only new card data is visible, masking enforced for previous data

    Examples:
      | firstCardSuffix | secondCardSuffix |
      | 1234           | 4321             |
      | 5678           | 8765             |

  # Integration: In-Memory Cache Data Provenance with Back Navigation
  @ui @api
  Scenario Outline: Cache redaction and masking via back navigation after reveal
    Given card details revealed with timer running
    When user navigates back to preparation or card selection screen
    And returns to card details screen via back navigation
    Then at all stages, cache is erased and sensitive fields are masked
    And regulatory compliance is observed for PCI/PII
    When timer expires or session aborts
    Then no residual card info exists in cache

    Examples:
      | navigationPath    |
      | backToPrep        |
      | backToSelection   |
      | timerExpiry       |

  # Boundary: Card Details API Status/Error ID Decision Table Exhaustion
  @api @ui
  Scenario Outline: Exhaustive validation of HTTP status and errorId-to-UI mapping
    Given card details API returns <status> and errorId <errorId>
    When UI processes API response
    Then correct error screen/message '<uiScreen>' is shown
    And fields are masked as per PCI/PII
    And retry triggers fresh data refresh/PII masking

    Examples:
      | status | errorId | uiScreen             |
      | 203    | 31      | Zero-state           |
      | 203    | 32      | Lockout popup        |
      | 203    | 33      | Expired OTP screen   |
      | 204    | 0       | No card screen       |
      | 500    | 0       | Generic error popup  |
      | 403    | 0       | Permission denied    |

  # Integration: Card Vendor Product ID Image & Branding Mapping
  @ui @api
  Scenario Outline: Brand image and fallback rendering logic for card selection/details
    Given card selection/details screen displays cards with brandCode '<brandCode>' and productId '<vendorProductId>'
    When image retrieval is attempted for the card
    Then correct branding image appears for known brands
    And generic or placeholder image for invalid codes
    And branding persists through navigation and cache is wiped after session expiry
    And fallback and masking logic enforced

    Examples:
      | brandCode | vendorProductId |
      | 1         | MC_123          |
      | 2         | VISA_987        |
      | 3         | AMEX_456        |
      | 7         | ISR_333         |
      | 99        | UNKNOWN         |

  # State-Transition: Retry After Session Abort or Timer Expiry
  @ui @api
  Scenario Outline: Full workflow restart after abort/timer expiry ~ masking and API refresh
    Given session abort or timer expiry occurred
    When user retries from main menu or workflow entry point
    Then all sensitive data is masked/redacted
    And fresh API call retrieves new OTP and card data
    And no session data is carried over from previous attempt
  
    Examples:
      | sessionEndType |
      | abort          |
      | timerExpiry    |

  # Negative: Invalid Input Handling for OTP Entry
  @ui
  Scenario Outline: Negative input validation for OTP entry screen
    Given user is on OTP entry screen
    When OTP input '<otpInput>' is submitted (<inputType>)
    Then input is blocked or shows regulatory-compliant error '<errorText>'
    And red inline messaging and input field reset/masking is enforced
    And session is clean after abort, no PII exposure

    Examples:
      | otpInput | inputType     | errorText          |
      | abcdef   | non-numeric   | Only digits allowed|
      | 12345    | short         | OTP must be 6 digits|
      | 999999   | repeatedInvalid| Invalid code entered|

  # Integration: Client/Server Split Rendering and Session Data Redaction
  @ui @api
  Scenario Outline: Full client/server rendering, cache expiry and back navigation masking
    Given client renders guidance text/image, server delivers sensitive values
    When OTP and card details screens are displayed
    Then branding images and timer are rendered per client/server split
    When session expires, user navigates back, or cache is accessed
    Then local/session cache is erased, all sensitive fields masked, no restoration after navigation

    Examples:
      | guidanceSource | valueSource   |
      | client         | server        |
      | client         | server        |
