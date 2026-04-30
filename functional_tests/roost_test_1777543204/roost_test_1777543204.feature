Feature: Secure Card Details Viewing Workflow and Privacy Enforcement

  # UI Tests: Card Selection, Masking, Branding, Navigation, and Pre-View Warnings

  @ui
  Scenario Outline: Card selection list displays only eligible and user-owned cards, with masked details and correct branding
    Given I am logged in as '<user_type>' with <num_cards> eligible card(s)
    When I navigate to the card selection screen
    Then I should see a list of <num_cards> card(s) registered to my account, each with masked card number ('**** <cardSuffix>')
    And the brand image matches <cardVendorProductId> (e.g., VISA for code 2)
    And the owner name field displays '<partyFirstName> <partyLastName>'
    And no cards from other users are shown
    And audit log records selection event

    Examples:
      | user_type       | num_cards | cardSuffix | cardVendorProductId | partyFirstName | partyLastName |
      | single-card     | 1         | 4242       | 1                   | John          | Doe           |
      | multi-card      | 2         | 1234       | 2                   | Jane          | Smith         |
      | multi-card      | 2         | 5678       | 3                   | Alice         | Rosenberg     |
      | multi-card      | 3         | 1357       | 7                   | David         | Cohen         |

  @ui
  Scenario: Still pending card state message shown
    Given I am logged in as a user who has just ordered a card that is not yet approved
    When I attempt to view card details from the main menu
    Then I should see the message "The card you just ordered will appear only after approval. Please check again in a few moments"
    And no card selection or copy buttons are present
    And only navigation options to order new card or return home are available

  @ui
  Scenario Outline: Pre-view warning privacy screen and timer display
    Given I am on the privacy pre-view screen after successfully retrieving card details
    When the API provides a valid card response and privacy guidance
    Then the UI transitions to the pre-view warning screen, not displaying card details immediately
    And privacy message '<privacyInfo>' is shown, fetched from backend
    And regulatory guidance '<securityInfo>' is shown
    And timer set for '<duration>' seconds is visible
    And warning '<timerInfo>' about exposure duration is present
    And audit log contains record for pre-view step

    Examples:
      | privacyInfo                               | securityInfo                                                                           | duration | timerInfo                              |
      | Make sure no one else is watching the screen | It is recommended not to save the card number on your computer or mobile phone and to ensure confidentiality of card details | 90      | Card details will be shown for 90 seconds  |

  @ui
  Scenario Outline: Pre-view image assets loaded from local client library
    Given I am on the pre-view privacy/warning screen (Sc0004)
    When the UI loads image placeholders '<images>'
    Then all images are fetched from the local client asset store
    And no network fetches for these images occur
    And all text and warning banners are present alongside images

    Examples:
      | images                     |
      | eye, group, clip           |

  @ui
  Scenario Outline: Navigation back, home, or return clears session and redirects user
    Given I am on '<current_screen>' with navigation controls visible
    When I click '<nav_button>' button
    Then I am redirected to the card hub/main credit card menu
    And session and cached details are cleared
    And audit log traces navigation event
    And no sensitive card data remains in session or UI

    Examples:
      | current_screen     | nav_button |
      | card details UI    | Back       |
      | card details UI    | Home       |
      | no cards UI        | Back       |
      | selection menu     | Return     |
      | error screen       | Close      |
      | completion screen  | Finish     |

  @ui
  Scenario Outline: Action buttons appear and work in 'No Cards' state
    Given I am on the 'No Cards Available' UI
    When I click '<action_button>' button
    Then the UI triggers correct redirection or next operation as per source rules
    And only permitted action buttons are available
    And audit log captures action usage
    And no sensitive card data is present in UI

    Examples:
      | action_button |
      | Go to Home    |
      | Order Card    |

  @ui
  Scenario: No Eligible Cards blocks retrieval and shows explanatory UI
    Given my user account has no eligible cards
    When I attempt to view card details from the main menu
    Then I see the 'No Cards' UI state with correct message explaining lack of eligible cards
    And card retrieval action is blocked
    And only navigation/order buttons are shown
    And audit log records zero-card access attempt

  @ui
  Scenario Outline: Owner name field is populated from backend service for card selection UI
    Given I am viewing card selection UI with cards from backend
    When partyFirstName='<partyFirstName>' and partyLastName='<partyLastName>' are provided by backend
    Then UI displays 'Owner: <partyFirstName> <partyLastName>' for each card

    Examples:
      | partyFirstName | partyLastName |
      | John           | Doe           |
      | Jane           | Smith         |
      | Alice          | Rosenberg     |

  @ui
  Scenario Outline: Card masking rules and brand-dependent image/label rendering
    Given card details are displayed with brandCode '<brandCode>' and masking fields from backend
    When viewing card details screen for brandCode '<brandCode>'
    Then only masked card number and last 4 digits ('<maskedCardNumber>') are shown, never the full number
    And the brand image and label for '<brandLabel>' are present
    And audit/clipboard/logs contain only masked values

    Examples:
      | brandCode | maskedCardNumber          | brandLabel   |
      | 1         | **** **** **** 4242       | MasterCard   |
      | 2         | **** **** **** 1234       | VISA         |
      | 3         | **** **** **** 5678       | Amex         |
      | 7         | **** **** **** 1357       | Isracard     |
      | 99        | **** **** **** XXXX       | Fallback     |

  @ui
  Scenario Outline: Card details and CVV are copied only when visible
    Given card details or CVV are visible and copy icon/button is enabled
    When I click the copy icon for '<field>' during exposure
    Then the clipboard contains only '<maskedValue>' as shown in UI
    And after session expires or card details are masked, copy icon is disabled and clipboard is cleared

    Examples:
      | field       | maskedValue          |
      | cardNumber  | **** **** **** 4242  |
      | CVV         | ***                  |

  @ui
  Scenario Outline: AMEX dual-CVV display and toggle actions
    Given I am viewing AMEX card details screen (brandCode=3) with CVVs populated
    When I click '<toggle_button>' to view '<side>' CVV
    Then the correct CVV and label are shown for '<side>'
    And toggle button updates UI appropriately
    And audit logs record toggle action
    And after timer expiry, both CVV fields are hidden and toggle is disabled

    Examples:
      | toggle_button      | side   |
      | Show Back CVV      | back   |
      | Show Front CVV     | front  |

  @ui
  Scenario Outline: Field population from backend for card selection screen
    Given backend provides '<cardListInfo>', '<cardTypeTilte>', '<cardNumberTitle>' values
    When I load the card selection screen
    Then UI fields show text exactly as delivered

    Examples:
      | cardListInfo            | cardTypeTilte   | cardNumberTitle   |
      | Select the card to view | Debit Card      | Card Number       |
      | Choose a card           | Credit Card     | Number            |

  @ui
  Scenario Outline: Privacy enforcement, guidance, and timer are sourced from backend and shown before card details
    Given the privacy/warning screen is entered before viewing card details
    When backend delivers '<privacyGuidance>' and '<securityGuidance>' with timer info '<timerGuidance>'
    Then UI displays these texts exactly as provided by backend
    And timer for '<duration>' seconds is visible
    And user cannot proceed without seeing warning
    And audit is recorded

    Examples:
      | privacyGuidance                         | securityGuidance                                                                           | timerGuidance                           | duration |
      | Make sure no one else is watching        | It is recommended not to save the card number...                                            | Card details will be shown for 90 seconds| 90      |

  @ui
  Scenario Outline: Masked phone number is always shown in the OTP entry notification
    Given I am on the OTP entry screen after triggering OTP send
    When backend returns masked phone number '<maskedPhone>' in otpInfo
    Then UI shows notification "To protect your account, we sent an authentication code to <maskedPhone>"
    And no full mobile numbers are exposed in UI, logs, or API responses

    Examples:
      | maskedPhone   |
      | 052-6***53    |
      | 05X-XXXXXX    |

  @ui
  Scenario: OTP error message disappears as soon as input changes
    Given a red error message is shown after entering an invalid OTP code
    When I begin typing a new OTP digit
    Then the error message immediately disappears
    And the input field updates with only the new code

  # API Tests: Card Retrieval, OTP, Error Handling, Block/Timer Flows, Audit Logging

  @api
  Scenario Outline: Card retrieval API boundary responses (204, 203+ID=31) trigger 'No Cards' UI state
    Given the API base URL is '/card-account/cards/details'
    And the authorization token is set
    When I send a GET request with activityTypeCode=<activityTypeCode> and receive HttpStatusCode=<statusCode> with ID=<errorId>
    Then the UI shows '<uiState>' with explanatory text
    And no card details or sensitive values are exposed
    And logs confirm error handling and audit event

    Examples:
      | activityTypeCode | statusCode | errorId | uiState            |
      | 902              | 204        | null    | No Cards UI        |
      | 902              | 203        | 31      | No Cards UI        |
      | 902              | 203        | 32      | No Cards UI        |

  @api
  Scenario Outline: OTP verification for valid and invalid codes triggers correct state transitions
    Given the API for OTP verification is '/restore-card-information/verify-otp'
    When I send a POST request with payload
      """
      {
        "orderId": "<orderId>",
        "otpCode": "<otpCode>"
      }
      """
    Then the response status is <status>
    And UI transitions to <next_screen>
    And card details are masked and timer starts if OTP succeeded
    And error message '<errorMsg>' appears if OTP fails
    And audit log reflects authentication outcome

    Examples:
      | orderId    | otpCode  | status | next_screen           | errorMsg                                                          |
      | 928462     | 123456   | 200    | card details view     |                                                                   |
      | 928462     | 654321   | 203    | OTP error screen      | Code entered is incorrect. Please try again                       |
      | 928462     | 111111   | 203    | OTP error screen      | Code entered is incorrect. Please try again                       |
      | 928462     | expired  | 203    | expired, restart      | The authentication code is no longer valid. Please restart recovery|
      | 928462     | block    | 203    | blockscreen           | Access to view card details blocked after excessive OTP requests   |

  @api
  Scenario Outline: OTP expiry and block handling disables input, instructs restart, and logs audit
    Given the user is at OTP entry screen with expired or blocked session
    When backend responds with HttpStatusCode=<statusCode> and errorId=<errorId>
    Then UI shows error message '<errorMsg>' in red
    And OTP input field is cleared and disabled
    And user must restart recovery process as instructed
    And audit event is recorded

    Examples:
      | statusCode | errorId | errorMsg                                              |
      | 203        | 33      | The authentication code is no longer valid. Please restart recovery|
      | 203        | 32      | Access to view card details blocked after excessive OTP requests   |

  @api
  Scenario Outline: No phone detected for OTP blocks and prevents further attempts
    Given the user initiates OTP request for card viewing
    And user profile has no phone number registered
    When backend returns HttpStatusCode=203 with errorId=31
    Then UI displays block popup overlay with message "Your mobile phone number does not exist in the system. To proceed, please update it"
    And no further OTP or card viewing actions are permitted

    Examples:
      | statusCode | errorId | blockMsg                                                          |
      | 203        | 31      | Your mobile phone number does not exist in the system. To proceed, please update it |

  @api
  Scenario Outline: Attempt retry for card retrieval post-issuance with dynamic API response
    Given a user has just issued a card and is viewing the 'No Card Found' UI
    When user clicks 'Try Again' and a GET request to '/card-account/cards/details' is sent
    And backend returns <responseStatus> and <responseBody>
    Then UI state updates as follows
      | Response        | UI Next State               |
      | 203/ID=31       | No Card Found screen with retry option |
      | 200/Card data   | Pre-view warning enforcement screen    |
    And audit log captures retry action

    Examples:
      | responseStatus | responseBody            |
      | 203            | { "errorId": 31 }       |
      | 200            | { "cardDetails": {...} }|

  @api
  Scenario Outline: Attempt counter resets after block duration
    Given user is blocked from OTP entry/request after excessive attempts
    When block duration of <blockDuration> minutes elapses
    And user re-initiates card detail retrieval or OTP entry
    Then blockscreen is cleared and user can try again
    And attempt counter is reset
    And system logs show block resolution

    Examples:
      | blockDuration |
      | 10            |

  @api
  Scenario Outline: Audit event is logged for navigation or session closure
    Given user completes card viewing session and navigates or closes process
    When UI triggers process closure or navigation back to origin/home
    Then an audit event is recorded with fields:
      | Field             | Value                          |
      | userId            | masked/test format             |
      | timestamp         | current time                   |
      | sessionId         | generated session ID           |
      | originScreen      | process origin/menu            |
      | actionType        | close, navigate                |
      | cardReference     | last 4 digits only             |
      | panFull           | not present                    |
      | phoneFull         | not present                    |
    And audit event is persistent, immutable, and retrievable

    Examples:
      | actionType | originScreen         |
      | close      | credit card menu     |
      | navigate   | post-issuance lobby  |

  # Performance Tests: Timer, Session Expiry, Exposure Duration

  @performance
  Scenario Outline: Timer component initiates at 90 seconds, counts down accurately, and triggers session end
    Given I enter '<screen_type>' for card details viewing
    When timer initiates at <duration> seconds and counts down every second
    Then timer displays correct countdown and expiry triggers session end screen
    And card details are hidden after expiry
    And audit logs record session end

    Examples:
      | screen_type         | duration |
      | non-AMEX details    | 90       |
      | AMEX details        | 90       |
      | CVV details (Sc0014)| 90       |

  @performance
  Scenario Outline: Block duration for exceeded OTP requests enforces 10-minute timeout
    Given user is blocked after exceeding OTP request attempts
    When UI shows wait message for <waitMinute> minutes
    And user attempts to retry within timeout
    Then access is denied
    When user retries after <waitMinute> minutes
    Then access is restored and blockscreen disappears

    Examples:
      | waitMinute |
      | 10         |

  @performance
  Scenario Outline: Session timer accuracy validated for regulatory compliance
    Given session timer for card details exposure starts at 90 seconds
    When timer counts down uninterrupted in one-second steps
    Then expiry occurs exactly at 0 seconds and session ends
    And timer never overcounts or undercounts

    Examples:
      | duration |
      | 90       |

  # Security Tests: PII Masking and Copy-To-Clipboard Restrictions

  @security
  Scenario Outline: PII masking enforced for all card/phone fields in UI, API, logs
    Given card details or phone number value are present in service responses and logs
    When displaying card or phone fields in UI or exporting logs
    Then only masked values are displayed (e.g., last 4 digits for card, masked phone like '052-6***53')
    And no full values appear in UI, logs, or clipboard export

    Examples:
      | cardNumber     | maskedPhone |
      | 4242           | 052-6***53  |
      | 5678           | 05X-XXXXXX  |

  @security
  Scenario Outline: Card number and suffix display rules enforce masking in UI and copy to clipboard
    Given non-AMEX card details screen is loaded with masked fields
    When viewing or copying card number or suffix
    Then only masked number ('<maskedCard>') and visible suffix ('<suffix>') are present
    And logs and clipboard contain masked format only

    Examples:
      | maskedCard           | suffix |
      | **** **** **** 4242  | 4242   |
      | **** **** **** 1234  | 1234   |

  @security
  Scenario Outline: Masked CVV visible only during permitted session, never present in logs or clipboard post-expiry
    Given CVV field is rendered for a non-AMEX card during session exposure
    When I click 'Show CVV' and copy it to clipboard
    Then only masked CVV value is copied and displayed
    And after session expiry, CVV is removed and no unmasked value is retained anywhere

    Examples:
      | maskedCVV |
      | ***       |
      | 123       |

  @security
  Scenario Outline: Copy card/CVV data to clipboard only when visible in UI
    Given card details or CVV are visible and copy icon is enabled
    When I click the copy icon during exposure
    Then clipboard content matches visible value
    When session expires or details are masked
    Then copy icon is disabled and clipboard is cleared

    Examples:
      | field       | maskedValue         |
      | cardNumber  | **** **** **** 4242 |
      | CVV         | ***                 |

  # State Transition & Functional: CVV Screen Navigation, Explicit Session End, Return Actions

  @ui
  Scenario Outline: CVV screen transition occurs upon 'view CVV' button press from card details
    Given I am on the card details screen (Sc0012/Sc0013) for '<brand>' card
    When I click 'view CVV' button
    Then app transitions to CVV display screen (Sc0014)
    And CVV field is visible and masked as per brand rules
    And timer for CVV display starts if present
    And navigation/history is preserved

    Examples:
      | brand      |
      | MasterCard |
      | VISA       |
      | Amex       |
      | Isracard   |

  @ui
  Scenario Outline: Explicit session end via 'finish' button
    Given I am on card details screen during timer exposure
    When I press the 'finish' button before timer expires
    Then session is immediately ended and I am transitioned to session end screen (Sc0015/Sc0016)
    And backend records session closure
    And I cannot access card details post-session

    Examples:
      | screen         |
      | Sc0012         |
      | Sc0013         |

  @ui
  Scenario: Auto-close session when timer expires
    Given timer has reached zero while viewing card details
    When timer expires without user interaction
    Then session ends automatically and transition to completion screen occurs
    And card details are no longer accessible

  @ui
  Scenario Outline: Explicit user return from any workflow stage resets session and navigation
    Given I am at '<stage>' in the card viewing workflow with return/exit button enabled
    When I click 'Return' or 'Close'
    Then I am returned to the origin screen and session state is reset
    And no sensitive card data remains exposed

    Examples:
      | stage             |
      | pre-view screen   |
      | OTP entry         |
      | card details      |
      | error/completion  |
      | blockscreen       |

  # Decision Table: API Outcome Branches Validate Correct UI

  @api
  Scenario Outline: API response decision table triggers correct UI/error screen and ensures no card detail exposure
    Given API endpoint '/card-account/cards/details' or '/restore-card-information/verify-otp' simulates response HttpStatusCode=<status> with ID=<errorId>
    When user initiates card details retrieval or OTP verification
    Then UI displays '<screen>' as defined by matrix
    And no card detail is exposed in any error branch

    Examples:
      | status | errorId | screen           |
      | 203    | 32      | No Cards screen  |
      | 203    | 31      | No new card      |
      | 204    | null    | No cards found   |

