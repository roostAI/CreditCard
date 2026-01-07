Feature: Secure card details viewing with OTP and external processor integration

  # Notes:
  # - This Feature mixes UI and API scenarios because the requirements cover both end-user flows and backend behaviors.
  # - UI scenarios avoid direct mention of HTTP methods/endpoints; API scenarios include full request/response details.
  # - Text IDs (e.g., 21000–21008) are referenced where relevant; masking and PCI controls are validated across flows.

  # API Tests

  @api @happy_path
  Scenario Outline: API E2E success flow for <brandName> with OTP, processor fetch, and finalize
    Given the API base URL is 'https://<env-host>'
    And the processor API base URL is 'https://<proc-host>'
    And I set request headers:
      | Header                           | Value      |
      | Content-Type                     | application/json |
      | partyAccounts.bankNumber         | <bankNumber>     |
      | partyAccounts.branchNumber       | <branchNumber>   |
      | partyAccounts.accountNumber      | <accountNumber>  |
    When I send a GET request to '/card-channel/web-order/card-account/cards/details?activityTypeCode=902<serialQuery>'
    Then the response status should be 200
    And the response should contain '<brandCode>'
    And the response should mask PAN to last4 only for all cards
    When I send a POST request to '/card-channel/web-order/restore-card-information/orders' with payload:
      """
      {
        "activityTypeCode": 902,
        "cardIssuingSpCode": "SP-<brandName>",
        "creditCardSerialId": "<creditCardSerialId>",
        "cardIdServiceProvider": "<cardIdServiceProvider>",
        "cardSuffix": <cardSuffix>,
        "birthDate": "1990-01-01",
        "brandCode": <brandCode>,
        "smsByVoice": false
      }
      """
    Then the response status should be 200
    And I store 'orderId' as '<orderId>'
    When I send a POST request to '/card-channel/web-order/restore-card-information/verify-otp' with payload:
      """
      {
        "activityTypeCode": 902,
        "cardIssuingSpCode": "SP-<brandName>",
        "otpPassword": "<otp>",
        "orderId": "<orderId>"
      }
      """
    Then the response status should be 200
    And the response should contain '<brandCode>'
    And I store 'OTT' as 'ott-token'
    And I store 'encryptionKey' as 'encKey'
    When I send a GET request to '/PartnerAuthentication.Api/api/GetEncryptedCardData/getEncryptedCardData' on the processor API with header 'authorization'='ott-token'
    Then the response status should be 200
    And the decrypted payload should have PAN length <panLength> and CVV length <cvvLength>
    And the decrypted payload last4 should equal '<cardLast4>'
    When I send a PUT request to '/card-channel/web-order/restore-card-information/<orderId>' with payload:
      """
      { "activityTypeCode": 902 }
      """
    Then the response status should be 200
    And OTT and encryptionKey should be invalidated (subsequent processor call must return 401)

    Examples:
      | env-host     | proc-host  | bankNumber | branchNumber | accountNumber | serialQuery                          | brandName | brandCode | creditCardSerialId | cardIdServiceProvider | cardSuffix | cardLast4 | otp     | orderId       | panLength | cvvLength |
      | api.sbx.bank | proc.sbx   | 12         | 345          | 678901        |                                       | Visa      | 2         | VISA-GOLD-SER      | SP-VISA               | 1445       | 1445      | 470221  | ORD-123       | 16        | 3         |
      | api.sbx.bank | proc.sbx   | 12         | 345          | 678901        | &creditCardSerialId=cardIdHapoalim    | AmEx      | 3         | AMEX-SER           | SP-AMEX               | 8850       | 8850      | 470221  | ORD-AMEX-1    | 15        | 4         |

  @api @otp_errors
  Scenario Outline: OTP business errors and resend pathways
    Given the API base URL is 'https://api.sbx.bank'
    And I set request headers:
      | Header                           | Value      |
      | Content-Type                     | application/json |
      | partyAccounts.bankNumber         | 12         |
      | partyAccounts.branchNumber       | 345        |
      | partyAccounts.accountNumber      | 678901     |
    And I have generated an OTP with orderId '<orderId>' for cardSuffix <cardSuffix> and brandCode <brandCode>
    When I send a <method> request to '<endpoint>' with payload:
      """
      <payload>
      """
    Then the response status should be <status>
    And the response business error id should be '<errorId>'

    Examples:
      | method | endpoint                                                     | payload                                                                                                    | status | errorId | orderId     | cardSuffix | brandCode |
      | POST   | /card-channel/web-order/restore-card-information/verify-otp  | { "activityTypeCode": 902, "otpPassword": "000000", "orderId": "ORD-NEG" }                                 | 203    | 31      | ORD-NEG     | 1445       | 2         |
      | POST   | /card-channel/web-order/restore-card-information/verify-otp  | { "activityTypeCode": 902, "otpPassword": "999999", "orderId": "ORD-NEG" }                                 | 203    | 32      | ORD-NEG     | 1445       | 2         |
      | POST   | /card-channel/web-order/restore-card-information/verify-otp  | { "activityTypeCode": 902, "otpPassword": "123456", "orderId": "ORD-EXPIRED" }                             | 203    | 33      | ORD-EXPIRED | 1445       | 2         |
      | POST   | /card-channel/web-order/restore-card-information/orders       | { "activityTypeCode": 902, "cardSuffix": 1445, "brandCode": 2, "smsByVoice": false }                        | 203    | 31      | N/A         | 1445       | 2         |
      | POST   | /card-channel/web-order/restore-card-information/ORD-VOICE/resend | { "smsByVoice": true }                                                                                     | 203    | 32      | ORD-VOICE   | 1445       | 2         |

  @api @contracts @security
  Scenario Outline: Contract enforcement and security headers
    Given the API base URL is 'https://api.sbx.bank'
    And I set request headers:
      | Header                           | Value      |
      | Content-Type                     | application/json |
      | partyAccounts.bankNumber         | <bankNumber>     |
      | partyAccounts.branchNumber       | <branchNumber>   |
      | partyAccounts.accountNumber      | <accountNumber>  |
    When I send a <method> request to '<endpoint>' with payload:
      """
      <payload>
      """
    Then the response status should be <status>

    Examples:
      | method | endpoint                                                     | payload                                                                                                 | bankNumber | branchNumber | accountNumber | status |
      | GET    | /card-channel/web-order/card-account/cards/details           | {}                                                                                                      | 12         | 345          | 678901        | 200    |
      | GET    | /card-channel/web-order/card-account/cards/details           | {}                                                                                                      | missing    | 345          | 678901        | 403    |
      | POST   | /card-channel/web-order/restore-card-information/verify-otp  | {"otpPassword":"470221","orderId":"ORD-1"}                                                              | 12         | 345          | 678901        | 400    |
      | POST   | /card-channel/web-order/restore-card-information/orders       | {"activityTypeCode":902,"cardSuffix":1445,"brandCode":2,"smsByVoice":false}                            | wrong      | 345          | 678901        | 403    |

  @api @processor_errors
  Scenario Outline: Processor 401, invalid payload, and finalize idempotency
    Given the API base URL is 'https://api.sbx.bank'
    And the processor API base URL is 'https://proc.sbx'
    And I set request headers:
      | Header                           | Value      |
      | Content-Type                     | application/json |
      | partyAccounts.bankNumber         | 12         |
      | partyAccounts.branchNumber       | 345        |
      | partyAccounts.accountNumber      | 678901     |
    And I have a verified-otp context with orderId '<orderId>' and OTT '<ott>' and encryptionKey '<encKey>'
    When I send a GET request to '/PartnerAuthentication.Api/api/GetEncryptedCardData/getEncryptedCardData' on the processor API with header 'authorization'='<ott>'
    Then the response status should be <procStatus>
    And if <procStatus> equals 200 the decrypted payload should be valid JSON else no PAN/CVV should be exposed
    When I send a PUT request to '/card-channel/web-order/restore-card-information/<orderId>' with payload:
      """
      { "activityTypeCode": 902 }
      """
    Then the response status should be 200
    When I send a second PUT request to '/card-channel/web-order/restore-card-information/<orderId>' with the same payload
    Then the response status should be 200
    And the response body state should be 'finalized' (idempotent)

    Examples:
      | orderId     | ott           | encKey        | procStatus |
      | ORD-RB      | ott-expire    | encKey-1      | 401        |
      | ORD-RB-NEW  | ott-bad-json  | encKey-2      | 200        |

  # UI Tests

  @ui @e2e
  Scenario: E2E success from main menu - non-AmEx (Visa) with OTP verify, front/back CVV, manual Finish
    Given I am an authenticated retail customer on the main menu (cards world) with a verified mobile
    And the cards list shows a Visa ending 1445 with last 4 digits only and texts 21000–21004
    When I select Visa ending 1445 and click Continue
    Then I should see pre-view screen Sc0004 with texts 21005–21008 and proper brand images
    When I click 'View card details'
    Then I should see OTP screen Sc0005 with masked phone per text 21050 and a 6-cell numeric-only input
    When I enter a valid 6-digit OTP and click Continue
    Then I should land on front card view Sc0012 with Visa branding, spaced 16-digit number, expiry visible, 'Copy details', timer banner (starting at 90), 'View CVV' and 'Finish' buttons
    When I click 'View CVV'
    Then I should see back view Sc0014 with CVV visible, advisory text 21110, and the timer continuing without reset
    When I go back to card details and click 'Copy details'
    Then the clipboard should contain only PAN and expiry without CVV and no tooltip reveals sensitive data
    When I click 'Finish'
    Then I should see end screen Sc0016 with texts 21150–21152 referencing suffix 1445 and 'Home' navigates back to cards world
    And OTT and decryption keys are cleared and cannot be reused

  @ui @e2e
  Scenario: E2E AmEx flow from post-order lobby with auto-finish on timer expiry
    Given I enter from post-order lobby with creditCardSerialId and see Sc0004 pre-view for AmEx ending 8850
    When I click 'View card details' and complete a valid 6-digit OTP
    Then the app decrypts data and shows Sc0013 AmEx front with PAN 15 digits and 4-digit CVV guidance (21108), timer at 90
    When I navigate to Sc0014 back view and then back to Sc0013 repeatedly
    Then the timer should continue decreasing without reset across screens
    When I let the timer reach zero
    Then the app auto-finalizes and shows end screen Sc0015/Sc0016 with suffix 8850, and secrets are cleared
    And using browser back should require OTP again

  @ui @zero_state
  Scenario Outline: Zero-state gating from different entry sources
    Given I am on the <entry> and initiate 'View card details'
    When the backend returns <status> with business id '<bizId>'
    Then I should see <screen> with proper texts and CTAs
    When I click <cta>
    Then I should navigate to <target>

    Examples:
      | entry            | status | bizId | screen  | cta                | target                   |
      | main menu        | 204    | -     | Sc0001  | Order a new card   | new card order process   |
      | main menu        | 203    | 32    | Sc0001  | Home               | cards world              |
      | post-order lobby | 203    | 31    | Sc0002  | Try again          | Sc0004 pre-view          |

  @ui @otp_validation
  Scenario Outline: OTP input validation, throttling, and recovery
    Given I am on Sc0004 pre-view and start OTP generation successfully
    When I enter '<input>' into the 6-cell OTP input and attempt to Continue
    Then the Continue button should be <continueState> and inline validation should be <validation>
    When I submit with a server condition '<serverCase>'
    Then I should see '<uiResult>' and be able to recover by '<recovery>'

    Examples:
      | input     | continueState | validation         | serverCase                  | uiResult                                   | recovery                     |
      | 12345     | disabled      | none               | none                        | stay on Sc0005                             | type more digits             |
      | 1234567   | enabled       | extra digits trimmed | wrong_code_203_31         | Sc0007 inline error 21055, input cleared   | retype OTP                   |
      | abc123    | disabled      | reject non-numeric | none                        | stay on Sc0005                             | clear and type digits        |
      | 001234    | enabled       | allow leading zero | expired_203_33              | Sc0008 expired state                       | restart flow                 |
      | 123456    | enabled       | valid              | resend_throttle_203_32_sms  | Sc0011/Sc0010 throttling popup, exit flow  | wait window then restart     |
      | N/A       | N/A           | N/A                | no_mobile_203_31_generate   | Sc0009 missing mobile popup, exit flow     | update mobile then restart   |

  @ui @processor_errors
  Scenario Outline: Processor and decrypt error handling, placeholders, multi-tab, and finalize idempotency
    Given I have completed OTP and reached the step before rendering sensitive details
    When '<case>' occurs
    Then the app shows a safe error with no PAN/CVV exposure and navigates to '<fallback>'
    And any OTT/encryption keys are purged and cannot be reused

    Examples:
      | case                               | fallback  |
      | processor_401_expired_ott          | Sc0004    |
      | decryption_failure_invalid_payload | Sc0004    |
      | missing_brand_image_placeholder    | Sc0012    |
      | open_second_tab_gated_view         | Sc0004    |
      | duplicate_finish_clicks            | Sc0016    |
      | refresh_during_timer_requires_otp  | Sc0004    |

  @ui @cache_switch
  Scenario: Card selection cache and switch-after-generate invalidates previous order
    Given I am on Sc0003 with three cards listed for Account A and only last4 is displayed
    When I select MasterCard 1445 and proceed to Sc0004 then start OTP
    Then Sc0005 shows masked phone and order state is tied to the selected card
    When I navigate Back to Sc0003 and select Visa 8850 and start OTP again
    Then a new order replaces the previous one and attempts to verify with the old order are safely rejected
    And switching to Account B shows only its cards and no cached data from Account A

  @ui @timer
  Scenario: Timer robustness with backgrounding, clock skew, and finalize retry on network failure
    Given I am on Sc0012 with timer at 90 seconds
    When I background the app for ~30 seconds and resume
    Then the timer should show ~60 seconds remaining without reset
    When I advance the device clock by +2 minutes
    Then the timer reaches zero and auto-finalize is attempted once
    When the first finalize attempt times out and the second succeeds
    Then Sc0016 end screen is shown and no sensitive nodes remain in the DOM
    And navigating Back cannot re-expose details

  @ui @provenance
  Scenario Outline: Data provenance and brand/PAN/CVV length enforcement
    Given I completed OTP for <brandName> and the app decrypted processor payload
    When the payload contains '<payloadCase>'
    Then the app should '<uiOutcome>' and never render partial digits
    And clipboard, logs, and telemetry must contain no PAN/CVV

    Examples:
      | brandName | payloadCase                     | uiOutcome                           |
      | Visa      | matching_last4_and_lengths      | render Sc0012 and allow Copy (no CVV) |
      | Visa      | last4_mismatch                  | show safe error and return to Sc0004 |
      | Visa      | brand_mismatch_15_digit_pan     | show safe error and return to Sc0004 |
      | AmEx      | valid_15_pan_4_cvv              | render Sc0013 and allow View back CVV |
      | AmEx      | invalid_3_digit_cvv             | show safe error and return to Sc0004 |
      | Unknown   | 16_pan_3_cvv_default_rule       | render Sc0012 with placeholder brand |

  @ui @service_errors
  Scenario Outline: Service error robustness and contract failures across stages
    Given I am progressing through the flow from list to finalize
    When the backend at stage '<stage>' returns '<error>'
    Then the UI shows a safe error state and offers appropriate retry or exit
    And no sensitive data is displayed and no duplicate finalize after success

    Examples:
      | stage           | error            |
      | cards_list      | 500              |
      | generate_otp    | 504_timeout      |
      | verify_otp      | 502_bad_gateway  |
      | processor_fetch | invalid_json     |
      | processor_fetch | 500              |
      | finalize        | 500_then_200     |
      | any_stage       | 400_missing_activityTypeCode |
      | any_stage       | 401_403_header_mismatch     |

  @ui @concurrency
  Scenario: OTP concurrency across tabs shares attempts and gates after verify
    Given I started OTP in Tab A and Tab B for the same order
    When I submit wrong codes and perform resend actions across both tabs
    Then attempt counters and resend throttling are shared
    When Tab A verifies successfully and proceeds to details
    Then Tab B is gated from further resends or verify and requires restart
    And after finalize, the order cannot be reused from either tab

  @ui @session_expiry
  Scenario: Session expiry during sensitive view hides data and attempts finalize once
    Given I am viewing Sc0012 with ~70 seconds remaining
    When my session expires or I log out
    Then the sensitive view disappears immediately and a single finalize attempt is made
    And I am redirected to login and must restart with a new order after re-login

  @ui @a11y @rtl
  Scenario: RTL localization and accessibility hardening without exposing digits
    Given my browser language is Hebrew (RTL) and a screen reader is active
    When I navigate Sc0003 → Sc0004 → Sc0005 with keyboard only
    Then texts 21000–21008 are correctly RTL aligned, focus order is logical, and images have alt text
    When I enter OTP and proceed to Sc0012
    Then timer announcements are polite, PAN/CVV nodes are aria-hidden, and 'Copy details' has an accessible name without reading digits
    When I view CVV on Sc0014 and finish
    Then end screen controls have clear accessible names and no digits appear in the accessibility tree

  @ui @brand_fallback
  Scenario: Unknown brandCode uses placeholder and default non-AmEx rules
    Given I select a card with unknown brandCode and complete OTP
    When details are shown
    Then Sc0012 renders with a placeholder brand image, 16-digit PAN, 3-digit CVV via 'View CVV', and timer at 90
    And finalize succeeds and secrets are invalidated

  @ui @duplicates
  Scenario: Duplicate last-4 across cards does not cause cross-card leakage
    Given the list shows two cards with last4 4455 of different brands
    When I complete the flow for the Visa card and finish
    Then the end screen references the Visa suffix 4455
    When I complete the flow for the Isracard with suffix 4455
    Then details and clipboard reflect only the Isracard data and OTTs are not interchangeable

  @ui @account_scope
  Scenario: Account header switch mid-flow enforces strict scoping
    Given I start OTP in Account A
    When I switch to Account B before verify
    Then verify is blocked with a safe error and I must restart under Account B
    When I verify in Account B and switch back to Account A before finalize
    Then finalize is blocked until I return to Account B where it succeeds
    And no sensitive data is exposed during mismatches

  @ui @debounce
  Scenario: Debounce and throttling on initial OTP generation with lockout popup
    Given I am on Sc0004 pre-view with a selected card
    When I double-click 'View card details' rapidly
    Then only a single OTP generation occurs and I see Sc0005 once
    When I abuse the button repeatedly thereafter
    Then I see a throttling popup (Sc0010) with a 10-minute wait and no further requests are sent
    When the wait elapses and I try again
    Then a fresh order is issued and previous ones are not reused

  @ui @offline
  Scenario: Offline resilience before verify and during processor fetch with safe recovery
    Given I am on Sc0005 with masked phone
    When I go offline and submit a valid OTP
    Then I see a safe offline banner and can retry after reconnect
    When I reconnect and succeed verify, then go offline before processor fetch
    Then the app shows a safe error and returns to Sc0004 requiring a fresh OTP
    And old secrets are purged and cannot be reused

  @ui @nostore
  Scenario: No-store and browser history protections including print attempts
    Given I am viewing Sc0012 and the timer is active
    When I inspect caching policies
    Then sensitive routes use no-store and are not cached by service worker
    When I navigate Back and Forward or refresh
    Then Sc0012 is not restored and OTP is required again unless finalized
    When I trigger print while on Sc0012 and let the timer expire
    Then the view is finalized and print content does not expose PAN/CVV

  @ui @clipboard
  Scenario: Clipboard permission denied and sanitized copy behavior
    Given I am on Sc0012 with PAN and expiry visible and CVV hidden
    When I click 'Copy details' with clipboard permission denied
    Then I see a non-sensitive failure message and no digits are shown
    When I grant permission and copy again
    Then the clipboard contains only PAN and expiry, never CVV
    When I finish or the timer expires
    Then the clipboard is cleared or scrubbed per policy

  @ui @mobile
  Scenario: Mobile rotation preserves OTP and timer continuity
    Given I am on a mobile device at Sc0005 with 6 OTP cells
    When I enter three digits and rotate to landscape
    Then digits persist and focus remains correct with numeric-only input enforced
    When I complete OTP and reach Sc0012 then rotate repeatedly
    Then the timer continues without reset and no duplicate network calls occur
    When I view CVV and rotate back and forth
    Then timer remains consistent and Finish completes safely

  @ui @deeplink
  Scenario: Route and deep-link hardening blocks direct access to sensitive screens
    Given I have no active OTP/order context
    When I open a deep link to a sensitive view (Sc0012/Sc0013/Sc0014)
    Then no processor call is made and I am redirected to Sc0003 or Sc0004
    When I append a stale OTT in the URL or local state
    Then it is ignored and access remains gated
    And only a legitimate OTP flow can render details

  @ui @intl_phone
  Scenario: International phone handling and mid-flow phone update with resend
    Given I started OTP with a domestic masked phone and both SMS/Voice options are available
    When I update my registered mobile in a separate profile flow to an international number and resend by SMS
    Then the masked phone updates to the international format and Voice is disabled or safely blocked
    When I enter the OTP sent to the international number and proceed to details
    Then the flow succeeds and finalize completes without PII leakage

  @ui @otp_input
  Scenario: OTP input robustness with non-ASCII numerals, separators, auto-fill, and paste sanitization
    Given I am on Sc0005 with 6 OTP cells and Continue is disabled
    When I type Arabic-Indic or full-width digits
    Then the input rejects them and Continue remains disabled
    When I paste '12 34- 56'
    Then only ASCII digits are accepted and cells fill as '123456' and Continue enables
    When I trigger mobile auto-fill
    Then cells populate without logging the OTP and submission is allowed
    When I submit a wrong code then a correct code
    Then I see inline error (21055) then proceed to details (which I exit immediately to avoid exposure)

  @ui @performance
  Scenario: Large portfolio performance and selection gating on Sc0003
    Given the list contains 28 masked cards across brands with proper images or placeholders
    When I scroll rapidly and attempt to click Continue without selecting
    Then rendering remains smooth, no extra network calls are made, and Continue stays disabled
    When I select a card and navigate Back and forth
    Then selection is preserved and accessible names do not expose PAN

  @ui @payload_completeness
  Scenario: Processor payload completeness checks block rendering on missing fields
    Given I completed OTP for Visa and the processor payload omits expiry
    When the app validates the payload
    Then no details are rendered, a safe error is shown, and I return to Sc0004 with secrets purged
    When I retry with AmEx and the payload omits CVV
    Then the app blocks Sc0013 and returns to Sc0004 safely
    When I retry with complete payloads
    Then details render and finalize succeeds with end screen texts displayed
