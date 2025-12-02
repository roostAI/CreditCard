# Feature: OrangeHRM User Authentication and Dashboard Access

## Business Value
As a registered OrangeHRM user, I need to authenticate with my credentials to access the HR management system dashboard and perform my daily HR administrative tasks. Successful authentication is critical for ensuring authorized access to sensitive employee data and HR operations.

## Feature Description
This feature validates the complete end-to-end authentication workflow for the OrangeHRM demo application. It covers the entire user journey from initial page load, through credential submission, to successful dashboard access with an established authenticated session.

## Priority: Critical
## Test Type: E2E Authentication Workflow

Background:
  Given the OrangeHRM demo site is accessible and operational
  And the authentication service is responding normally
  And no existing authenticated session is active in the browser
  And the test credentials are valid and active

@authentication @critical @happy-path @e2e @login
Scenario: Successful login to OrangeHRM with valid credentials
  # Step 1: Initial Navigation and Auto-Redirect
  Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  Then I should be automatically redirected to the login page
  And I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  And the login form should be visible
  And the page title should contain "OrangeHRM"
  
  # Step 2: Username Input Interaction
  When I locate the "Username" textbox field on the login form
  And I click on the "Username" textbox field
  And I fill in the "Username" field with "Admin"
  Then the "Username" field should contain the value "Admin"
  And the "Username" field should accept the input without errors
  And I should remain on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  
  # Step 3: Password Input Interaction
  When I locate the "Password" textbox field on the login form
  And I click on the "Password" textbox field
  And I fill in the "Password" field with "admin123"
  Then the "Password" field should be masked for security
  And the "Password" field should accept the input without errors
  And I should remain on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  
  # Step 4: Form Submission
  When I locate the "Login" button on the login form
  And I click on the "Login" button
  Then the login form should be submitted
  And the authentication request should be processed
  And no validation errors should be displayed
  
  # Step 5: Post-Authentication Navigation Verification
  Then I should be redirected to the authenticated dashboard
  And I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And the URL should change from "/auth/login" to "/dashboard/index"
  And the login page should no longer be visible
  
  # Step 6: Authenticated Dashboard State Verification
  Then the dashboard page should load completely
  And the page should display authenticated user context
  And the main navigation menu should be visible
  And the dashboard header should be present
  And the user profile section should be visible
  And the page title should indicate successful authentication
  And the authenticated session should be established
  And I should have full access to HR management features

@authentication @critical @validation @negative
Scenario: Login page displays correct form structure and elements
  # Validate login page structure before interaction
  Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  Then I should be automatically redirected to the login page
  And I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  
  When I examine the login form structure
  Then the "Username" textbox field should be present
  And the "Username" field should be empty by default
  And the "Username" field should have appropriate label text "Username"
  
  And the "Password" textbox field should be present
  And the "Password" field should be empty by default
  And the "Password" field should have appropriate label text "Password"
  And the "Password" field should have password masking enabled
  
  And the "Login" button should be present
  And the "Login" button should be enabled
  And the "Login" button should display the text "Login"
  
  And the login form should be ready for user interaction
  And no error messages should be displayed initially

@authentication @critical @session @state-management
Scenario: Authenticated session prevents access to login page
  # Verify authenticated users cannot access login page
  Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And I should be automatically redirected to the login page
  And I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  
  When I fill in the "Username" field with "Admin"
  And I fill in the "Password" field with "admin123"
  And I click on the "Login" button
  Then I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And the authenticated session should be active
  
  When I attempt to navigate directly to "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  Then I should be redirected back to the dashboard
  Or I should remain on the page "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And the authenticated session should remain active
  And I should not see the login form

@authentication @critical @navigation @url-handling
Scenario: Direct dashboard URL access redirects unauthenticated users to login
  # Verify security: unauthenticated access redirects to login
  Given I have no active authenticated session
  And I clear all browser cookies and session data
  
  When I navigate directly to "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  Then I should be automatically redirected to the login page
  And I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  And the dashboard should not be accessible
  And the login form should be displayed
  And the "Username" field should be visible
  And the "Password" field should be visible
  And the "Login" button should be visible

