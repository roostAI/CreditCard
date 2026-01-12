Feature: RoostGPT connectors, authentication, workflow, logs, insights, and reports validation

  # Shared context across scenarios
  Background:
    Given the application environment is 'dev'
    And test datasets and projects are available in Bitbucket and other frameworks
    And the system can simulate network latency, faults, and session expiry per scenario needs

  # UI Tests
  @ui
  Scenario Outline: Bitbucket connector setup, repo metadata population with retry, and GitLab deprioritized skip handling
    Given I am logged in locally as admin on '/login'
    When I navigate to the Connectors page '/roostgpt/connectors' and click 'Add Connector'
    And I choose 'Bitbucket', enter name 'mayank-account', and start OAuth
    Then I should see the connector status 'Connected' with token masked
    When I click 'Fetch Repositories' and wait up to <timeout_seconds>s
    Then I should see repositories list state '<fetch_state>' and backoff visible if retried
    When I select repository 'mayankzbio/restassured'
    Then the branch dropdown and project path input appear
    When I wait up to 10s for branch and project metadata
    Then I should see '<metadata_state>' with banner messaging if not loaded
    When I click 'Retry' and inject <latency> artificial latency
    Then branch options populate and project path suggestions are offered by the server
    When I enter branch 'main' and project path 'sample/path' and click 'Save'
    Then connector metadata persists and no secrets are displayed
    When I attempt to add a GitLab connector
    Then I should see 'GitLab connectors are currently deprioritized' and creation is disabled with a 'Learn More' link
    When I navigate to Workflow and create a new test plan referencing one Bitbucket-backed suite and one GitLab-backed suite
    And I click 'Generate Tests'
    Then the plan shows two entries: Bitbucket suite 'Pending' and GitLab suite 'Skipped' with reason 'Deprioritized/unavailable connector'
    And the run summary tooltip shows skipped count incremented by 1 with an explanatory message and no error severity escalation
    When I open the deep link '/roostgpt/workflow?test_id=<masked>'
    Then the GitLab item retains 'Skipped' consistently across views

    Examples:
      | timeout_seconds | fetch_state      | metadata_state                                           | latency |
      | 20              | list populated   | metadata populated                                       | 2s      |
      | 20              | empty, retrying  | error: Unable to load branches and project path (banner) | 2s      |

  @ui
  Scenario Outline: Bitbucket OAuth revocation and reauthorization restore metadata without data loss
    Given I am on the Connectors page '/roostgpt/connectors' with a Bitbucket connector named 'mayank-account' in 'Available' state
    When I revoke Bitbucket OAuth in Bitbucket and click 'Validate' in RoostGPT
    Then the connector transitions from 'Available' to 'Misconfigured' and repo metadata fields indicate re-auth required
    When I reauthorize Bitbucket OAuth
    Then the connector transitions back to 'Available' and previously selected repo, branch, and project path are restored without data loss
    And no secrets are visible in the UI

    Examples:
      | connector_name  |
      | mayank-account  |

  @ui
  Scenario Outline: Okta SSO invalid configuration, session expiry, deep-link authorization, and dual-login broken handling with rerun success
    Given I navigate to '/login'
    When I click 'Sign in with Okta' with configuration '<okta_config_state>'
    Then I should see '<expected_message>' and no internal details are exposed
    When I correct Okta configuration (if invalid) and retry sign-in handling cross-origin redirect and CSRF
    Then a session cookie is set and the dashboard loads
    When I start a workflow plan requiring dual login (local + Okta) and click 'Trigger Analyze'
    Then the pre-run checklist indicates both identities required and the status transitions 'Created' -> 'Queued' -> 'Analyzing'
    When I open logs deep link '/roostgpt/logs?trigger_id=T-SSO-001' in a new tab
    Then streaming logs begin
    When I simulate session expiry and interact with logs
    Then I receive '401 Sign in required' without data leakage
    When a silent refresh occurs or I re-authenticate with Okta and return to the logs deep link
    Then the analyze continues without restart and lines continue streaming from the last offset
    When in a separate browser profile, I log out Okta and log in via local only and open '/roostgpt/insights?trigger_id=T-SSO-001'
    Then I see 'Access denied or insufficient permissions' instead of 'Page not found'
    When I stop providing secondary local credentials in plan secrets and resume analyze
    Then the plan transitions deterministically to 'Broken' with message 'Two-login requirement not satisfied'
    When I navigate to '/roostgpt/workflow?test_id=TEST-SSO-PLAN'
    Then 'Broken' status is synchronized across Workflow, Logs, and Insights (Insights shows 0 tests executed)
    When I click 'Rerun' and provide both Okta and local credentials
    Then the status transitions 'Created' -> 'Queued' -> 'Analyzing' -> 'Completed' and deep link navigation preserves context

    Examples:
      | okta_config_state | expected_message                  |
      | invalid           | SSO configuration invalid         |
      | valid             | Dashboard loads after Okta sign-in |

  @ui
  Scenario Outline: Rest-Assured analyze stalled logs detection, timeout to 'Stuck', retry, cancel, and cross-page reconciliation
    Given I am logged in locally and create a Rest-Assured analyze job from Workflow
    When I click 'Trigger Analyze' and record trigger_id '7886e55c-6a13-41b7-bd19-3b2e68416950'
    And I open '/roostgpt/logs?trigger_id=7886e55c-6a13-41b7-bd19-3b2e68416950'
    Then initial log lines stream with timestamps
    When I simulate log stall at a known step and observe no new lines after T0+2m
    Then a spinner shows 'Waiting for logs' with last heartbeat time
    When I wait up to 30 minutes with explicit polling
    Then the UI marks status 'Stuck' and offers 'Retry' or 'Cancel'
    When I click '<post_timeout_action>'
    Then the Workflow status transitions accordingly and logs '<log_resume_behavior>'
    When I cancel after a persistent stall (if chosen) and open Workflow deep link '/roostgpt/workflow?test_id=<masked>'
    Then overall status is 'Cancelled' and Insights indicate run cancelled with no misleading pass/fail counts
    When I click 'Rerun Analyze'
    Then a new trigger_id is assigned and logs stream continuously to completion
    And Workflow shows 'Completed', Logs end with 'Exit code 0', and Insights counters have no zero-value anomalies
    And counters across Workflow and Insights match and partial artifacts from the cancelled attempt are excluded

    Examples:
      | post_timeout_action | log_resume_behavior                                     |
      | Retry               | resumes streaming from step-of-stall with resume token  |
      | Cancel              | shows 'Cancelled by user' and stops streaming           |

  @ui
  Scenario Outline: Karate analyze under resource and dependency failures with remediation and insights/report validation
    Given I create a Karate test suite job and click 'Trigger Analyze' with trigger_id '<first_trigger>'
    When I inject disk space fault and open '/roostgpt/logs?trigger_id=<first_trigger>'
    Then I should see error 'No space left on device' with stack trace and remediation link
    When I navigate to the Workflow card
    Then the status is 'Failed' with reason 'Resource exhaustion' and a 'Retry' CTA
    And Insights show a failed run summary with no misleading zero counters
    When I free disk space and click 'Retry Analyze' to get trigger_id '<second_trigger>'
    And I open '/roostgpt/logs?trigger_id=<second_trigger>'
    Then I should see error 'npm prism not found' with steps to install, and the run fails fast without hanging
    When Workflow reflects 'Failed' and Insights capture the failure reason
    And I download the error logs
    Then messaging is correct and secrets are not present
    When I install 'npm prism' and trigger analyze again to create trigger_id '<success_trigger>'
    Then the job transitions through 'Created', 'Queued', 'Analyzing' and completes successfully
    When I open '/roostgpt/insights?trigger_id=<success_trigger>'
    Then compile success is shown and counters are non-zero and plausible
    When I click 'View Allure Report' and download 'allure-report.zip'
    Then 'index.html' renders and totals match Insights (total, passed, failed, skipped, broken)
    And Logs show explicit remediation steps for both failures and no secrets in error outputs
    And prior failed artifacts are not mixed into the successful run's Insights or Allure

    Examples:
      | first_trigger                              | second_trigger                             | success_trigger        |
      | f851c1d9-c387-4a45-83e1-bab730f81b6e       | 9810f51f-5bff-4fa8-8bda-a928135b9eed      | <success>              |

  @ui
  Scenario Outline: Cross-framework insights visibility, Karate aggregation, Newman reporter failure, analyze-not-triggered handling, and Allure reconciliation
    Given I log in locally and open Workflow
    When I generate tests for Pytest unit, Pytest API, Karate, and Postman/Newman
    And for Pytest unit, I click Insights icon for trigger_id '<pytest_trigger>'
    Then a valid trigger should render Insights and not 'Page not found'; defects are recorded if reproduced
    When for Karate, I open Insights for trigger_id '<karate_trigger>'
    Then compile success is visible and counters do not show zero when artifacts exist
    When I open Allure report for the Karate run
    Then totals match Insights and Workflow; mismatches are flagged
    When for Postman/Newman, I open logs for trigger_id '<newman_trigger>'
    Then I should see error 'Failed to update Newman html reporter' surfaced clearly and the run marked 'Failed'; Insights show the failure reason
    When for one generated test, 'Analyze' did not trigger post-generate
    Then the UI displays 'Analyze not triggered' with 'Retry' and precondition hints; clicking 'Retry' creates an idempotent trigger
    When all runs complete, I open Allure aggregation and download 'allure-report.zip' and 'index.html'
    Then Allure totals match Insights and Workflow summaries and no failures are omitted
    And raw logs' fail signatures reconcile with Allure and UI counts and warnings prompt reconciliation if Allure misses failures
    When I navigate via workflow deep link '/roostgpt/workflow?test_id=<workflow_deeplink>'
    And I open Logs and Insights via icons
    Then context and filters persist across pages
    And no sensitive tokens or credentials are displayed anywhere
    When I re-run affected runs after applying fixes
    Then Pytest Insights loads correctly, Karate counters reflect data, and Newman runs succeed with reporter updated

    Examples:
      | pytest_trigger                           | karate_trigger                          | newman_trigger                         | workflow_deeplink                            |
      | c1c54717-75ee-4b9a-bc68-a55f9a8b8954    | 6b0cc76b-62be-4d54-b0ca-6fc729b542a1   | b0da00ec-2496-4465-aefc-636ce7cfd943   | 9e1341bb-e312-4cf0-9efb-ca7b4c948934         |

  @ui
  Scenario Outline: Local login CSRF enforcement, invalid credentials messaging, remember-me persistence, logout, and session expiry deep-link redirect
    Given I navigate to '/roostgpt/login' and observe a CSRF token present in the login form
    When I submit valid credentials while intercepting to remove CSRF token
    Then I should see 'CSRF validation failed' and no session cookie is set
    When I retry login with incorrect password and valid CSRF
    Then I should see 'Invalid credentials' and no session is established
    When I perform a successful login with correct credentials and enable 'Remember me'
    Then I am redirected to the dashboard and a session cookie plus remember token are set
    When I refresh the dashboard twice
    Then the session persists and CSRF token rotates or remains valid per policy
    When I open a deep link '/roostgpt/workflow?test_id=<masked-workflow-id>'
    Then the page renders with user context and filters available
    When I simulate session expiry while viewing '/roostgpt/logs?trigger_id=<masked-trigger-id>' and interact
    Then I am redirected to '/login' with 'returnUrl' containing the original deep link
    When I log in again
    Then I am redirected back to '/roostgpt/logs?trigger_id=<masked-trigger-id>' with context preserved and no data leakage
    When I click the user menu and log out
    Then all auth cookies are cleared and I return to '/roostgpt/login'; using Back does not restore authenticated content
    When I open '/roostgpt/insights?trigger_id=<masked-trigger-id>' in a new tab while logged out
    Then I am consistently redirected to '/login' with no partial content flash
    When I log in again with 'Remember me' disabled and reopen the browser
    Then no auto-login occurs and login is required

    Examples:
      | masked-workflow-id | masked-trigger-id |
      | <masked>           | <masked>          |

  @ui
  Scenario Outline: Logs deep-link streaming with pagination, network blip recovery, deduplication, tail correctness, and rerun isolation
    Given I trigger analyze for a verbose Pytest API suite and record trigger_id '<pytest_trigger>'
    When I open '/roostgpt/logs?trigger_id=<pytest_trigger>' and enable 'Auto-scroll to latest'
    Then streaming starts, timestamps increment, and new lines append
    When I disable 'Auto-scroll', scroll up, and click 'Load older logs'
    Then the previous chunk loads with a visible divider and no gaps; sequence numbers are noted
    When I re-enable 'Auto-scroll' and scroll to bottom
    Then new lines append and a top truncation indicator shows when max buffer is reached
    When I simulate a transient network blip for ~20s
    Then the UI shows 'Reconnecting…' and resumes streaming from the correct offset with no duplicates or gaps
    When I refresh the browser
    Then the viewer requests the last-known anchor and returns to the same approximate position; 'Load older logs' remains functional
    When I toggle word wrap on and off and search for a known error string
    Then line integrity and timestamps remain aligned and search matches across chunks
    When I cancel the running analyze from the header control
    Then logs append 'Cancelled by user' with exit code or final state and no further lines stream
    When I click 'Rerun' from Workflow to create trigger_id '<pytest_trigger_rerun>'
    And I open '/roostgpt/logs?trigger_id=<pytest_trigger_rerun>'
    Then streaming starts cleanly from setup stage with no contamination from the prior run
    When I request older logs when none exist
    Then I see a graceful 'No older logs' message without error banners

    Examples:
      | pytest_trigger                    | pytest_trigger_rerun             |
      | <masked-pytest-trigger>          | <masked-pytest-trigger-rerun>    |

  @ui
  Scenario Outline: Deep link security for invalid, expired, and unauthorized IDs across Workflow, Logs, and Insights
    Given I have roles '<role>' and authentication state '<auth_state>'
    When I navigate to '<page>' with deep link type '<link_type>' and ID '<link_id>'
    Then I should see '<expected_ui_response>' and no data leakage
    When I perform a restore on archived runs (if applicable)
    Then restored data appears and counters load without requiring a new trigger

    Examples:
      | role   | auth_state    | page                                 | link_type           | link_id                    | expected_ui_response                                                 |
      | none   | logged_out    | /roostgpt/logs                       | invalid-format      | abc123                     | Redirect to /login with sanitized returnUrl                          |
      | viewer | logged_in     | /roostgpt/insights                   | nonexistent-uuid    | 00000000-0000-0000-0000-000000000000 | Friendly error 'Insights not found for this ID' without internal IDs |
      | viewer | logged_in     | /roostgpt/workflow                   | unauthorized-foreign-test-id | foreign-123          | 403 Forbidden 'Access denied'                                        |
      | admin  | logged_in     | /roostgpt/workflow                   | unauthorized-foreign-test-id | foreign-123          | 403 Forbidden 'Access denied'                                        |
      | admin  | logged_in     | /roostgpt/insights                   | expired-archived-trigger | archived-456            | 'Archived run' message with 'Request restore'                        |
      | admin  | logged_in     | /roostgpt/logs                       | expired-archived-trigger | archived-456            | 'Archived logs unavailable'                                          |
      | viewer | logged_in     | /roostgpt/insights?triggr_id=...     | parameter-error     | corrected-on-help         | Router guidance on parameter validation error                        |
      | none   | logged_out    | /roostgpt/workflow                   | valid-owned-test-id | owned-789                  | Redirect to /login then back to the requested workflow after auth    |

  @ui
  Scenario Outline: Trigger lifecycle to 'Partial' with multi-framework plan and rerun failing component to reach 'Completed'
    Given I create a composite test plan containing Job A (Pytest API) and Job B (Rest-Assured) with test_id '<composite_test_id>'
    When I 'Trigger Analyze' for the plan
    Then overall status transitions 'Created' -> 'Queued' -> 'Analyzing'
    When I open Logs for Job A '/roostgpt/logs?trigger_id=<jobA_trigger>'
    Then I see successful progression and 'Exit code 0'
    When I open Logs for Job B '/roostgpt/logs?trigger_id=<jobB_trigger>' and inject a compile error
    Then I see 'Compile failed' with non-zero exit
    When I return to '/roostgpt/workflow?test_id=<composite_test_id>'
    Then the overall status shows 'Partial' with sub-status 'Passed:1 Failed:1' and synchronized timestamps
    When I open Insights for the overall run
    Then counters reflect only Job A results and Job B contributes zero test executions with explicit failure reason
    And Job A shows 'Completed' in Workflow with matching Insights breakdown; Job B shows 'Failed' with compile error and no counters
    When I validate Allure links
    Then Allure is available only for Job A; overall aggregate omits Job B test cases but includes an errors section
    When I click 'Rerun failed components only' and fix the dependency
    Then the plan transitions from 'Partial' to 'Completed' and Insights aggregate include both jobs with correct totals
    And Job A results are not duplicated and Workflow audit history records both attempts with clear attribution

    Examples:
      | composite_test_id | jobA_trigger            | jobB_trigger            |
      | <masked-composite> | <masked-jobA-trigger>  | <masked-jobB-trigger>   |

  @ui
  Scenario Outline: Allure report generation failure, regeneration workflow, artifact integrity, and deep-link mapping
    Given I open Insights '/roostgpt/insights?trigger_id=<complete_trigger>' and counters show non-zero totals
    When I click 'View Allure Report'
    Then if 'Report is processing' appears, the UI polls with progress up to 120s
    When a missing artifact is simulated and polling completes
    Then I see 'Allure report not available' with options 'Regenerate report' and 'View logs'
    When I click 'Regenerate report'
    Then a background job shows 'Queued' -> 'Running' -> 'Completed' and Workflow reflects a report generation subtask
    When I click 'Download allure-report.zip'
    Then checksum validation passes and 'index.html' renders with totals matching Insights
    When a corrupted download is forced mid-transfer
    Then the viewer detects 'Invalid archive' and prompts 'Retry download' or 'Regenerate again' without showing partial content
    When I regenerate again and cancel midway
    Then the UI shows 'Cancelled' and the previous valid artifact remains active; no partial artifacts are linked
    When I click a specific test link in Insights that deep-links to Allure
    Then the Allure test detail opens to the exact test with matching status and attachments
    When I compare Allure totals with Workflow run summary
    Then they match; if mismatch, an alert banner prompts regeneration and a diagnostic link appears
    And audit history notes both regeneration attempts with timestamps and actors; no sensitive tokens appear

    Examples:
      | complete_trigger             |
      | <masked-complete-trigger>    |

  @ui
  Scenario Outline: Postman/Newman end-to-end with environment handling, reporter configuration, artifacts, and reconciliation
    Given I create a new Postman/Newman job selecting repo 'postman-sample', branch 'main', project path 'postman/collections'
    When I attach environment '<env_file>' with masked sensitive variables and select reporters '<reporters>'
    And I click 'Save', then 'Generate', then 'Trigger Analyze'
    Then I capture trigger_id '<newman_trigger>' from the job card or logs link
    When I open '/roostgpt/logs?trigger_id=<newman_trigger>'
    Then setup lines show 'Reporter configured: <reporters>' and 'Environment: <env_name>' with secret values redacted
    And I do not see 'Failed to update Newman html reporter'
    When I toggle log filters 'Errors only' and back to 'All'
    Then lines filter correctly and streaming continues to completion with 'Exit code 0'
    When I open '/roostgpt/insights?trigger_id=<newman_trigger>'
    Then totals are non-zero per-request pass/fail and environment name is shown; masked variables are redacted
    When I download artifacts
    Then 'newman-report.html' and 'junit-results.xml' (if configured) render/parse and match Insights counters
    When I edit the job to change reporters to '<reporters_after>'
    And I rerun analyze to create '<newman_trigger_2>'
    Then only configured artifacts are produced; Insights totals remain consistent
    When I remove the environment file and set fallback key=value pairs via UI and rerun to create '<newman_trigger_3>'
    Then the run completes with a warning 'Using default env values' and totals are comparable; no crash due to missing env
    When Allure integration is '<allure_enabled>' for Newman
    Then the 'View Allure Report' button is '<allure_button_state>' with matching totals if enabled

    Examples:
      | env_file                         | env_name | reporters        | newman_trigger              | reporters_after | newman_trigger_2            | newman_trigger_3            | allure_enabled | allure_button_state        |
      | dev.postman_environment.json     | dev      | html,junit       | <masked-newman-trigger>     | html            | <masked-newman-trigger-2>   | <masked-newman-trigger-3>   | enabled        | visible and functional     |
      | dev.postman_environment.json     | dev      | html             | <masked-newman-trigger-alt> | html            | <masked-newman-trigger-alt2> | <masked-newman-trigger-alt3> | disabled       | hidden or disabled tooltip |

  @ui
  Scenario Outline: Workflow dashboard filters, sorting, pagination, and bulk actions with cross-page consistency
    Given I open '/roostgpt/workflow' and status chips show global totals by status
    When I apply filters Status='<filter_statuses>'
    Then the list updates and chips recalculate to reflect filtered items without including 'Completed'
    When I sort by 'Start Time' descending
    Then the first item has the latest timestamp and the sort arrow indicates active order
    When I search by repo substring '<search_term>'
    Then results narrow and the search term is highlighted
    When I select all items on page 1 and click 'Bulk Retry'
    Then only items with 'Failed' or 'Broken' are retried; 'Skipped' remain unchanged; 'Completed' unaffected; new trigger_ids appear in a toast
    When I navigate to page 2
    Then selection from page 1 is cleared unless 'Select across all pages' is used; using 'Select across all pages' shows selection count equals filtered total
    When I click 'Bulk Cancel' for items currently 'Queued'
    Then only 'Queued' items transition to 'Cancelled'; others show tooltip 'Not applicable'
    And Logs for a cancelled item append 'Cancelled by user' and stop streaming
    When I open a filtered item via its Logs icon and click 'Back to Workflow'
    Then filters and sort order persist and list position is retained
    When I clear all filters and refresh the page
    Then chips counters revert to global totals and pagination shows correct total pages; default sort and no-filter state are restored
    When I re-apply a saved filter view '<saved_view>' or the same filters
    Then results match prior filtered state and bulk actions behave deterministically

    Examples:
      | filter_statuses        | search_term  | saved_view     |
      | Failed,Broken,Skipped  | restassured  | Failing Only   |

  @ui
  Scenario Outline: Analyze idempotency under rapid retries, queued cancellation, and prevention of duplicates
    Given I open '/roostgpt/workflow' and select a ready Pytest API job
    When I click 'Trigger Analyze' with rapid double-clicks
    Then the button disables and only one analyze request is processed; duplicate attempts are suppressed
    When I simulate a client-side timeout and click 'Retry' upon UI prompt
    Then the server responds with deduplication and no new trigger is produced; a single trigger_id '<idem_trigger>' exists
    When I refresh the Workflow page
    Then a single analyze row exists for the job and status transitions 'Created' -> 'Queued' -> 'Analyzing' without duplicates
    When the status is 'Queued', I click 'Cancel'
    Then the status changes to 'Cancelled' and '/roostgpt/logs?trigger_id=<idem_trigger>' shows 'Cancelled by user' with no further log progression
    When I immediately click 'Trigger Analyze' again
    Then a new trigger_id '<idem_trigger_2>' is created and transitions 'Queued' -> 'Analyzing'
    When I attempt to trigger while '<idem_trigger_2>' is 'Analyzing'
    Then the button is disabled with tooltip 'Analyze already running' and API attempts are rejected with '409 Conflict'
    When I open '/roostgpt/logs?trigger_id=<idem_trigger_2>'
    Then a single continuous log stream appears without interleaving lines from the cancelled attempt
    When I open '/roostgpt/insights?trigger_id=<idem_trigger_2>' after completion
    Then only one successful run is listed and audit history records dedup events without extra runs

    Examples:
      | idem_trigger  | idem_trigger_2 |
      | <masked-idem> | <masked-idem-2> |

  @ui
  Scenario Outline: Connector resilience to repository rename and branch deletion with re-map flow and auditability
    Given I open '/roostgpt/workflow' and a job is configured to repo 'old-name' branch 'dev' project path 'api-tests/rest'
    When I click 'Generate' then 'Trigger Analyze' and allow it to complete successfully (baseline)
    Then the baseline run is 'Completed' with non-zero counters
    When the repository is renamed to 'new-name' and branch 'dev' is deleted in Bitbucket
    And I trigger analyze for the same job
    Then a pre-run validation banner shows 'Repository or branch not found' with options 'Re-map' or 'Skip'
    When I choose '<resolution>'
    Then the run is marked '<post_resolution_status>' with reason '<reason>' and audit entry records action and external 404 details
    When I re-open job configuration and click 'Re-map'
    And I search for 'new-name' and select it; for branch choose 'main'
    Then project path suggestions update based on the new repo
    When I save and trigger analyze
    Then status transitions 'Created' -> 'Queued' -> 'Analyzing' and logs show 'Fetching repo new-name branch main'
    And on completion, Insights counters are non-zero and artifacts reference 'new-name'
    When I validate the Bitbucket connector on '/roostgpt/connectors'
    Then state shows 'Available' with updated last refresh timestamp and no secrets exposed
    And Workflow audit history lists 'Repo renamed detected', 'Branch missing', 'Skip action', and 'Re-map applied' with timestamps and masked IDs

    Examples:
      | resolution | post_resolution_status | reason             |
      | Skip       | Skipped                | Reference missing  |
      | Re-map     | Completed              | Re-mapped to main  |

  @ui
  Scenario Outline: Pytest API insights classification for failed, broken, skipped, xfail/xpass and reconciliation with rerun after fix
    Given I configure a Pytest API job pointing to repo 'pytest-sample', branch 'main', project path 'api-tests/pytest' with marker expression selecting mixed-status tests
    When I trigger analyze and open '/roostgpt/logs?trigger_id=<mixed_trigger>'
    Then logs distinguish 'AssertionError' for failures and 'Error in setup/teardown' for broken and report skipped reasons
    When analyze completes and I open '/roostgpt/insights?trigger_id=<mixed_trigger>'
    Then totals for total, passed, failed, skipped, broken are recorded and non-zero where expected
    When I validate xfail behavior
    Then expected failures are classified '<xfail_policy>' and xpass are classified '<xpass_policy>' with clear messaging
    And no counters show zero when artifacts exist; compile success indicator is present and consistent
    When I click 'View Allure Report'
    Then Allure categories show Failed, Broken, Skipped, and XFailed/XPassed where applicable and totals match Insights
    When I open a broken test deep link to Allure and return
    Then the stack trace and attachments are present and redacted; scroll position in Insights is preserved
    When I filter Insights to show only 'Broken' and export a summary
    Then the exported counts match the on-screen filtered totals
    When I fix the setup error and rerun to create '<fixed_trigger>'
    Then 'broken' count becomes 0 while other counts adjust; Allure and Insights remain aligned

    Examples:
      | mixed_trigger                   | fixed_trigger                    | xfail_policy                     | xpass_policy                             |
      | <masked-pytest-mixed>          | <masked-pytest-fixed>            | Distinct XFailed or mapped to Skipped | Classified per policy (Failed or Broken) |

  # API Tests
  @api
  Scenario Outline: Connectors API - create Bitbucket connector, fetch metadata with retry/backoff, and deny GitLab creation when deprioritized
    Given the API base URL is '<base_url>'
    And the authorization token is set
    When I send a POST request to '/api/connectors' with payload """
    {
      "name": "mayank-account",
      "provider": "<provider>",
      "type": "scm",
      "oauthCode": "masked-consent-code"
    }
    """
    Then the response status should be <create_status>
    And the response should contain '<create_response_field>'
    When I send a GET request to '/api/connectors/<connector_id>/status'
    Then the response status should be 200
    And the response should contain 'status'
    When I send a GET request to '/api/repos?provider=bitbucket'
    Then the response status should be 200
    And the response should contain 'items'
    When I send a GET request to '/api/repos/mayankzbio/restassured/branches'
    Then the response status should be <branches_status>
    And the response should contain '<branches_field>'
    When I send a GET request to '/api/repos/mayankzbio/restassured/metadata?path=sample%2Fpath'
    Then the response status should be <metadata_status>
    And the response should contain '<metadata_field>'
    When I send a POST request to '/api/connectors' with payload """
    {
      "name": "gitlab-deprioritized",
      "provider": "gitlab",
      "type": "scm"
    }
    """
    Then the response status should be <gitlab_create_status>
    And the response should contain '<gitlab_error_field>'

    Examples:
      | base_url          | provider  | create_status | create_response_field | connector_id | branches_status | branches_field | metadata_status | metadata_field | gitlab_create_status | gitlab_error_field            |
      | https://api.local | bitbucket | 201           | id                    | 12345        | 200             | branches       | 200             | projectPath    | 409                   | connectorsDeprioritizedBanner |
      | https://api.local | bitbucket | 201           | id                    | 12345        | 503             | error          | 200             | projectPath    | 409                   | connectorsDeprioritizedBanner |

  @api
  Scenario Outline: Triggers API idempotency and queued cancellation semantics
    Given the API base URL is '<base_url>'
    And the authorization token is set
    When I send a POST request to '/api/triggers' with payload """
    {
      "jobId": "<job_id>",
      "dedupKey": "<dedup_key>"
    }
    """
    Then the response status should be 201
    And the response should contain 'trigger_id'
    When I resend the POST request to '/api/triggers' with the same payload
    Then the response status should be 409
    And the response should contain 'Already queued'
    When I send a GET request to '/api/triggers/<trigger_id>'
    Then the response status should be 200
    And the response should contain 'status'
    When the trigger status is 'Queued'
    And I send a DELETE request to '/api/triggers/<trigger_id>'
    Then the response status should be 202
    And I send a POST request to '/api/triggers' with payload """
    {
      "jobId": "<job_id>",
      "dedupKey": "<dedup_key_2>"
    }
    """
    Then the response status should be 201
    And I send a POST request to '/api/triggers' with payload """
    {
      "jobId": "<job_id>",
      "dedupKey": "<dedup_key_2>"
    }
    """
    Then the response status should be 409
    And the response should contain 'Analyze already running'

    Examples:
      | base_url          | job_id  | dedup_key       | dedup_key_2       | trigger_id                    |
      | https://api.local | job-123 | idem-key-abc    | idem-key-def      | 7886e55c-6a13-41b7-bd19-3b2e68416950 |

  @api
  Scenario Outline: Deep link security via API for invalid, unauthorized, and archived IDs
    Given the API base URL is '<base_url>'
    And the authorization token is set for role '<role>'
    When I send a GET request to '<endpoint>' with query '<query>'
    Then the response status should be <status_code>
    And the response should contain '<expected_field>'

    Examples:
      | base_url          | role    | endpoint                 | query                                     | status_code | expected_field         |
      | https://api.local | none    | /api/logs                | trigger_id=abc123                         | 401         | returnUrl              |
      | https://api.local | viewer  | /api/insights            | trigger_id=00000000-0000-0000-0000-000000000000 | 404         | error                  |
      | https://api.local | viewer  | /api/workflow            | test_id=foreign-123                        | 403         | message                |
      | https://api.local | admin   | /api/workflow            | test_id=foreign-123                        | 403         | message                |
      | https://api.local | admin   | /api/insights            | trigger_id=archived-456                    | 410         | archived               |

  @api
  Scenario Outline: Logs API pagination with cursor tokens ensures ordered, deduplicated sequences across reconnections
    Given the API base URL is '<base_url>'
    And the authorization token is set
    When I send a GET request to '/api/logs/<trigger_id>?cursor=<cursor>'
    Then the response status should be 200
    And the response should contain 'entries'
    And entries are ordered by 'sequence' and contain no duplicates
    When I send a GET request to '/api/logs/<trigger_id>?cursor=<next_cursor>'
    Then the response status should be 200
    And entries continue from the last sequence without gaps

    Examples:
      | base_url          | trigger_id                         | cursor      | next_cursor  |
      | https://api.local | <masked-pytest-trigger>            | start       | start+1000   |

  @api
  Scenario Outline: Allure report regeneration API lifecycle and checksum validation
    Given the API base URL is '<base_url>'
    And the authorization token is set
    When I send a GET request to '/api/reports/<trigger_id>/status'
    Then the response status should be 200
    And the response should contain 'state'
    When the report state is '<initial_state>'
    And I send a POST request to '/api/reports/<trigger_id>/regenerate'
    Then the response status should be <regen_status>
    And I send a GET request to '/api/reports/<trigger_id>/status'
    Then the response should contain 'Completed'
    When I send a GET request to '/api/reports/<trigger_id>/download'
    Then the response status should be 200
    And the response should contain 'checksum'
    When a corrupted download is detected client-side
    Then I send a POST request to '/api/reports/<trigger_id>/regenerate'
    And I may send a DELETE request to '/api/reports/<trigger_id>/job' to cancel regeneration
    Then the response status should be 200 or 202 as applicable
    And the previous valid artifact remains active

    Examples:
      | base_url          | trigger_id                 | initial_state | regen_status |
      | https://api.local | <masked-complete-trigger> | processing    | 202          |
      | https://api.local | <masked-complete-trigger> | missing       | 202          |
