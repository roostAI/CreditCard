Feature: Promotional Ticker experience in landscape player

  # UI Tests
  @ui @tc-001 @tc-002 @tc-013
  Scenario Outline: Render and animate ticker with optional sponsorship suffix and correct looping
    Given I am watching a video in landscape with player controls hidden and connected to moderator messages
    And a moderator publishes a ticker with text "<text>", host nickname "<hostNickname>", host tag present, sponsorship suffix "<suffix>", and max display time <maxTime> seconds
    When the ticker intro animation starts
    Then I should see the sequence in order for each loop:
      | step | content                                                                  |
      | 1    | Host nickname (truncated to 10 chars if needed) + host tag               |
      | 2    | "<text>" (enclosed in quotes in the UI)                                  |
      | 3    | Yellow dot separator (visible only if sponsorship suffix is not empty)   |
      | 4    | Sponsorship suffix (visible only if not empty)                           |
    And all elements should be visually distinct and readable
    And the sequence should repeat exactly two times followed by an outro animation
    And the yellow dot visibility should be <dotExpected>
    And the ticker should hide before or at <maxTime> seconds according to the 2-loops-or-time rule

    Examples:
      | text                     | hostNickname | suffix               | maxTime | dotExpected |
      | Flash sale today only    | Alex         | Sponsored by ACME    | 20      | visible     |
      | Welcome to the show      | Sam          |                      | 20      | hidden      |

  @ui @tc-003
  Scenario: End animation early due to max display time cap
    Given I am watching a video in landscape with player controls hidden and connected to moderator messages
    And a moderator publishes a ticker with text "Limited", host nickname "Ava", host tag present, sponsorship suffix "BrandX", and max display time 3 seconds
    When the intro animation begins and I start a timer
    Then the ticker should end (outro or immediate removal per design) when the timer reaches 3 seconds even if the first loop has not completed

  @ui @tc-004
  Scenario: Minimum display time threshold skip when remaining time < 1s
    Given the user is in portrait and a moderator publishes a ticker with max display time 3 seconds
    And 2.2 seconds have elapsed since publish
    When I rotate the device to landscape
    Then the ticker should not appear because the remaining time is less than 1 second

  @ui @tc-005
  Scenario Outline: Host nickname truncation to 10 visible characters without breaking grapheme clusters
    Given I am watching a video in landscape with player controls hidden and connected to moderator messages
    And a moderator publishes a ticker with host nickname "<inputNickname>", host tag present, text "Any text", and max display time 20 seconds
    When the ticker displays the host nickname
    Then the host nickname should be rendered as "<expectedDisplay>" without broken glyphs or split emojis

    Examples:
      | inputNickname  | expectedDisplay |
      | Christopher    | Christophe      |
      | Alex😀😀Test     | Alex😀😀Test      |

  @ui @tc-006
  Scenario: Quoted text rendering with embedded quotes
    Given I am watching a video in landscape with player controls hidden and connected to moderator messages
    And a moderator publishes a ticker with text "He said, \"Go!\"" and no sponsorship suffix
    When the ticker displays the text portion
    Then the UI should show the text surrounded by quotes, preserving and escaping embedded quotes, and no layout overflow or clipping should occur

  @ui @tc-007
  Scenario: CTA tap transitions to portrait with FZ open and hides ticker
    Given a ticker with a CTA is visible in landscape
    When I tap the CTA
    Then the app should transition to portrait orientation
    And the FZ view should open
    And the ticker should be dismissed and not overlay the FZ

  @ui @tc-008
  Scenario: Dismiss tap hides ticker for current session and prevents reappearance
    Given a ticker is visible in landscape
    When I tap the Dismiss control
    Then the ticker should hide immediately
    And it should not reappear even if time remains within the same publication window
    And if a new ticker is published later, only the new ticker is allowed to show

  @ui @tc-009 @tc-010
  Scenario Outline: Hide when player controls appear and conditional reappearance after fade
    Given a ticker is visible with <remainingBeforeControls>s remaining and player controls are currently hidden
    When I tap the player area to reveal controls (controls fade after <controlsFade>s)
    Then the ticker should hide immediately
    And after controls fade, the ticker should <reappearOutcome>

    Examples:
      | remainingBeforeControls | controlsFade | reappearOutcome      |
      | 5                       | 3            | reappear and continue |
      | 2                       | 3            | remain hidden         |

  @ui @tc-011
  Scenario: Show ticker upon entering landscape within time
    Given a moderator publishes a ticker with max display time 10 seconds while I am in portrait
    And 3 seconds after publish I rotate to landscape
    When the ticker intro starts
    Then the ticker should appear and animate
    And it should end after two loops or when max display time is reached, whichever comes first

  @ui @tc-012
  Scenario: Exactly two loops when time is ample
    Given I am watching in landscape and a moderator publishes a ticker with max display time 60 seconds
    When the ticker animates
    Then the sequence should play exactly two loops and then the outro
    And the ticker should hide immediately after the second loop even though time remains

  @ui @tc-014
  Scenario: Text length boundary at exactly 100 characters
    Given I am watching a video in landscape with player controls hidden and connected to moderator messages
    And a moderator publishes a ticker with a 100-character text string and no sponsorship suffix
    When the ticker renders the text portion
    Then all 100 characters should be visible inside quotes without truncation or UI overflow

  @ui @tc-016
  Scenario: Newest ticker replaces currently visible ticker
    Given a ticker A is visible in landscape with at least 5 seconds remaining
    When a moderator publishes a new ticker B
    Then ticker A should stop immediately (or transition out per design) and ticker B should start with its intro
    And ticker B should follow standard loop and time rules independently of ticker A

  @ui @tc-017
  Scenario Outline: Behavior across app background and foreground
    Given a ticker is visible in landscape with <remainingTime>s remaining
    When I send the app to background for <backgroundDuration>s and then resume to foreground
    Then the ticker should <reappearOutcome> based on remaining time at resume

    Examples:
      | remainingTime | backgroundDuration | reappearOutcome      |
      | 5             | 2                  | reappear and continue |
      | 5             | 6                  | remain hidden         |

  @ui @tc-018
  Scenario: Analytics events emitted for ticker lifecycle (client verification)
    Given analytics logging is enabled and a ticker is made visible
    When the first visible frame appears
    Then a "ticker_impression" event should be logged with tickerId and timestamp
    When I tap Dismiss
    Then a "ticker_dismiss" event should be logged with tickerId and user_action=true
    When another ticker is shown and I tap the CTA
    Then a "ticker_cta" event should be logged with tickerId and destination="FZ"
    When a ticker ends by time or loops
    Then a "ticker_end" event should be logged with reason in {"time","loops"}

  # API Tests (inferred for meaningful coverage: server validation and analytics telemetry)
  @api @validation @tc-015
  Scenario Outline: Publish promotional ticker server-side validation
    Given the API base URL is "<base_url>"
    And the authorization header "Bearer <token>" is set
    And the Content-Type is "application/json"
    When I send a POST request to "/api/tickers" with JSON payload
      '''
      {
        "text": "<text>",
        "sponsorshipSuffix": "<suffix>",
        "maxDisplayTimeSec": <maxDisplayTimeSec>,
        "hostNickname": "<hostNickname>",
        "hostTag": true
      }
      '''
    Then the response status should be <expectedStatus>
    And the response JSON should <responseExpectation>

    Examples:
      | base_url             | token   | text                              | suffix               | maxDisplayTimeSec | hostNickname | expectedStatus | responseExpectation                          |
      | https://api.example  | abc123  | <100-char-string>                 | Sponsored by ACME    | 20                | Alex         | 202            | contain field "tickerId"                      |
      | https://api.example  | abc123  | <101-char-string>                 |                      | 20                | Sam          | 400            | contain field "error.code" = "TEXT_TOO_LONG"  |
      | https://api.example  | abc123  | Deal time!                        |                      | 0                 | Sam          | 400            | contain field "error.code" = "INVALID_TIME"   |
      | https://api.example  | abc123  |                                   |                      | 20                | Sam          | 400            | contain field "error.code" = "TEXT_REQUIRED"  |

  @api @telemetry @tc-018
  Scenario Outline: Analytics telemetry events are accepted with required metadata
    Given the API base URL is "<base_url>"
    And the authorization header "Bearer <token>" is set
    And the Content-Type is "application/json"
    When I send a POST request to "/api/analytics/events" with JSON payload
      '''
      {
        "eventType": "<eventType>",
        "tickerId": "tckr-123",
        "timestamp": "<isoTimestamp>",
        "metadata": <metadata>
      }
      '''
    Then the response status should be 202
    And the response JSON should contain field "accepted" = true

    Examples:
      | base_url            | token  | eventType         | isoTimestamp             | metadata                                                                                     |
      | https://api.example | abc123 | ticker_impression | 2025-01-01T12:00:00Z     | {"surface":"player","reason":null}                                                            |
      | https://api.example | abc123 | ticker_dismiss    | 2025-01-01T12:00:05Z     | {"user_action":true}                                                                          |
      | https://api.example | abc123 | ticker_cta        | 2025-01-01T12:00:07Z     | {"destination":"FZ","cta_label":"Open promotion"}                                             |
      | https://api.example | abc123 | ticker_end        | 2025-01-01T12:00:10Z     | {"reason":"time","loopsCompleted":1}                                                          |

  # Non-functional Tests
  @nonfunctional @performance @tc-019
  Scenario Outline: Animation performance meets FPS and jank targets across devices
    Given performance profiling is enabled on a <deviceTier> device
    And a ticker with host, quoted text, yellow dot, and sponsorship suffix is visible in landscape
    When the ticker plays intro, two loops, and outro
    Then the average FPS should be at least <minFps>
    And the jank percentage should be less than <maxJankPercent>

    Examples:
      | deviceTier | minFps | maxJankPercent |
      | high-end   | 55     | 5              |
      | low-end    | 55     | 5              |

  @nonfunctional @latency @tc-020
  Scenario: End-to-end latency from publish to first visible frame within SLA
    Given synchronized clocks between server and client and logging of publish timestamps
    When a moderator publishes a ticker and the client records the first visible frame
    Then the median latency across 10 runs should be ≤ 1.0 seconds
    And the p95 latency should be ≤ 2.0 seconds under normal network conditions

  @nonfunctional @resources @tc-021
  Scenario: Resource usage (CPU and memory) within budget during ticker lifecycle
    Given CPU and memory profiling is active
    When a ticker with all elements plays intro, two loops, and outro
    Then the additional CPU usage should be ≤ 10% over baseline
    And the memory increase should be ≤ 20 MB during the ticker lifecycle

  @nonfunctional @a11y @tc-022
  Scenario: Accessibility for focus, labels, and contrast
    Given a screen reader is enabled and the ticker with CTA and Dismiss is visible
    When I navigate focus to the CTA and Dismiss using keyboard or remote
    Then the CTA should have the accessible name "Open promotion" and Dismiss should have "Dismiss ticker"
    And ticker content should be announced once per appearance, not repeated each loop
    And the color contrast for text and yellow dot against background should meet WCAG AA

  @nonfunctional @i18n @tc-023
  Scenario Outline: Internationalization and complex scripts layout and truncation
    Given I am watching a video in landscape with player controls hidden and connected to moderator messages
    And a moderator publishes a ticker with host nickname "<nickname>", host tag present, text "<text>", sponsorship suffix "<suffix>", and max display time 20 seconds
    When the ticker displays all elements
    Then the layout should not break, clip, or misalign
    And the nickname should be truncated to 10 visible characters without breaking ligatures or emoji clusters if longer than 10
    And quotes should render correctly around the text regardless of script

    Examples:
      | nickname              | text             | suffix               |
      | المضيفالمحترفطويل      | Great deals now  |                      |
      | Deal🔥🔥Host           | Hot🔥🔥Sale       | Sponsored by ACME    |

  @nonfunctional @resilience @tc-024
  Scenario Outline: Resilience to network interruptions affecting delivery timing
    Given network link conditioning is enabled to simulate drop and recovery
    And a moderator publishes a ticker at t=0 while I am in landscape
    When the network drops immediately and is restored after <restoreAfter>s
    Then if remaining time upon receipt is ≥ 1 second, the ticker should display
    And if remaining time upon receipt is < 1 second, the ticker should be skipped without error

    Examples:
      | restoreAfter |
      | 1.0          |
      | 9.5          |
