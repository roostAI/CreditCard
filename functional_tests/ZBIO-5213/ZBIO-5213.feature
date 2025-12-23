@api
Feature: Credit Card Collection Lifecycle and Notification System

  Background:
    Given the base URL for the Core Banking API is "https://mock.banking.api"
    And the base URL for the Notification Service API is "https://mock.notification.api"
    And the system is authenticated with a valid API token

  #--------------------------------------------------------------------------------------
  # State Transition Scenarios
  #--------------------------------------------------------------------------------------

  @state_transition @happy_path
  Scenario Outline: Account correctly transitions through delinquency states and triggers notifications
    Given a credit card account exists with PAN ending in "<pan_ending>" and status "<initial_status>"
    And the account has a balance of <balance> and a due date set to "<due_date_offset>"
    And the customer has opted-in for "Email" and "SMS" notifications
    When the system clock is advanced to be <days_to_advance> days past the due date
    And the daily notification and account status update batch job is executed
    Then the account status should be updated to "<expected_status>"
    And a "<notification_type>" notification should be sent for the account
    And the notification content should be accurate and contain the masked PAN "<pan_ending>"

    Examples:
      | pan_ending | initial_status    | balance  | due_date_offset | days_to_advance | expected_status     | notification_type            |
      | "1234"     | "Current"         | 500.00   | "3 days ago"    | -2              | "Payment Due Soon"  | "Credit Card Due Reminder"   |
      | "5678"     | "Payment Due Soon"| 350.00   | "today"         | 1               | "Overdue"           | "Overdue Balance Alert"      |
      | "9012"     | "Overdue"         | 1255.50  | "30 days ago"   | 30              | "In Collections"    | "Collection Notification"    |

  @state_transition @negative
  Scenario: System prevents invalid direct state transition from 'Current' to 'In Collections'
    Given a credit card account exists with PAN ending in "1122", status "Current", and a due date 15 days in the future
    When an API request is sent to manually update the account status to "In Collections"
    Then the API response should be a "400 Bad Request" with an "Invalid state transition" error
    And the account status should remain "Current"
    And no "Collection Notification" should be sent for the account

  #--------------------------------------------------------------------------------------
  # Decision Table / Suppression Rule Scenarios
  #--------------------------------------------------------------------------------------

  @decision_table @suppression
  Scenario Outline: Notifications are suppressed based on specific account conditions
    Given a credit card account exists with PAN ending in "<pan_ending>" and a due date "<days_past_due>" days in the past
    And the account has a balance of <balance>
    And the account is configured with the condition: <condition_description>
    When the daily notification and account status update batch job is executed
    Then no "Overdue Balance Alert" or "Collection Notification" should be sent
    And the application logs should indicate a notification was suppressed due to "<log_reason>"
    And the account status should be updated to "<expected_status>"

    Examples:
      | pan_ending | days_past_due | balance  | condition_description                                | log_reason                  | expected_status |
      | "3344"     | 1             | 400.00   | "Customer has opted-out of all notifications"          | "Customer Opt-Out"          | "Overdue"       |
      | "5566"     | 30            | 2500.00  | "Account is flagged with 'BANKRUPTCY_FILED' status"    | "Bankruptcy Status"         | "In Collections"|
      | "7788"     | 5             | 0.00     | "Account has a zero balance"                           | "Zero Balance"              | "Current"       |
      | "1111"     | 1             | -50.00   | "Account has a credit (negative) balance"              | "Credit Balance"            | "Current"       |

  #--------------------------------------------------------------------------------------
  # Boundary Value Analysis Scenarios
  #--------------------------------------------------------------------------------------

  @boundary_value
  Scenario: 'Due Reminder' is sent on the first day of the window but not before
    Given a credit card account "A" exists with PAN ending in "1010" and a due date 3 days from now
    And a credit card account "B" exists with PAN ending in "2020" and a due date 4 days from now
    When the daily notification batch job is executed
    Then a "Credit Card Due Reminder" should be sent for account "A"
    And no "Credit Card Due Reminder" should be sent for account "B"

  @boundary_value
  Scenario: 'Overdue Alert' is triggered immediately after the due date passes midnight
    Given a credit card account exists with PAN ending in "3030" and a due date of "today"
    When the system clock is set to "23:59:55" on the due date and the notification job is executed
    Then no "Overdue Balance Alert" should be sent for the account
    When the system clock is advanced by 10 seconds to "00:00:05" the next day and the job is executed again
    Then an "Overdue Balance Alert" should be sent for the account
    And the account status should be updated to "Overdue"

  @boundary_value
  Scenario: 'Collection Notification' is triggered on the exact 30th day of delinquency
    Given a credit card account exists with PAN ending in "4040", status "Overdue", and a due date 29 days in the past
    When the daily notification batch job is executed
    Then no "Collection Notification" should be sent for the account
    And the account status should remain "Overdue"
    When the system clock is advanced by 1 day and the job is executed again
    Then a "Collection Notification" should be sent for the account
    And the account status should be updated to "In Collections"

  #--------------------------------------------------------------------------------------
  # Security and PII Masking Scenarios
  #--------------------------------------------------------------------------------------

  @security @pii_masking
  Scenario Outline: PII (PAN) is correctly masked in all notifications and channels
    Given an account is eligible to receive a "<notification_type>"
    And the account's full PAN is "<full_pan>"
    When the notification job runs and generates a notification for the "<channel>" channel
    Then the API payload sent to the notification service must not contain the full PAN
    And the API payload must contain the masked PAN "<masked_pan>"
    And the final rendered content for the "<channel>" must only display the masked PAN

    Examples:
      | notification_type          | channel           | full_pan           | masked_pan         |
      | "Credit Card Due Reminder" | "Email"           | "4242424242421234" | "************1234" |
      | "Overdue Balance Alert"    | "SMS"             | "5555555555555678" | "************5678" |
      | "Collection Notification"  | "Email"           | "373737373734567"  | "***********4567"  |
      | "Collection Notification"  | "SMS"             | "373737373734567"  | "***********4567"  |
      | "Collection Notification"  | "Push Notification" | "373737373734567"  | "***********4567"  |

  #--------------------------------------------------------------------------------------
  # Integration Scenarios
  #--------------------------------------------------------------------------------------

  @integration
  Scenario: Financial data in 'Collection Notification' matches the core banking ledger
    Given a delinquent account with PAN ending in "8888" has the following ledger entries in the core banking system:
      | Entry Type          | Amount   |
      | Principal Balance   | 1500.00  |
      | Late Fees           | 35.00    |
      | Interest Charges    | 22.50    |
    When the notification job generates a "Collection Notification" for this account
    Then the notification body must display a "Total Amount Owed" of "$1,557.50"
    And the notification body must contain an itemized list matching the ledger entries

  @integration @race_condition
  Scenario: 'Overdue Balance Alert' is suppressed if a full payment is posted moments before the job runs
    Given an account with PAN ending in "9999" is "Overdue" with a balance of $250.00
    And the overdue notification job is scheduled to run at "01:00:00"
    When a full payment of $250.00 is posted to the account at "00:59:59"
    And the overdue notification job executes at "01:00:00"
    Then the account status should be updated to "Current" or "Paid" before the job selects it
    And no "Overdue Balance Alert" should be sent for the account

  #--------------------------------------------------------------------------------------
  # Exception Handling Scenarios
  #--------------------------------------------------------------------------------------

  @exception_handling
  Scenario: System gracefully handles notification service API unavailability
    Given an account with PAN ending in "6543" is eligible for a "Credit Card Due Reminder"
    And the mock Notification Service API is configured to return a "503 Service Unavailable" error
    When the notification batch job is executed
    Then the application logs should contain an error for account "6543" stating the service was unavailable
    And the notification request for this account should be marked as "PENDING_RETRY"
    And the batch job should complete without crashing

  @exception_handling
  Scenario: System handles invalid customer contact information without halting the batch
    Given an account with PAN ending in "3210" is eligible for an "Overdue Balance Alert" but has an invalid email "johndoe@invalid-domain"
    And a valid account with PAN ending in "3211" is also eligible for an "Overdue Balance Alert"
    When the notification batch job is executed
    Then the application logs should contain a delivery failure error for account "3210"
    And the notification status for account "3210" should be "FAILED_DELIVERY"
    And an "Overdue Balance Alert" should be successfully sent for the valid account "3211"

  #--------------------------------------------------------------------------------------
  # End-to-End Scenarios
  #--------------------------------------------------------------------------------------

  @e2e @happy_path
  Scenario: A single account progresses through the full delinquency lifecycle
    Given a new account is created with PAN ending in "2222", a balance of $1000, and a due date 30 days from now
    # Stage 1: Reminder
    When the system clock is advanced by 27 days and the notification job is executed
    Then a "Credit Card Due Reminder" is sent and the account status becomes "Payment Due Soon"
    # Stage 2: Overdue
    When the system clock is advanced by another 4 days and the notification job is executed
    Then an "Overdue Balance Alert" is sent, a late fee is added, and the account status becomes "Overdue"
    # Stage 3: Collections
    When the system clock is advanced by another 29 days and the notification job is executed
    Then a "Collection Notification" is sent with the updated total balance, and the account status becomes "In Collections"

  @e2e
  Scenario: Collection lifecycle is interrupted and halted by a full payment
    Given an account with PAN ending in "3333" becomes "Overdue" and an "Overdue Balance Alert" is sent
    And a late fee is added, bringing the total balance to $535.00
    When a full payment of $535.00 is posted to the account
    And the system clock is advanced past the 30-day collection threshold
    And the notification job is executed
    Then the account balance should be $0.00 and its status "Current"
    And no "Collection Notification" should be sent

  @e2e
  Scenario: Collection lifecycle is suppressed by an active dispute flag
    Given an account with PAN ending in "4444" is in "Overdue" status
    When a "DISPUTE_ACTIVE" flag is applied to the account
    And the system clock is advanced past the 30-day collection threshold
    And the notification job is executed
    Then no "Collection Notification" should be sent
    And the account status should not transition to "In Collections" while the dispute is active
