Feature: Promotional Ticker - UI and API Testing

  Background:
    # API common setup
    Given the API base URL is set from environment variable 'BASE_URL'
    And the authorization header is set with token from 'AUTH_TOKEN'
    And the content type is 'application/json'

    # UI common setup
    And the browser is launched
    And I am logged in as a valid user
    And I navigate to the video player page
    And the video player is active and playing
    And the device orientation is set to landscape
    And the moderator console is available

  # ----------------------------------------
  # API Tests
  # ----------------------------------------

  @API
  Scenario: Create ticker with sponsor (happy path)
    Given I set the authorization header with token from 'MODERATOR_TOKEN'
    And the request body:
      '''
      {
        "hostNickname": "HostTwo",
        "hostTag": "Host",
        "text": "Limited time offer",
        "sponsorshipSuffix": "Sponsored by ACME",
        "maxDisplayTimeSec": 30,
        "orientation": "landscape"
      }
      '''
    When I send a POST request to '/api/tickers'
    Then the response status should be 201
    And the response body should contain 'id' field
    And the response body 'sponsorshipSuffix' should be 'Sponsored by ACME'
    And the response body 'display.hasSponsor' should be true
    And the response body 'display.nicknameTruncated' should be 'HostTwo'
    And the response body 'display.textTruncated' should be 'Limited time offer'

  @API
  Scenario: Create ticker without sponsor (no yellow dot downstream)
    Given I set the authorization header with token from 'MODERATOR_TOKEN'
    And the request body:
      '''
      {
        "hostNickname": "HostOne",
        "hostTag": "Host",
        "text": "Big sale today",
        "maxDisplayTimeSec": 30,
        "orientation": "landscape"
      }
      '''
    When I send a POST request to '/api/tickers'
    Then the response status should be 201
    And the response body 'sponsorshipSuffix' should be null
    And the response body 'display.hasSponsor' should be false

  @API
  Scenario: Create ticker with 100-character text boundary
    Given I set the authorization header with token from 'MODERATOR_TOKEN'
    And the request body:
      '''
      {
        "hostNickname": "Host100",
        "hostTag": "Host",
        "text": "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890",
        "maxDisplayTimeSec": 30,
        "orientation": "landscape"
      }
      '''
    When I send a POST request to '/api/tickers'
    Then the response status should be 201
    And the response body 'display.textTruncated' should have length 100
    And the response body 'display.textTruncated' should equal the request body 'text'

  @API
  Scenario: Create ticker with text exceeding 100 characters is truncated in display metadata
    Given I set the authorization header with token from 'MODERATOR_TOKEN'
    And the request body:
      '''
      {
        "hostNickname": "HostOver",
        "hostTag": "Host",
        "text": "12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890",
        "maxDisplayTimeSec": 30,
        "orientation": "landscape"
      }
      '''
    When I send a POST request to '/api/tickers'
    Then the response status should be 201
    And the response body 'text' should have length 110
    And the response body 'display.textTruncated' should have length 100
    And the response body 'display.textTruncated' should equal the first 100 characters of the request body 'text'

  @API
  Scenario: Host nickname longer than 10 characters is truncated in display metadata
    Given I set the authorization header with token from 'MODERATOR_TOKEN'
    And the request body:
      '''
      {
        "hostNickname": "SuperLongHostName",
        "hostTag": "Host",
        "text": "Deal",
        "maxDisplayTimeSec": 30,
        "orientation": "landscape"
      }
      '''
    When I send a POST request to '/api/tickers'
    Then the response status should be 201
    And the response body 'hostNickname' should equal 'SuperLongHostName'
    And the response body 'display.nicknameTruncated' should have length 10
    And the response body 'display.nicknameTruncated' should equal 'SuperLongH'

  @API
  Scenario: Retrieve current ticker for user in landscape
    Given I set the authorization header with token from 'USER_TOKEN'
    When I send a GET request to '/api/tickers/current?orientation=landscape'
    Then the response status should be 200
    And the response body should contain 'id', 'display', 'remainingTimeSec', and 'loopsAllowed' fields
    And the response body 'display.hasSponsor' should be a boolean
    And the response body 'display.showYellowDot' should equal the response body 'display.hasSponsor'

  @API
  Scenario: Update ticker to add sponsor suffix
    Given I set the authorization header with token from 'MODERATOR_TOKEN'
    And the request body:
      '''
      {
        "sponsorshipSuffix": "Sponsored by ACME"
      }
      '''
    When I send a PATCH request to '/api/tickers/tk_update_1'
    Then the response status should be 200
    And the response body 'sponsorshipSuffix' should be 'Sponsored by ACME'
    And the response body 'display.hasSponsor' should be true

  @API
  Scenario: Delete ticker by id
    Given I set the authorization header with token from 'MODERATOR_TOKEN'
    When I send a DELETE request to '/api/tickers/tk_delete_1'
    Then the response status should be 204
    When I send a GET request to '/api/tickers/tk_delete_1'
    Then the response status should be 404

  @API
  Scenario: Unauthorized create when no token provided
    Given I clear the authorization header
    And the request body:
      '''
      {
        "hostNickname": "HostX",
        "hostTag": "Host",
        "text": "Hello",
        "maxDisplayTimeSec": 30,
        "orientation": "landscape"
      }
      '''
    When I send a POST request to '/api/tickers'
    Then the response status should be 401

  @API
  Scenario: Forbidden create when authenticated user is not a moderator
    Given I set the authorization header with token from 'USER_TOKEN'
    And the request body:
      '''
      {
        "hostNickname": "HostY",
        "hostTag": "Host",
        "text": "Hi",
        "maxDisplayTimeSec": 30,
        "orientation": "landscape"
      }
      '''
    When I send a POST request to '/api/tickers'
    Then the response status should be 403

  @API
  Scenario: Get current ticker when none is active
    Given I set the authorization header with token from 'USER_TOKEN'
    When I send a GET request to '/api/tickers/current?orientation=landscape'
    Then the response status should be 204

  @API
  Scenario: Remaining time under minimum threshold is marked skippable
    Given I set the authorization header with token from 'USER_TOKEN'
    When I send a GET request to '/api/tickers/current?orientation=landscape'
    Then the response status should be 200
    And the response body 'remainingTimeSec' should be less than 1
    And the response body 'skippable' should be true

  @API
  Scenario: Analytics event accepted with idempotency support
    Given I set the authorization header with token from 'USER_TOKEN'
    And the request body:
      '''
      {
        "eventName": "ticker_shown",
        "tickerId": "tk_123",
        "timestamp": "2025-11-27T12:00:00Z",
        "metadata": {
          "host": "HostTwo",
          "textLength": 17,
          "hasSponsor": true
        },
        "idempotencyKey": "c1f2e3a4-b5d6-47aa-8899-1234567890ab"
      }
      '''
    When I send a POST request to '/api/analytics/events'
    Then the response status should be 201
    And the response body should contain 'eventId' field
    When I send the same POST request again to '/api/analytics/events'
    Then the response status should be 200
    And the response header 'Idempotent-Replay' should be 'true'

  @API
  Scenario: Analytics event validation error on missing fields
    Given I set the authorization header with token from 'USER_TOKEN'
    And the request body:
      '''
      {
        "eventName": "ticker_cta_clicked",
        "metadata": { "source": "ticker" }
      }
      '''
    When I send a POST request to '/api/analytics/events'
    Then the response status should be 400
    And the response body 'errors' should contain 'tickerId' and 'timestamp'

  @API
  Scenario: Create ticker with RTL content produces correct display metadata
    Given I set the authorization header with token from 'MODERATOR_TOKEN'
    And the request body:
      '''
      {
        "hostNickname": "مضيفطويلجدا",
        "hostTag": "Host",
        "text": "عرض مميز اليوم",
        "sponsorshipSuffix": "برعاية الشركة",
        "maxDisplayTimeSec": 30,
        "orientation": "landscape"
      }
      '''
    When I send a POST request to '/api/tickers'
    Then the response status should be 201
    And the response body 'display.nicknameTruncated' should have length 10
    And the response body 'display.hasSponsor' should be true

  @API
  Scenario: Rate limiting on create ticker
    Given I set the authorization header with token from 'MODERATOR_TOKEN'
    And I have sent 10 POST requests to '/api/tickers' within '1 minute'
    And the request body:
      '''
      {
        "hostNickname": "HostRL",
        "hostTag": "Host",
        "text": "Promo",
        "maxDisplayTimeSec": 30,
        "orientation": "landscape"
      }
      '''
    When I send a POST request to '/api/tickers'
    Then the response status should be 429

  @API
  Scenario: Retrieve ticker by id returns full structure
    Given I set the authorization header with token from 'USER_TOKEN'
    When I send a GET request to '/api/tickers/tk_123'
    Then the response status should be 200
    And the response body should contain 'id', 'hostNickname', 'hostTag', 'text', 'sponsorshipSuffix', 'maxDisplayTimeSec', 'orientation', 'status', 'publishedAt', and 'display'

  @API
  Scenario: Validate maxDisplayTimeSec boundary
    Given I set the authorization header with token from 'MODERATOR_TOKEN'
    And the request body:
      '''
      {
        "hostNickname": "HostTime",
        "hostTag": "Host",
        "text": "Short time",
        "maxDisplayTimeSec": 0,
        "orientation": "landscape"
      }
      '''
    When I send a POST request to '/api/tickers'
    Then the response status should be 400
    And the response body 'errors.maxDisplayTimeSec' should contain 'must be >= 1'

  @API
  Scenario: User cannot delete ticker
    Given I set the authorization header with token from 'USER_TOKEN'
    When I send a DELETE request to '/api/tickers/tk_no_delete'
    Then the response status should be 403

  # ----------------------------------------
  # UI Tests
  # ----------------------------------------

  @UI @TC-001
  Scenario: Display ticker without sponsor in landscape
    Given a moderator has published a promotional ticker with hostNickname 'HostOne', hostTag 'Host', text 'Big sale today', no sponsorship suffix, and max display time 30 seconds
    And I confirm the device is in landscape orientation
    When the ticker animation starts
    Then I should see the Intro
    And I should see the host nickname 'HostOne' and tag 'Host'
    And I should see the quoted text "Big sale today"
    And I should not see a yellow dot separator
    And I should not see any sponsor suffix
    And the full sequence should repeat exactly one more time
    And I should then see the Outro and the ticker should hide
    And the ticker should not terminate early

  @UI @TC-002
  Scenario: Display ticker with sponsor and yellow dot
    Given a moderator has published a ticker with hostNickname 'HostTwo', hostTag 'Host', text 'Limited time offer', sponsorship suffix 'Sponsored by ACME', and max display time 30 seconds
    When the ticker animation plays
    Then I should see the Intro
    And I should see the host nickname 'HostTwo' and tag 'Host'
    And I should see the quoted text "Limited time offer"
    And I should see a yellow dot separator
    And I should see the sponsor suffix 'Sponsored by ACME'
    And the full sequence should repeat once
    And I should then see the Outro

  @UI @TC-003
  Scenario: Host nickname truncation to 10 characters
    Given a moderator has published a ticker with hostNickname 'SuperLongHostName', hostTag 'Host', text 'Deal', and max display time 30 seconds
    When the host segment appears
    Then the displayed host nickname should be truncated to 'SuperLongH'
    And the host tag 'Host' should remain visible and aligned
    And there should be no layout overlap

  @UI @TC-004
  Scenario: Text length at 100 characters boundary
    Given a moderator has published a ticker with hostNickname 'Host100', hostTag 'Host', a text of exactly 100 characters, and max display time 30 seconds
    When the text segment appears
    Then the entire text should be displayed inside quotes without clipping
    And the text should wrap as per design without overflow

  @UI @TC-005
  Scenario: Text length exceeding 100 characters is truncated
    Given a moderator has published a ticker with a text of 120 characters and max display time 30 seconds
    When the text segment appears
    Then only the first 100 characters should be displayed inside quotes
    And there should be no layout issues or errors

  @UI @TC-006
  Scenario: End by max display time before two loops complete
    Given a moderator has published a ticker with normal content and a short max display time of 3 seconds
    When I measure from the first visible frame
    Then the ticker should end due to reaching max display time before two loops complete
    And the Outro should play immediately and the ticker should hide

  @UI @TC-007
  Scenario: End after exactly two loops
    Given a moderator has published a ticker with max display time 60 seconds and normal content
    When I observe the animation loops
    Then exactly two complete loops should play
    And no third loop should start
    And the Outro should follow

  @UI @TC-008
  Scenario: Skip when less than 1 second remaining
    Given a moderator has published a ticker with max display time 5 seconds
    And 4.2 seconds have elapsed since publish
    When I rotate the device to landscape with approximately 0.8 seconds remaining
    Then the ticker should not appear because remaining time is under 1 second

  @UI @TC-009
  Scenario: Show when exactly 1 second remaining
    Given a moderator has published a ticker with max display time 5 seconds
    And approximately 4.0 seconds have elapsed
    When I rotate the device to landscape
    Then the ticker should appear and remain visible for at least 1 second
    And the Outro should play gracefully as time expires

  @UI @TC-010
  Scenario: CTA tap transitions to portrait with FZ open
    Given a ticker with a visible CTA is currently displayed
    When I tap the CTA once
    Then the app should transition to portrait orientation
    And the FZ should open
    And the ticker should no longer be visible

  @UI @TC-011
  Scenario: Dismiss tap hides ticker for current instance
    Given a ticker is visible and the dismiss control is present
    When I tap the dismiss control
    Then the ticker should hide immediately
    And the ticker should not reappear during its remaining time window

  @UI @TC-012
  Scenario: Hide on player controls show; reappear after controls fade (time remains)
    Given a ticker is visible and player controls are set to auto-fade after approximately 3 seconds
    When I tap the video to show player controls
    Then the ticker should hide while controls are visible
    When I allow the controls to auto-fade without interaction
    Then the ticker should reappear if its time window has not expired

  @UI @TC-013
  Scenario: Hide on player controls show; no reappear if time expired
    Given a ticker is visible with approximately 2 seconds remaining and controls auto-fade in about 3 seconds
    When I tap to show player controls
    And I wait for the controls to auto-fade
    Then the ticker should not reappear because its allowed display time expired

  @UI @TC-014
  Scenario: Orientation change pauses visibility
    Given a ticker is visible with at least 5 seconds remaining
    When I rotate the device to portrait
    Then the ticker should hide immediately
    When I rotate back to landscape within the remaining time window
    Then the ticker should reappear

  @UI @TC-015
  Scenario: Quoted text formatting
    Given tickers are published with various text inputs
    When I view a ticker with text 'Weekend deals'
    Then I should see the text displayed as "Weekend deals"
    When I view a ticker with text containing inner quotes 'Save on "gadgets" now'
    Then I should see the text displayed with outer quotes preserved and layout intact
    When I view a ticker with emojis and punctuation
    Then the text should remain enclosed within display quotes without layout breakage

  @UI @TC-016
  Scenario: Right-to-left (RTL) text and sponsor display
    Given a ticker is published with hostNickname 'مضيفطويلجدا', hostTag 'Host', text 'عرض مميز اليوم', sponsorship suffix 'برعاية الشركة', and max display time 30 seconds
    When the host name is displayed
    Then the nickname should be truncated to 10 RTL characters
    And the text should appear quoted with correct RTL directionality
    And the yellow dot and sponsor should appear in proper RTL order and alignment

  @UI @TC-017
  Scenario: Rapid taps showing/hiding controls do not glitch ticker
    Given a ticker is visible and player controls auto-fade is enabled
    When I tap the player area every 0.8 seconds for 10 seconds
    Then the ticker should hide only while controls are visible
    And the ticker should reappear reliably after controls fade if time remains
    And there should be no visual tearing or stuck states

  @UI @TC-018
  Scenario: Publish while already in landscape starts immediately
    Given I am in landscape and no ticker is currently visible
    When the moderator publishes a new ticker
    Then the ticker animation should start immediately subject to network and processing latency

  @UI @TC-019
  Scenario: No yellow dot when sponsor is absent
    Given a ticker is published without a sponsorship suffix
    When the text segment transitions to the next element
    Then I should not see a yellow dot anywhere in the sequence

  @UI @TC-020
  Scenario: Telemetry/analytics events for ticker lifecycle
    Given analytics logging is enabled and a ticker is published
    When I let the ticker complete two loops without interaction
    Then I should see analytics events 'ticker_shown' and 'ticker_completed' logged once each with correct metadata
    When I publish a new ticker and tap dismiss
    Then I should see 'ticker_shown' and 'ticker_dismissed' logged once each with correct metadata
    When I publish a new ticker and tap the CTA
    Then I should see 'ticker_shown' and 'ticker_cta_clicked' and a navigation event logged with correct metadata

  @UI @TC-021
  Scenario: Animation performance (FPS and jank)
    Given a ticker with max display time at least 20 seconds is running
    When I record FPS and dropped frames throughout two loops
    Then the average FPS should be at least 55
    And the 95th percentile frame time should be at most 20 ms
    And dropped frames should be at most 1% of total
    And there should be no visible stutter

  @UI @TC-022
  Scenario: Memory stability under repeated cycles
    Given automation is available to publish and expire tickers
    When I run 100 cycles of ticker display from publish to completion
    Then the peak memory increase should be at most 30 MB during animation
    And the post-test heap should return within 5 MB of baseline
    And there should be no retained ticker views or listeners

  @UI @TC-023
  Scenario: Touch responsiveness
    Given a ticker is visible with CTA and dismiss controls
    When I tap the CTA
    Then the time to navigation start should be at most 150 ms
    When I tap the dismiss control
    Then the time to ticker disappearance should be at most 100 ms

  @UI @TC-024
  Scenario: Accessibility - screen reader support
    Given VoiceOver or TalkBack is enabled and a ticker is visible
    When I swipe through accessibility elements
    Then the ticker region should be announced as a single concise announcement including host, tag, text, and sponsor if present
    And CTA and dismiss should be labeled and actionable
    And focus should not be trapped

  @UI @TC-025
  Scenario: Accessibility - color contrast and size
    Given I have the design specs and a WCAG contrast checker
    When I measure the contrast ratio of ticker text versus background and the visibility of the yellow dot
    And I measure CTA and dismiss touch targets
    And I test with dynamic text sizes enabled
    Then the contrast ratio should be at least 4.5:1 for text
    And touch targets should be at least 44x44 pt on iOS or 48x48 dp on Android
    And the layout should remain usable with large text

  @UI @TC-026
  Scenario: Battery impact during prolonged usage
    Given a controlled device environment with stable brightness and network conditions
    When I run a 30-minute session with tickers appearing every 60 seconds
    And I compare it to a 30-minute baseline session without tickers
    Then the additional power drain should be at most 10% over baseline on mid-tier hardware
    And no thermal throttling should be triggered

  @UI @TC-027
  Scenario: Network resiliency and offline behavior
    Given a ticker is running
    When I toggle the network to offline
    Then the current ticker should continue and end normally
    When I attempt to publish a new ticker while offline
    Then the app should handle it gracefully with user-safe messaging or logs
    And the app should not crash

  @UI @TC-028
  Scenario: Layout across devices and safe areas
    Given a device matrix including small phones, large phones, and tablets with notches and rounded corners
    When I display a ticker in landscape on each device type
    Then there should be no clipping or overlap
    And elements should remain within safe areas
    And truncation rules should hold
    And visuals should match the design

  @UI @TC-029
  Scenario: Stability under rapid state changes
    Given a ticker is visible
    When I rapidly rotate the device between landscape and portrait 10 times and intermittently show/hide controls
    And I repeat the sequence across two tickers
    Then there should be no crashes or ANRs
    And ticker visibility rules should remain consistent
    And the app state should recover cleanly

  @API @TC-030
  Scenario: Event logging integrity via analytics API
    Given I set the authorization header with token from 'USER_TOKEN'
    And I publish and interact with a ticker to generate 'ticker_shown', 'ticker_dismissed', 'ticker_cta_clicked', and 'ticker_completed'
    When I query the analytics sink for events correlated by 'tickerId' 'tk_123'
    Then I should find exactly one log per action with ordered timestamps
    And all events should share a valid correlation ID
    And there should be no duplicates even if the app was backgrounded and foregrounded during the ticker