@authentication @critical @data-persistence @form-state
Scenario: Login form fields retain input during single session
  # Verify form state management during user interaction
  Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  Then I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  
  When I fill in the "Username" field with "Admin"
  Then the "Username" field should display "Admin"
  
  When I click on the "Password" field
  Then the "Username" field should still contain "Admin"
  And the previously entered username should remain visible
  
  When I fill in the "Password" field with "admin123"
  Then the "Password" field should contain masked characters
  And the "Username" field should still contain "Admin"
  And both fields should retain their values
  
  When I click on the "Login" button
  Then both credential values should be submitted together
  And I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"

@authentication @critical @ui-feedback @user-experience
Scenario: Login form provides appropriate visual feedback during interaction
  # Validate user interface feedback and state changes
  Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  Then I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  
  When I click on the "Username" field
  Then the "Username" field should receive focus
  And the field should display focus indicator styling
  
  When I type "Admin" into the "Username" field
  Then each character should appear immediately in the field
  And the field should show active input state
  
  When I click on the "Password" field
  Then the "Username" field should lose focus
  And the "Password" field should receive focus
  And the "Password" field should display focus indicator styling
  
  When I type "admin123" into the "Password" field
  Then the password characters should be masked
  And each character should be hidden for security
  And the field should show active input state
  
  When I hover over the "Login" button
  Then the button should display hover state styling
  
  When I click on the "Login" button
  Then the button should indicate processing state
  And the form should show submission in progress
  And I should receive visual feedback that login is being processed

## Edge Cases and Additional Validations

@authentication @edge-case @network @performance
Scenario: Login succeeds despite slow network conditions
  # Test authentication resilience under network latency
  Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  And network conditions are simulated as slow
  
  When I fill in the "Username" field with "Admin"
  And I fill in the "Password" field with "admin123"
  And I click on the "Login" button
  Then the authentication request should be sent
  And the system should wait for server response
  And loading indicators should be displayed during processing
  
  When the authentication response is received
  Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And the authenticated session should be established successfully
  And the dashboard should load completely despite network delay

@authentication @edge-case @browser-behavior @back-navigation
Scenario: Browser back button behavior after successful authentication
  # Validate session handling with browser navigation controls
  Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  
  When I fill in the "Username" field with "Admin"
  And I fill in the "Password" field with "admin123"
  And I click on the "Login" button
  Then I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And the authenticated session should be active
  
  When I click the browser back button
  Then I should not return to the login page with filled credentials
  And I should either remain on the dashboard or be redirected back to dashboard
  And the authenticated session should remain active
  And sensitive credential data should not be exposed in browser history

@authentication @edge-case @multi-click @button-interaction
Scenario: Multiple rapid login button clicks do not cause duplicate submissions
  # Test form submission idempotency and duplicate prevention
  Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  
  When I fill in the "Username" field with "Admin"
  And I fill in the "Password" field with "admin123"
  And I click on the "Login" button rapidly multiple times
  Then only one authentication request should be sent to the server
  And duplicate submissions should be prevented
  And the login button should be disabled during processing
  
  When the authentication completes
  Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index" exactly once
  And no duplicate sessions should be created
  And the authenticated state should be clean and consistent

@authentication @edge-case @tab-management @session-sharing
Scenario: Opening dashboard URL in new tab while already authenticated
  # Validate session sharing across browser tabs
  Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/auth/login"
  
  When I fill in the "Username" field with "Admin"
  And I fill in the "Password" field with "admin123"
  And I click on the "Login" button
  Then I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
  And the authenticated session should be established in the current tab
  
  When I open a new browser tab
  And I navigate to "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index" in the new tab
  Then the new tab should recognize the existing authenticated session
  And I should directly access the dashboard without re-authentication
  And I should be on the page "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index" in the new tab
  And both tabs should share the same authenticated session state

## Data Requirements
# Valid Credentials: Username: "Admin", Password: "admin123"
# Network: Stable HTTPS connection
# Browser: JavaScript enabled, session storage capable
# Environment: OrangeHRM demo site operational at opensource-demo.orangehrmlive.com

## Prerequisites
# - OrangeHRM demo application is accessible and operational
# - Authentication service endpoints are responding
# - Test credentials (Admin/admin123) are valid and active
# - Browser supports modern web standards, cookies, and session management
# - No conflicting authenticated sessions exist before test execution