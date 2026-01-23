Feature: RoostGPT connectors, authentication, workflows, logs, insights, and reports validation

  # Common environment setup
  Background:
    Given the application base URL is 'https://dev.roostgpt.local'
    And the API base URL is 'https://dev.roostgpt.local/api'
    And I am testing in 'dev' environment
    And user roles 'admin' and 'tester' are available
    And authentication methods 'local' and 'okta' are configured or can be toggled by the test harness

  # UI Tests
  @ui @connectors
  Scenario: Bitbucket connector setup and repository metadata population with retry and latency injection
    Given I am logged in as 'admin' via local on '/login'
    When I navigate to '/roostgpt/connectors' and click 'Add Connector'
    And I select 'Bitbucket' and name the connector 'mayank-account'
    And I start OAuth and complete consent
    Then I should see the connector status 'Connected' with a masked token indicator
    When I click 'Fetch Repositories' and wait up to 20 seconds
    Then I should see the repositories list
    When I select repository 'mayankzbio/restassured'
    Then I should see a branch dropdown and project path input appear
    And I wait up to 10 seconds for metadata to populate
    But if metadata fails to load, I should see an error banner 'Unable to load branches and project path' with a 'Retry' option
    When I click 'Retry' and inject 2 seconds latency
    Then the branches should populate and project path suggestions should be available without exposing secrets
    When I enter branch 'main' and project path 'sample/path' and click 'Save'
    Then the connector metadata should persist and no secrets should be displayed

  @ui @connectors
  Scenario: GitLab connectors globally deprioritized are skipped with clear UI messaging and deterministic plan behavior
    Given I am on the Connectors page '/roostgpt/connectors' as 'admin'
    When I attempt to add a 'GitLab' connector
    Then I should see a banner 'GitLab connectors are currently deprioritized' and creation should be disabled with a 'Learn More' link
    When I navigate to '/roostgpt/workflow' and create a test plan referencing one Bitbucket-backed suite and one GitLab-backed suite
    And I save the plan and click 'Generate Tests'
    Then the plan should show two entries: 'Bitbucket suite' as 'Pending' and 'GitLab suite' as 'Skipped' with reason 'Deprioritized/unavailable connector'
    When I open the run summary tooltip
    Then the skipped count should increment by 1 and the message should explain the skip cause with no error severity escalation
    When I deep link to '/roostgpt/workflow?test_id=<masked>'
    Then the context should be preserved and the GitLab item should retain 'Skipped' consistently

  @ui @auth
  Scenario Outline: Okta SSO invalid configuration handling, session renewal, deep-link authorization, and dual-login plan broken handling
    Given I am on '/login' as a tester
    When I click 'Sign in with Okta' with configuration '<okta_config_state>'
    Then I should see '<expected_message>'
    When I correct the Okta configuration if invalid and retry login
    And I handle cross-origin redirect and CSRF token
    Then the session cookie should be set and the dashboard should load
    When I start a workflow plan that requires dual login (local + Okta)
    And I click 'Trigger Analyze' noting 'trigger_id' '<trigger_id>'
    Then I should see status transitions 'Created' -> 'Queued' -> 'Analyzing' on Workflow
    When I open '/roostgpt/logs?trigger_id=<trigger_id>' in a new tab
    Then I should see streaming logs begin
    When I simulate session expiry and attempt to interact with logs
    Then I should receive 401 and see 'Sign in required' with no data leakage
    When silent refresh or redirect to Okta occurs and I re-authenticate
    And I return to the logs deep-link
    Then analyze should continue without restart and lines continue streaming from last offset
    When in a separate profile I log out Okta and log in via local only and open '/roostgpt/insights?trigger_id=<trigger_id>'
    Then I should see 'Access denied or insufficient permissions' rather than 'Page not found'
    When I stop providing secondary local credentials in the plan secrets and resume analyze
    Then the plan should deterministically transition to 'Broken' with message 'Two-login requirement not satisfied'
    When I navigate to '/roostgpt/workflow?test_id=TEST-SSO-PLAN'
    Then the 'Broken' status should be synchronized with Logs and Insights (Insights shows 0 tests executed)
    When I click 'Rerun' and provide both Okta and local credentials
    Then I should see status transitions 'Created' -> 'Queued' -> 'Analyzing' -> 'Completed' and deep-link navigation preserves context and filters

    Examples:
      | okta_config_state | expected_message                 | trigger_id  |
      | invalid           | SSO configuration invalid        | T-SSO-001   |
      | valid             | Redirecting to Okta… then signed | T-SSO-001   |

  @ui @logs
  Scenario: Rest-Assured analyze logs stalled detection, timeout to stuck, retry, cancellation, and reconciliation
    Given I am logged in locally and open '/roostgpt/workflow'
    When I create a Rest-Assured analyze job and click 'Trigger Analyze'
    And I record 'trigger_id' '7886e55c-6a13-41b7-bd19-3b2e68416950'
    And I open '/roostgpt/logs?trigger_id=7886e55c-6a13-41b7-bd19-3b2e68416950'
    Then I should see initial log lines stream with timestamps
    When I simulate a log stall at 'Running mvn test' and no new lines after T0+2m
    Then I should see a spinner 'Waiting for logs' with last heartbeat time
    When I wait up to 30 minutes with polling
    Then the UI should mark status 'Stuck' and offer 'Retry' or 'Cancel'
    When I click 'Retry'
    Then Workflow should transition 'Queued' then 'Analyzing' and logs resume streaming from the stalled step or restart with a resume token
    When the stall persists for 10 minutes and I click 'Cancel'
    Then cancellation should be acknowledged in logs with 'Cancelled by user' and the job should stop gracefully
    When I navigate to '/roostgpt/workflow?test_id=<masked>'
    Then the status should be 'Cancelled' and Insights should indicate 'run cancelled' with no misleading pass/fail counts
    When I click 'Rerun Analyze' to get a new 'trigger_id' and open its logs deep link
    Then streaming should continue to completion with Workflow 'Completed', Logs 'Exit code 0', and Insights pass/fail/skip counts with no zero-value anomalies
    And counters across Workflow cards and Insights totals should match and partial artifacts from the cancelled attempt should be excluded

  @ui @karate
  Scenario: Karate analyze under resource and dependency failures with recovery and insights/report validation
    Given I am logged in locally and open '/roostgpt/workflow'
    When I select a Karate test suite and click 'Trigger Analyze'
    And I record 'trigger_id' 'f851c1d9-c387-4a45-83e1-bab730f81b6e'
    And I inject a disk space fault
    Then on '/roostgpt/logs?trigger_id=f851c1d9-c387-4a45-83e1-bab730f81b6e' I should see 'No space left on device' with stack trace and a remediation link
    When I navigate to the Workflow card
    Then the status should be 'Failed' with reason 'Resource exhaustion' and a 'Retry' CTA; Insights shows a failed run summary without zero counters if artifacts were not created
    When I free disk space and click 'Retry Analyze' to get 'trigger_id' '9810f51f-5bff-4fa8-8bda-a928135b9eed'
    And I open its logs deep link and simulate missing dependency 'npm prism'
    Then I should see error 'npm prism not found' with steps to install and run fails fast without hanging
    When Workflow reflects 'Failed' and Insights capture the failure reason in an error panel
    And I install 'npm prism' dependency and trigger analyze again
    Then the job should transition 'Created' -> 'Queued' -> 'Analyzing' -> 'Completed'
    When I open '/roostgpt/insights?trigger_id=<success>'
    Then compile success should be shown; test counters should be non-zero and plausible
    When I click 'View Allure Report'
    Then 'allure-report.zip' should download and 'index.html' should render; totals match Insights (total, passed, failed, skipped, broken)
    And logs show explicit remediation steps and no secrets in error outputs
    And cancelled or failed artifacts from prior attempts are not mixed into the successful run's Insights or Allure

  @ui @cross-framework
  Scenario Outline: Cross-framework insights visibility, reporter failure surfacing, analyze-not-triggered handling, and Allure reconciliation
    Given I am logged in locally and open '/roostgpt/workflow'
    When I generate tests for '<framework>'
    And I open the deep link '<page>'
    Then I should see '<expected_behavior>'
    When I open the Allure report if applicable for '<framework>'
    Then Allure totals should match Insights and Workflow summaries or the Allure button should be disabled with a clear tooltip
    And no sensitive tokens or credentials should be displayed in logs, insights, or artifacts
    When I click 'Retry' for analyze-not-triggered cases
    Then the trigger should be created idempotently without duplicates
    When I rerun after applying fixes
    Then the defects should be resolved and counters should reflect data correctly

    Examples:
      | framework        | page                                                               | expected_behavior                                                                                         |
      | Pytest unit      | /roostgpt/insights?trigger_id=c1c54717-75ee-4b9a-bc68-a55f9a8b8954 | Valid trigger should render Insights, not 'Page not found'; if defect, no data leakage in response        |
      | Karate           | /roostgpt/insights?trigger_id=6b0cc76b-62be-4d54-b0ca-6fc729b542a1 | Compile success shown; counters not zero when artifacts exist; reconcile with Allure                      |
      | Postman/Newman   | /roostgpt/logs?trigger_id=b0da00ec-2496-4465-aefc-636ce7cfd943     | Error 'Failed to update Newman html reporter' surfaced; run marked 'Failed'; Insights shows failure reason|
      | Any framework    | /roostgpt/workflow?test_id=9e1341bb-e312-4cf0-9efb-ca7b4c948934    | If analyze not triggered: show 'Analyze not triggered' with 'Retry' and precondition hints; retry works   |

  @ui @auth
  Scenario Outline: Local login CSRF enforcement, invalid credential messaging, and remember-me persistence
    Given I am on '/roostgpt/login'
    And I verify presence of a CSRF token in the login form
    When I attempt login with '<credentials>' and '<csrf_state>'
    Then I should see '<login_message>' and no session cookie set if CSRF fails
    When I perform a successful login with correct credentials and '<remember_me>'
    Then I should be redirected to the dashboard and a session cookie and remember token should be set if applicable
    When I refresh the dashboard twice
    Then the session should persist and CSRF token should rotate or remain valid per policy

    Examples:
      | credentials             | csrf_state     | login_message          | remember_me     |
      | valid masked creds      | removed        | CSRF validation error  | enabled         |
      | invalid password        | present        | Invalid credentials     | disabled        |
      | valid masked creds      | present        | Logged in successfully  | enabled         |

  @ui @auth
  Scenario: Session expiry redirect to login and deep-link return without data leakage; logout clears session
    Given I have an authenticated session with 'Remember me' enabled
    And I open a deep link '/roostgpt/workflow?test_id=<masked-workflow-id>'
    When I navigate to '/roostgpt/logs?trigger_id=<masked-trigger-id>' and simulate session expiry
    And I attempt an interaction (scroll or fetch older logs)
    Then I should be redirected to '/roostgpt/login' with a sanitized 'returnUrl' containing the original deep link and no data leakage
    When I log in again
    Then I should be redirected back to '/roostgpt/logs?trigger_id=<masked-trigger-id>' with context preserved (auto-scroll state)
    When I click the user menu and log out
    Then all auth cookies should be cleared and I should land on '/roostgpt/login'
    And navigating back should not restore authenticated content
    When I open '/roostgpt/insights?trigger_id=<masked-trigger-id>' in a new tab while logged out
    Then I should be consistently redirected to '/login' without partial content flash
    When I log in with 'Remember me' disabled and restart the browser
    Then no auto-login should occur and login should be required

  @ui @logs
  Scenario: Logs deep-link streaming with pagination, blip recovery, deduplication, sticky auto-scroll, and clean cancellation/rerun
    Given I have triggered analyze for a verbose Pytest API suite and recorded 'trigger_id' '<masked-pytest-trigger>'
    When I open '/roostgpt/logs?trigger_id=<masked-pytest-trigger>'
    Then streaming should start, timestamps should increment, and 'Auto-scroll to latest' is enabled
    When I disable Auto-scroll and scroll up and click 'Load older logs'
    Then the previous chunk should load with a visible divider and no gaps; sequence numbers should be continuous
    When I re-enable Auto-scroll and scroll to bottom
    Then new lines should append and a top truncation indicator should appear when the max buffer is reached
    When I simulate a network blip for ~20 seconds
    Then the UI should show 'Reconnecting…' then resume streaming from the correct offset with no duplicate or missing sequence numbers
    When I refresh the browser
    Then the viewer should request the last-known anchor and return to the same approximate position; 'Load older logs' remains functional
    When I toggle word wrap and search for a known error string
    Then line integrity and timestamps remain aligned and search matches across loaded chunks
    When I cancel the running analyze from the header control
    Then logs should append 'Cancelled by user' with a final state and no further lines stream
    When I click 'Rerun' and open the new logs deep link for 'trigger_id' '<masked-pytest-trigger-rerun>'
    Then no contamination from prior run should be present and streaming starts cleanly from the setup stage
    When I attempt to request older logs when none exist
    Then I should see a graceful 'No older logs' message without error banners

  @ui @security
  Scenario Outline: Deep link security for invalid, expired, and unauthorized IDs across Workflow, Logs, and Insights
    Given I am '<auth_state>' and I open '<page>'
    When I attempt to access the resource
    Then I should see '<expected_message>' and no sensitive metadata or partial content
    When I switch role to '<role_change>' if applicable and retry the same deep link
    Then I should see consistent authorization behavior and no data leakage
    When I request restore for archived runs where available
    Then restored data should appear without requiring a new trigger

    Examples:
      | auth_state     | page                                                          | expected_message                                      | role_change |
      | logged out     | /roostgpt/logs?trigger_id=<invalid-format>                    | Redirect to /login with sanitized returnUrl           | none        |
      | viewer         | /roostgpt/insights?trigger_id=<nonexistent-uuid>              | Insights not found for this ID                        | none        |
      | viewer         | /roostgpt/workflow?test_id=<unauthorized-foreign-test-id>     | 403 Forbidden - Access denied                         | admin       |
      | admin          | /roostgpt/workflow?test_id=<unauthorized-foreign-test-id>     | 403 Forbidden - Access denied                         | none        |
      | admin          | /roostgpt/insights?trigger_id=<expired-archived-trigger>      | Archived run - Request restore or view limited metadata| none        |
      | admin          | /roostgpt/logs?trigger_id=<expired-archived-trigger>          | Archived logs unavailable                             | none        |
      | viewer         | /roostgpt/insights?triggr_id=<valid-owned-test-id>            | Parameter validation error                            | none        |
      | logged out     | /roostgpt/workflow?test_id=<valid-owned-test-id>              | Redirect to /login then return to requested workflow  | none        |

  @ui @composite
  Scenario: Multi-framework plan transitions to Partial due to a single component failure, then completes after rerun of failed component
    Given I create a composite plan with Job A (Pytest API) and Job B (Rest-Assured) and note 'test_id' '<masked-composite-test-id>'
    When I click 'Trigger Analyze'
    Then overall status transitions 'Created' -> 'Queued' -> 'Analyzing'
    When I open logs for Job A '/roostgpt/logs?trigger_id=<masked-jobA-trigger>'
    Then Job A should complete successfully with 'Exit code 0'
    When I open logs for Job B '/roostgpt/logs?trigger_id=<masked-jobB-trigger>' and inject a compile error
    Then I should see 'Compile failed' and a non-zero exit
    When I return to '/roostgpt/workflow?test_id=<masked-composite-test-id>'
    Then overall status should be 'Partial' with sub-status 'Passed:1 Failed:1' and synchronized timestamps
    When I open Insights for the overall run via the icon
    Then counters should reflect only Job A results and Job B should show an explicit failure reason with zero test executions
    And Job A should show 'Completed' with matching Insights breakdown; Job B shows 'Failed' with compile error and no test counters
    When I verify Allure links
    Then Allure is available only for Job A; overall aggregate omits Job B test cases but includes an errors section
    When I click 'Rerun failed components only' and fix the dependency
    Then the plan should transition from 'Partial' to 'Completed' and Insights aggregate includes both jobs with correct totals
    And the second run should not duplicate Job A results and Workflow audit history should record both attempts with clear attributions

  @ui @reports
  Scenario: Allure report generation failure, regeneration workflow, artifact integrity checks, and deep-link mapping
    Given I open '/roostgpt/insights?trigger_id=<masked-complete-trigger>' and see non-zero counters
    When I click 'View Allure Report'
    Then if 'Report is processing' appears, I wait with backoff up to 120 seconds and see periodic polling and progress indicators
    When a missing artifact is simulated
    Then I should see 'Allure report not available' with options 'Regenerate report' and 'View logs'
    When I click 'Regenerate report'
    Then I should observe subtask statuses 'Queued' -> 'Running' -> 'Completed' and Workflow reflects a 'Report generation' subtask
    When regeneration completes and I click 'Download allure-report.zip'
    Then checksum validation should pass and 'index.html' should render; totals match Insights (total, passed, failed, skipped, broken)
    When a corrupted download is forced mid-transfer
    Then the viewer should detect 'Invalid archive' and prompt 'Retry download' or 'Regenerate again' without partial content
    When I regenerate again and cancel midway
    Then the UI should show 'Cancelled' and the previous valid artifact remains active; no dangling partial artifacts should be linked
    When from Insights I click a test case link to deep-link to Allure
    Then the Allure page should open to the exact test with matching status and attachments
    And Allure totals should match the Workflow run summary or prompt regeneration with diagnostics if mismatch
    And audit history should note regeneration attempts with timestamps and actors; no sensitive tokens appear in report URLs or logs

  @ui @newman
  Scenario Outline: Postman/Newman analyze with environment handling, reporter configuration changes, artifacts, and reconciliation
    Given I am logged in and open '/roostgpt/workflow'
    When I create a Newman job for repo 'postman-sample', branch 'main', project path 'postman/collections'
    And I attach environment '<env_file>' and mark sensitive variables masked if present
    And I select reporters '<reporters>' and click 'Save'
    And I click 'Generate' then 'Trigger Analyze' and capture 'trigger_id' '<trigger_id>'
    When I open '/roostgpt/logs?trigger_id=<trigger_id>'
    Then setup lines should show 'Reporter configured: <reporters_text>' and 'Environment: <env_name>' without exposing secrets
    And I toggle log filters to 'Errors only' and back to 'All' and streaming continues to completion with 'Exit code 0'
    When I open '/roostgpt/insights?trigger_id=<trigger_id>'
    Then totals should be non-zero and per-request pass/fail should display with environment name; masked variables are redacted
    When I download artifacts 'newman-report.html' and 'junit-results.xml' if configured
    Then they should render/parse and their totals should match Insights counters
    When Allure integration is '<allure_state>'
    Then the 'View Allure Report' button should be '<allure_visibility>' and totals should reconcile if enabled
    And removing the env file should fall back to UI defaults with a warning 'Using default env values' and comparable totals without crashes

    Examples:
      | env_file                         | reporters        | trigger_id                     | reporters_text | env_name | allure_state | allure_visibility |
      | dev.postman_environment.json     | html,junit       | <masked-newman-trigger>        | html,junit     | dev      | enabled      | visible           |
      | dev.postman_environment.json     | html             | <masked-newman-trigger-2>      | html           | dev      | enabled      | visible           |
      | (none - use UI defaults)         | html             | <masked-newman-trigger-3>      | html           | default  | disabled     | hidden            |

  @ui @workflow
  Scenario: Workflow dashboard filters, sorting, pagination, bulk retry/cancel, and context preservation
    Given I am logged in and open '/roostgpt/workflow' with >20 historical runs and mixed statuses
    When I validate status chip counters reflect the unfiltered totals
    And I apply filters Status='Failed','Broken','Skipped'
    Then the list should update and chips should recalculate counts excluding 'Completed'
    When I sort by 'Start Time' descending
    Then the first item should have the latest timestamp and the sort arrow should indicate active order
    When I use search with substring 'restassured'
    Then results should narrow and the term should be highlighted in rows
    When I select all items on page 1 and click 'Bulk Retry'
    Then only 'Failed' and 'Broken' items should retry; 'Skipped' remain unchanged; 'Completed' unaffected and new 'trigger_ids' appear in a toast
    When I navigate to page 2
    Then page 1 selections should be cleared unless 'Select all across pages' is used; selection count should match filtered total when used
    When I click 'Bulk Cancel' for items currently 'Queued'
    Then only 'Queued' items should transition to 'Cancelled'; others show tooltip 'Not applicable'; Logs append 'Cancelled by user' and stop streaming
    When I open a filtered item via its Logs icon and then click 'Back to Workflow'
    Then filters and sort order should persist and list position retained
    When I clear all filters
    Then chips counters revert to global totals and pagination shows correct total pages
    And refreshing the page should restore default sort and no-filter state
    When I re-apply a saved filter view 'Failing Only' or the Failed/Broken filter
    Then results should match deterministically and subsequent bulk actions behave as expected

  # API Tests
  @api @idempotency
  Scenario Outline: Analyze trigger idempotency, deduplication under rapid retries, and conflict handling
    Given the API base URL is 'https://dev.roostgpt.local/api' and the authorization token is set
    When I send a POST request to '/triggers' with payload:
      """
      {
        "job_id": "<job_id>",
        "framework": "pytest-api",
        "dedup_key": "<dedup_key>"
      }
      """
    Then the response status should be <status>
    And the response should contain '<response_field>'
    When I immediately retry the same POST with the same 'dedup_key'
    Then the response status should be <retry_status>
    And no new trigger should be produced (same 'trigger_id' or a 409 conflict)
    When I send a CANCEL request to '/triggers/<trigger_id>/cancel' while 'Queued'
    Then the response status should be 200 and status transitions to 'Cancelled'
    When I send a POST request to '/triggers' with a new 'dedup_key' after cancellation
    Then the response status should be 201 and a new 'trigger_id' is created

    Examples:
      | job_id        | dedup_key       | status | response_field | retry_status |
      | JOB-PY-001    | idem-123        | 201    | trigger_id     | 409          |
      | JOB-PY-001    | idem-123        | 201    | trigger_id     | 201          |

  @api @logs
  Scenario Outline: Logs pagination API returns ordered, non-duplicated lines and resumes after transient failures
    Given the API base URL is 'https://dev.roostgpt.local/api' and the authorization token is set
    When I send a GET request to '/logs/<trigger_id>?cursor=<cursor>&limit=<limit>'
    Then the response status should be 200
    And the response should contain an array 'lines' with monotonically increasing 'sequence' numbers and timestamps
    When I simulate a transient network failure and resend the GET with the last received 'sequence' anchor
    Then the response status should be 200 and no line is duplicated or missing
    When I request older logs with a 'prev_cursor' when none exist
    Then the response should be 200 with an empty 'lines' array and message 'No older logs'

    Examples:
      | trigger_id                                   | cursor     | limit |
      | 7886e55c-6a13-41b7-bd19-3b2e68416950         | tail       | 500   |
      | 7886e55c-6a13-41b7-bd19-3b2e68416950         | seq-105000 | 500   |

  @api @connectors
  Scenario Outline: Connector validation transitions and metadata refresh
    Given the API base URL is 'https://dev.roostgpt.local/api' and the authorization token is set
    When I send a POST request to '/connectors/<connector_id>/validate'
    Then the response status should be 200
    And the response body should contain 'state' equal to '<initial_state>'
    When I simulate external OAuth revocation and resend POST '/connectors/<connector_id>/validate'
    Then the response status should be 200
    And the response body should contain 'state' equal to 'Misconfigured' and a message 'Re-auth required'
    When I reauthorize and resend POST '/connectors/<connector_id>/validate'
    Then the response status should be 200
    And the response body should contain 'state' equal to 'Available' and metadata fields 'repo','branch','project_path' preserved

    Examples:
      | connector_id | initial_state |
      | mayank-account-bitbucket | Available |

  @api @security
  Scenario Outline: Deep link API security for invalid, nonexistent, unauthorized, archived IDs
    Given the API base URL is 'https://dev.roostgpt.local/api' and the authorization token is set for role '<role>'
    When I send a GET request to '<endpoint>'
    Then the response status should be <status>
    And the response body should contain '<body_message>' without leaking internal IDs or stack traces

    Examples:
      | role   | endpoint                                              | status | body_message                             |
      | none   | /logs/<invalid-format>                                | 401    | authentication_required                  |
      | viewer | /insights/<nonexistent-uuid>                          | 404    | insights_not_found                        |
      | viewer | /workflow/<unauthorized-foreign-test-id>              | 403    | access_denied                             |
      | admin  | /workflow/<unauthorized-foreign-test-id>              | 403    | access_denied                             |
      | admin  | /insights/<expired-archived-trigger>                  | 410    | archived_run                               |

  @api @insights
  Scenario Outline: Pytest API insights counters and classification mapping (failed, broken, skipped, xfail/xpass)
    Given the API base URL is 'https://dev.roostgpt.local/api' and the authorization token is set
    When I send a GET request to '/insights/<trigger_id>'
    Then the response status should be 200
    And the response JSON should contain counters: 'total','passed','failed','skipped','broken'
    And the response JSON should contain classification fields for 'xfail' and 'xpass' per policy
    When I compare counters to expected suite composition
    Then I should see non-zero counts matching '<expected_profile>'
    And the mapping should align with Allure categories names

    Examples:
      | trigger_id                         | expected_profile                                            |
      | <masked-pytest-mixed>              | 1 pass,1 fail,1 broken,1 skipped,1 xfail                    |
      | <masked-pytest-fixed>              | broken=0; other counts adjusted accordingly                 |

  @api @remap
  Scenario Outline: Connector resilience to repository rename and branch deletion via pre-run validation, skip, and re-map
    Given the API base URL is 'https://dev.roostgpt.local/api' and the authorization token is set for role 'admin'
    When I send a POST request to '/triggers' with payload:
      """
      {
        "job_id": "<job_id>",
        "repo": "old-name",
        "branch": "dev",
        "project_path": "api-tests/rest"
      }
      """
    Then the response status should be 201
    And the run should complete successfully as baseline
    When the repository is renamed to 'new-name' and branch 'dev' is deleted
    And I send a POST request to '/triggers' with payload:
      """
      {
        "job_id": "<job_id>",
        "repo": "old-name",
        "branch": "dev",
        "project_path": "api-tests/rest"
      }
      """
    Then the response status should be 422
    And the response body should contain 'validation_error' 'Repository or branch not found'
    When I send a POST request to '/triggers/<trigger_id>/skip' with payload:
      """
      {
        "reason": "Reference missing",
        "external_status": 404
      }
      """
    Then the response status should be 200 and the run should be marked 'Skipped'
    When I send a PUT request to '/jobs/<job_id>/remap' with payload:
      """
      {
        "repo": "new-name",
        "branch": "main"
      }
      """
    Then the response status should be 200 and metadata should refresh
    When I trigger analyze again for the remapped job
    Then the response status should be 201 and the run should complete successfully with correct repo metadata

    Examples:
      | job_id     |
      | JOB-REST-1 |

  @api @reports
  Scenario Outline: Allure report generation regeneration endpoint, checksum validation, and cancellation semantics
    Given the API base URL is 'https://dev.roostgpt.local/api' and the authorization token is set
    When I send a POST request to '/reports/allure/<trigger_id>/generate'
    Then the response status should be 202 and the report job status 'Queued'
    When I poll GET '/reports/allure/<trigger_id>/status' until 'Completed' or timeout
    Then the response should show 'Completed' within 120 seconds
    When I download GET '/reports/allure/<trigger_id>/artifact'
    Then the response should include a 'checksum' header and the zip should validate
    When I simulate a corrupted download and retry
    Then the service should return 400 'invalid_archive' and allow 'Regenerate' endpoint
    When I send a POST request to '/reports/allure/<trigger_id>/generate' and then POST '/reports/allure/<trigger_id>/cancel'
    Then the current report job should be 'Cancelled' and the previous valid artifact remains active

    Examples:
      | trigger_id                  |
      | <masked-complete-trigger>   |

