@api
Feature: Credit Card Account Lifecycle and Notification Management
  As a banking system, I need to manage the credit card account lifecycle from current to collections,
  triggering accurate and secure notifications at each stage, and correctly processing payments and other events.

  Background:
    Given the API base URL is "https://api.bank.com/v1"
    And the system has a valid authentication token for privileged operations

  @lifecycle @happy_path
  Scenario: TC-001 E2E Happy Path - Full Lifecycle with On-Time Payment
    Given a "Current" credit card account "acc-happy-path" exists with a balance of $0.00
    When I generate a new statement for account "acc-happy-path" with a balance of $500.00 and a due date in 30 days
    And I advance the system clock to 5 days before the due date
    And I run the notification batch job
    Then a "Credit Card Due Reminder" notification should be sent for account "acc-happy-path"
    And the notification must contain the statement balance "$500.00" and the correct due date
    And the notification must contain the masked PAN ending in the correct last 4 digits for "acc-happy-path"
    When I simulate a payment for account "acc-happy-path" with the full amount of $500.00
    And I advance the system clock to 1 day after the due date
    And I run the delinquency batch job
    Then the state of account "acc-happy-path" should be "Current"
    And no "Overdue Balance Alert" should have been sent for account "acc-happy-path"

  @lifecycle @delinquency
  Scenario: TC-002 E2E Delinquency Path - Transition to Collections
    Given a "Payment Due" credit card account "acc-delinquent" exists with a balance of $1000.00
    And the collections trigger is set to 30 days past due
    When I advance the system clock to 1 day after the due date
    And I run the delinquency batch job
    Then the state of account "acc-delinquent" should be "Overdue"
    And an "Overdue Balance Alert" should be sent for account "acc-delinquent" with the correct overdue amount
    When I advance the system clock by 29 days
    And I run the delinquency batch job
    Then the state of account "acc-delinquent" should be "In Collections"
    And a "Collection Notification" should be sent for account "acc-delinquent" with the total amount owed

  @lifecycle @recovery
  Scenario: TC-003 E2E Recovery Path - Payment Made While Overdue
    Given an "Overdue" credit card account "acc-recovery" exists, 15 days past due with a total balance of $535.00
    When I simulate a payment for account "acc-recovery" with the full amount of $535.00
    Then the state of account "acc-recovery" should immediately become "Current"
    And the balance of account "acc-recovery" should be $0.00
    When I advance the system clock to 31 days past the original due date
    And I run the delinquency batch job
    Then the state of account "acc-recovery" should remain "Current"
    And no "Collection Notification" should have been sent for account "acc-recovery"

  @state_transition @payment
  Scenario Outline: TC-012, TC-013, TC-036 Verify account state based on payment amount relative to minimum due
    Given a "Payment Due" account "<accountId>" has a statement balance of $1000.00 and a minimum due of $50.00
    When I simulate a payment for account "<accountId>" with an amount of <payment_amount> before the due date
    And I advance the system clock to 1 day after the due date
    And I run the delinquency batch job
    Then the state of account "<accountId>" should be "<expected_state>"
    And the "Overdue Balance Alert" sent status for account "<accountId>" should be <alert_sent>

    Examples:
      | accountId      | payment_amount | expected_state | alert_sent |
      | "acc-partial-1"| "$49.99"       | "Overdue"      | true       |
      | "acc-partial-2"| "$50.00"       | "Current"      | false      |
      | "acc-partial-3"| "$50.01"       | "Current"      | false      |

  @state_transition @negative
  Scenario: TC-005 Attempt an invalid state transition from 'Current' to 'In Collections'
    Given a "Current" credit card account "acc-invalid-trans" exists
    When I send a "PUT" request to "/api/accounts/acc-invalid-trans/state" with payload
      """
      {
        "state": "In Collections"
      }
      """
    Then the response status should be "400"
    And the response body should contain an error message "Invalid state transition"
    And the state of account "acc-invalid-trans" should remain "Current"
    And an audit log should be created for the failed state change attempt

  @security @pii
  Scenario Outline: TC-006, TC-007, TC-026, TC-034 Verify full PAN is not exposed in system outputs
    Given a test account "acc-pii-check" has a full PAN of "4444555566661234"
    When an "Overdue Balance Alert" is triggered for account "acc-pii-check"
    And the email delivery service is configured to fail to generate error logs
    Then I must verify the full PAN "4444555566661234" is not present in the "<output_source>"

    Examples:
      | output_source                       |
      | "raw HTML source of the email"      |
      | "application error logs"            |
      | "URL query parameters of payment links" |
      | "raw JSON payload of the push notification" |

  @boundary @notification
  Scenario Outline: TC-008, TC-010 Verify notifications are triggered on the precise boundary day
    Given an account "<accountId>" is configured to trigger a "<notification_type>"
    And the trigger day is <trigger_day> relative to the due date
    When I set the system date to <days_relative_to_due_date> days relative to the due date
    And I run the relevant batch job
    Then the "<notification_type>" sent status for account "<accountId>" should be <should_be_sent>

    Examples:
      | accountId     | notification_type          | trigger_day | days_relative_to_due_date | should_be_sent |
      | "acc-bound-1" | "Credit Card Due Reminder" | -5          | -6                        | false          |
      | "acc-bound-2" | "Credit Card Due Reminder" | -5          | -5                        | true           |
      | "acc-bound-3" | "Credit Card Due Reminder" | -5          | -4                        | false          |
      | "acc-bound-4" | "Collection Notification"  | 30          | 29                        | false          |
      | "acc-bound-5" | "Collection Notification"  | 30          | 30                        | true           |
      | "acc-bound-6" | "Collection Notification"  | 30          | 31                        | false          |

  @boundary @payment
  Scenario: TC-009 Verify payment processing at the midnight boundary
    Given two "Payment Due" accounts "acc-ontime" and "acc-late" have a due date of today
    When I set the system time to "23:59" on the due date
    And I simulate a full payment for account "acc-ontime"
    And I advance the system clock by 2 minutes to "00:01" the next day
    And I run the delinquency batch job
    Then the state of account "acc-ontime" should be "Current"
    And the state of account "acc-late" should be "Overdue"
    And an "Overdue Balance Alert" should be sent for account "acc-late"
    And no "Overdue Balance Alert" should have been sent for account "acc-ontime"

  @grace_period @suppression
  Scenario: TC-011, TC-041 Verify notification suppression by a last-minute payment
    Given an account "acc-grace" becomes "Overdue" at 00:01
    And an "Overdue Balance Alert" is scheduled in the notification queue for "acc-grace" with status "Pending"
    When I simulate a full payment for account "acc-grace" at 01:30
    Then the state of account "acc-grace" should revert to "Current"
    And the status of the scheduled alert for "acc-grace" in the notification queue should be updated to "Cancelled"
    When I advance the system clock to 02:01
    And the notification batch job has run
    Then I verify from delivery logs that the alert for "acc-grace" was not sent

  @reversal
  Scenario: TC-014 Bounced payment correctly reverts account to Overdue
    Given a "Payment Due" account "acc-reversal" has a due date of today
    When I simulate a full payment for account "acc-reversal" on the due date
    And I verify the account state is "Current"
    And I advance the system clock by 3 days
    And I simulate a payment reversal event for the last payment on account "acc-reversal"
    Then the state of account "acc-reversal" should be retroactively changed to "Overdue"
    And an "Overdue Balance Alert" should be triggered immediately for account "acc-reversal"

  @non_functional @time
  Scenario: TC-016 Verify time zone differences are handled correctly
    Given the bank server operates in "EST" and a customer's profile for account "acc-timezone" is "PST"
    And the payment due date for "acc-timezone" is today
    When I simulate a full payment for account "acc-timezone" at "22:00 PST"
    # This is 01:00 EST on the next day
    Then the payment transaction posting time should be recorded based on "EST"
    And the payment should be considered late
    And the state of account "acc-timezone" should become "Overdue"

  @notification @content
  Scenario Outline: TC-022, TC-023 Verify notification content for accuracy and completeness
    Given an account "<accountId>" is in a state to trigger a "<notification_type>"
    When the "<notification_type>" is generated for account "<accountId>"
    Then the notification must contain all required fields: <required_fields>
    And all financial data in the notification must be accurate based on the account's state
    And the notification must contain the masked PAN for account "<accountId>"

    Examples:
      | accountId     | notification_type         | required_fields                                                                                             |
      | "acc-cont-1"  | "Overdue Balance Alert"   | "customer name, masked PAN, overdue amount, total balance, due date, payment instructions"                  |
      | "acc-cont-2"  | "Collection Notification" | "legal disclosure, masked PAN, total amount owed, payment deadline, collections department contact info"    |

  @communication_preference
  Scenario Outline: TC-028, TC-029, TC-035 Verify notifications respect customer communication preferences
    Given an account "<accountId>" is overdue
    And the communication preference for the customer of account "<accountId>" is set to "<preference>"
    When I run the notification batch job
    Then an email notification sent status for account "<accountId>" should be <email_sent>
    And an SMS notification sent status for account "<accountId>" should be <sms_sent>
    And a push notification sent status for account "<accountId>" should be <push_sent>

    Examples:
      | accountId     | preference        | email_sent | sms_sent | push_sent |
      | "acc-pref-1"  | "Email Only"      | true       | false    | false     |
      | "acc-pref-2"  | "SMS Only"        | false      | true     | false     |
      | "acc-pref-3"  | "Do Not Contact"  | false      | false    | false     |

  @idempotency
  Scenario: TC-030 Verify duplicate notification prevention
    Given an account "acc-idem" is in a state to trigger a "Credit Card Due Reminder" today
    When I run the notification batch job
    Then exactly 1 "Credit Card Due Reminder" should be sent for account "acc-idem"
    When I run the notification batch job again on the same day
    Then no new notification should be sent for account "acc-idem"

  @boundary @sanity_check
  Scenario: TC-032 Verify no collection notifications for a zero balance account
    Given an account "acc-zero-bal" has a statement generated with a balance of $0.00
    When I advance the system clock through its entire billing cycle (reminder day and day after due)
    And I run all relevant batch jobs
    Then no "Credit Card Due Reminder" should be sent for account "acc-zero-bal"
    And no "Overdue Balance Alert" should be sent for account "acc-zero-bal"
    And the state of account "acc-zero-bal" should remain "Current"

  @error_handling
  Scenario: TC-037 Verify graceful failure for an account with no contact information
    Given an account "acc-no-contact" is overdue but has no email or phone number on file
    When I run the notification batch job
    Then the system should log a specific error "Missing Contact Information" for account "acc-no-contact"
    And the batch job should complete without crashing
    And no notification should be sent for account "acc-no-contact"

  @state_transition @account_management
  Scenario: TC-038 Verify account closure ceases the collection notification lifecycle
    Given an "Overdue" account "acc-closed" is 10 days past due
    When I send a "PUT" request to "/api/accounts/acc-closed/status" to close the account
    And I advance the system clock to 30 days past the original due date
    And I run the delinquency batch job
    Then the state of account "acc-closed" should remain "Closed"
    And no automated "Collection Notification" should have been sent for account "acc-closed"
