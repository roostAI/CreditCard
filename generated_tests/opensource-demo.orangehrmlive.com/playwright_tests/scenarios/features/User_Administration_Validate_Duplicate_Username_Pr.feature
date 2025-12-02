```gherkin
@user_administration @duplicate_validation @critical @e2e_workflow
Feature: User Administration - Duplicate Username Prevention
  As an HR Administrator
  I want the system to prevent me from creating duplicate usernames
  So that each user has a unique identifier and the system maintains data integrity

  Background:
    Given the OrangeHRM system is accessible and functional
    And I have administrator credentials with user management permissions
    And a user with username "Admin" already exists in the system
    And an employee record "Aparna123 4Ys 010Z" exists in the system

  @duplicate_username @form_validation @data_integrity
  Scenario: Validate system prevents creation of user with duplicate username and displays error message
    Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
    And I should see the dashboard page loaded successfully
    And my authenticated session is active
    
    # Navigate to User Administration Section
    When I click on the "Admin" link in the main navigation menu
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/viewSystemUsers"
    And I should see the "System Users" page title
    And I should see the list of existing system users displayed
    And I should see the "Add" button available in the user list header
    
    # Initiate User Creation Workflow
    When I click on the "Add" button
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/saveSystemUser"
    And I should see the "Add User" form page loaded
    And I should see the "User Role" dropdown field displayed
    And I should see the "Employee Name" autocomplete field displayed
    And I should see the "Status" dropdown field displayed
    And I should see the "Username" input field displayed
    And I should see the "Password" input field displayed
    And I should see the "Confirm Password" input field displayed
    And I should see the "Save" button displayed
    And I should see the "Cancel" button displayed
    
    # Select User Role
    When I click on the "User Role" dropdown field
    Then I should see the User Role dropdown menu expanded
    And I should see the "-- Select --" placeholder text
    And I should see "Admin" option available in the dropdown
    And I should see "ESS" option available in the dropdown
    
    When I click on the "Admin" option from the User Role dropdown
    Then the "User Role" dropdown should display "Admin" as selected value
    And the User Role dropdown menu should close
    
    # Select Employee Name
    When I click on the "Employee Name" autocomplete field
    And I type "Test" into the "Employee Name" autocomplete field
    Then I should see autocomplete suggestions appear below the field
    And I should see "Aparna123 4Ys 010Z" in the autocomplete dropdown suggestions
    
    When I click on "Aparna123 4Ys 010Z" from the autocomplete suggestions
    Then the "Employee Name" field should display "Aparna123 4Ys 010Z" as selected value
    And the autocomplete dropdown should close
    
    # Select Status
    When I click on the "Status" dropdown field
    Then I should see the Status dropdown menu expanded
    And I should see the "-- Select --" placeholder text
    And I should see "Enabled" option available in the dropdown
    And I should see "Disabled" option available in the dropdown
    
    When I click on the "Enabled" option from the Status dropdown
    Then the "Status" dropdown should display "Enabled" as selected value
    And the Status dropdown menu should close
    
    # Enter Duplicate Username - Critical Test Point
    When I click on the "Username" input field
    And I type "Admin" into the "Username" field
    Then the "Username" field should contain the value "Admin"
    
    # Enter Password
    When I click on the "Password" input field
    And I type "Test@123" into the "Password" field
    Then the "Password" field should be masked
    And the "Password" field should contain 8 characters
    
    # Enter Confirm Password
    When I click on the "Confirm Password" input field
    And I type "Test@123" into the "Confirm Password" field
    Then the "Confirm Password" field should be masked
    And the "Confirm Password" field should contain 8 characters
    
    # Verify Form State Before Submission
    And the "User Role" field should have "Admin" selected
    And the "Employee Name" field should have "Aparna123 4Ys 010Z" selected
    And the "Status" field should have "Enabled" selected
    And the "Username" field should contain "Admin"
    And the "Password" field should be filled
    And the "Confirm Password" field should be filled
    And the "Save" button should be enabled
    
    # Submit Form to Trigger Duplicate Username Validation
    When I click on the "Save" button
    Then I should remain on the page "https://opensource-demo.orangehrmlive.com/web/index.php/admin/saveSystemUser"
    And I should not be redirected to the System Users list page
    And I should see an error message "Already exists" displayed below the "Username" field
    And the error message should be styled with error indication
    And the "Username" field should be highlighted with error styling
    And the user account should not be created in the system
    And the form should remain populated with previously entered data
    
    # Verify Data Integrity
    And no duplicate username "Admin" should exist in the system database
    And the existing user "Admin" should remain unchanged
    And the system should maintain data integrity with unique usernames only
    
    # Verify Form Remains Interactive for Correction
    And the "User Role" field should remain editable
    And the "Employee Name" field should remain editable
    And the "Status" field should remain editable
    And the "Username" field should remain editable for correction
    And the "Password" field should remain editable
    And the "Confirm Password" field should remain editable
    And the "Save" button should remain enabled
    And the "Cancel" button should remain enabled

  @edge_case @username_case_sensitivity
  Scenario Outline: Validate username uniqueness with different case variations
    Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
    And I should see the dashboard page loaded successfully
    
    When I click on the "Admin" link in the main navigation menu
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/viewSystemUsers"
    
    When I click on the "Add" button
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/saveSystemUser"
    
    When I click on the "User Role" dropdown field
    And I click on the "Admin" option from the User Role dropdown
    Then the "User Role" dropdown should display "Admin" as selected value
    
    When I click on the "Employee Name" autocomplete field
    And I type "Test" into the "Employee Name" autocomplete field
    And I click on "Aparna123 4Ys 010Z" from the autocomplete suggestions
    Then the "Employee Name" field should display "Aparna123 4Ys 010Z" as selected value
    
    When I click on the "Status" dropdown field
    And I click on the "Enabled" option from the Status dropdown
    Then the "Status" dropdown should display "Enabled" as selected value
    
    When I click on the "Username" input field
    And I type "<username_variation>" into the "Username" field
    Then the "Username" field should contain the value "<username_variation>"
    
    When I click on the "Password" input field
    And I type "Test@123" into the "Password" field
    And I click on the "Confirm Password" input field
    And I type "Test@123" into the "Confirm Password" field
    
    When I click on the "Save" button
    Then I should see the validation result "<expected_result>"
    And the duplicate prevention behavior should be "<behavior>"
    
    Examples:
      | username_variation | expected_result           | behavior                |
      | admin             | Already exists            | Duplicate prevented     |
      | ADMIN             | Already exists            | Duplicate prevented     |
      | AdMiN             | Already exists            | Duplicate prevented     |
      | aDmIn             | Already exists            | Duplicate prevented     |

  @edge_case @username_whitespace
  Scenario: Validate username with leading and trailing spaces is handled correctly
    Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
    And I should see the dashboard page loaded successfully
    
    When I click on the "Admin" link in the main navigation menu
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/viewSystemUsers"
    
    When I click on the "Add" button
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/saveSystemUser"
    
    When I click on the "User Role" dropdown field
    And I click on the "Admin" option from the User Role dropdown
    Then the "User Role" dropdown should display "Admin" as selected value
    
    When I click on the "Employee Name" autocomplete field
    And I type "Test" into the "Employee Name" autocomplete field
    And I click on "Aparna123 4Ys 010Z" from the autocomplete suggestions
    Then the "Employee Name" field should display "Aparna123 4Ys 010Z" as selected value
    
    When I click on the "Status" dropdown field
    And I click on the "Enabled" option from the Status dropdown
    Then the "Status" dropdown should display "Enabled" as selected value
    
    When I click on the "Username" input field
    And I type " Admin " into the "Username" field with leading and trailing spaces
    Then the "Username" field should contain the value " Admin "
    
    When I click on the "Password" input field
    And I type "Test@123" into the "Password" field
    
    When I click on the "Confirm Password" input field
    And I type "Test@123" into the "Confirm Password" field
    
    When I click on the "Save" button
    Then the system should either trim the spaces and show "Already exists" error
    Or the system should validate spaces as part of username
    And the duplicate prevention logic should handle whitespace consistently

  @positive_flow @successful_user_creation
  Scenario: Verify successful user creation with unique username after duplicate error correction
    Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
    And I should see the dashboard page loaded successfully
    
    When I click on the "Admin" link in the main navigation menu
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/viewSystemUsers"
    
    When I click on the "Add" button
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/saveSystemUser"
    
    # First attempt with duplicate username
    When I click on the "User Role" dropdown field
    And I click on the "Admin" option from the User Role dropdown
    
    When I click on the "Employee Name" autocomplete field
    And I type "Test" into the "Employee Name" autocomplete field
    And I click on "Aparna123 4Ys 010Z" from the autocomplete suggestions
    
    When I click on the "Status" dropdown field
    And I click on the "Enabled" option from the Status dropdown
    
    When I click on the "Username" input field
    And I type "Admin" into the "Username" field
    
    When I click on the "Password" input field
    And I type "Test@123" into the "Password" field
    
    When I click on the "Confirm Password" input field
    And I type "Test@123" into the "Confirm Password" field
    
    When I click on the "Save" button
    Then I should see an error message "Already exists" displayed below the "Username" field
    And I should remain on the page "https://opensource-demo.orangehrmlive.com/web/index.php/admin/saveSystemUser"
    
    # Correct the username and retry
    When I clear the "Username" field completely
    And I click on the "Username" input field
    And I type "TestUser_2024" into the "Username" field
    Then the "Username" field should contain the value "TestUser_2024"
    And the error message "Already exists" should no longer be displayed
    And the "Username" field should not have error styling
    
    When I click on the "Save" button
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/viewSystemUsers"
    And I should see a success message indicating user was created successfully
    And I should see "TestUser_2024" in the system users list
    And the new user record should be visible with User Role "Admin"
    And the new user record should be visible with Employee Name "Aparna123 4Ys 010Z"
    And the new user record should be visible with Status "Enabled"

  @error_message_validation @ui_feedback
  Scenario: Verify error message appearance and styling for duplicate username
    Given I am on the homepage "https://opensource-demo.orangehrmlive.com/web/index.php/dashboard/index"
    And I should see the dashboard page loaded successfully
    
    When I click on the "Admin" link in the main navigation menu
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/viewSystemUsers"
    
    When I click on the "Add" button
    Then I should be redirected to "https://opensource-demo.orangehrmlive.com/web/index.php/admin/saveSystemUser"
    
    # Verify no error message initially
    And I should not see any error message below the "Username" field
    And the "Username" field should not have error styling
    
    When I click on the "User Role" dropdown field
    And I click on the "Admin" option from the User Role dropdown
    
    When I click on the "Employee Name" autocomplete field
    And I type "Test" into the "Employee Name" autocomplete field
    And I click on "Aparna123 4Ys 010Z" from the autocomplete suggestions
    
    When I click on the "Status" dropdown field
    And I click on the "Enabled" option from the Status dropdown
    
    When I click on the "Username" input field
    And I type "Admin" into the "Username" field
    
    When I click on the "Password" input field
    And I type "Test@123" into the "Password" field
    
    When I click on the "Confirm Password" input field
    And I type "Test@123" into the "Confirm Password" field
    
    When I click on the "Save" button
    Then I should see an error message "Already exists" displayed below the "Username" field
    And the error message should be in red color or error styling
    And the error message should be clearly visible to the user
    And the "Username" field should have error border styling
    And the error message should be positioned directly below the "Username" field
    And the error message should be easily readable
    
    # Verify error message persistence
    When I click on a different field outside the username field
    Then the error message "Already exists" should remain visible
    And the "Username" field should maintain error styling
    
    # Verify error clears when username is modified
    When I click on the "Username" input field
    And I modify the username to "TestUser123"
    And I click outside the "Username" field
    Then the error message "Already exists" should be cleared or hidden
    And the "Username" field should no longer have error styling
```

This comprehensive Gherkin feature file includes:

1. **Complete atomic step breakdown** - Each action is a separate, testable step
2. **Explicit navigation tracking** - Every page transition is documented with URL verification
3. **Granular form interactions** - Each field interaction is separated and verified
4. **Multiple scenario coverage** - Main flow plus edge cases and positive validation
5. **Detailed verification steps** - Each action followed by appropriate validation
6. **Realistic test data** - Specific values provided for all inputs
7. **No assumptions** - Every click, type, and verification explicitly stated
8. **Automation-ready** - Precise element descriptions and expected behaviors
9. **Business context** - Tags and descriptions provide clear test purpose
10. **Independent execution** - Each scenario starts from homepage with full context