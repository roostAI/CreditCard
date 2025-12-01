Feature: Credit Card Collection Lifecycle Notification System
  As a credit card company
  I want to automate the collection lifecycle notification process
  So that cardholders receive timely reminders and alerts about payment obligations while maintaining security and compliance

  Background:
    Given the notification system is operational
    And the cardholder database is accessible
    And all communication channels are configured
    And security controls for card number masking are enabled

  # ==========================================
  # FUNCTIONAL TEST SCENARIOS
  # ==========================================

  @functional @due-reminder @positive
  Scenario Outline: Send automated due reminder notification before payment due date
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the payment due date is '<due_date>'
    And the payment due amount is '<amount>'
    And the cardholder contact information is valid
    And the current date is '<days_before>' days before the due date
    When the automated reminder system triggers the notification
    Then a due reminder notification should be sent to the cardholder
    And the notification should include the payment due date '<due_date>'
    And the notification should include the payment due amount '<amount>'
    And the notification should display only the last 4 digits '<last_4_digits>' of the credit card
    And the notification should NOT display the full credit card number
    And the notification should include clear payment instructions
    And the notification should include late payment fee information
    And the notification delivery should be logged with timestamp

    Examples:
      | account_id | last_4_digits | due_date   | amount  | days_before |
      | ACC-001    | 1234          | 2024-02-15 | 250.00  | 5           |
      | ACC-002    | 5678          | 2024-02-20 | 1500.50 | 3           |
      | ACC-003    | 9012          | 2024-02-28 | 75.25   | 4           |
      | ACC-004    | 3456          | 2024-03-01 | 3200.00 | 5           |

  @functional @due-reminder @multi-channel
  Scenario Outline: Send due reminder through multiple communication channels
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the cardholder has email '<email>' configured
    And the cardholder has phone number '<phone>' configured
    And the cardholder has app notifications enabled set to '<app_enabled>'
    And the payment due date is 5 days in the future
    When the automated reminder system triggers the notification
    Then an email notification should be sent to '<email>'
    And an SMS notification should be sent to '<phone>'
    And an app push notification should be sent if '<app_enabled>' is 'true'
    And all notifications should display only last 4 digits '<last_4_digits>'
    And all channel deliveries should be logged separately

    Examples:
      | account_id | last_4_digits | email                    | phone          | app_enabled |
      | ACC-005    | 7890          | john.doe@email.com       | +1-555-0101    | true        |
      | ACC-006    | 2468          | jane.smith@email.com     | +1-555-0102    | false       |
      | ACC-007    | 1357          | bob.wilson@email.com     | +1-555-0103    | true        |
      | ACC-008    | 9753          | alice.brown@email.com    | +1-555-0104    | true        |

  @functional @overdue-alert @positive
  Scenario Outline: Trigger and send overdue balance alert after missed payment due date
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the payment due date '<due_date>' has passed
    And no payment has been recorded for the due date
    And the overdue amount is '<overdue_amount>'
    And the current date is '<days_overdue>' days past the due date
    When the overdue balance detection process is triggered
    Then an overdue balance alert should be generated
    And the alert should be sent to the cardholder via all configured channels
    And the alert should include the overdue amount '<overdue_amount>'
    And the alert should include the original due date '<due_date>'
    And the alert should display only last 4 digits '<last_4_digits>'
    And the alert should state potential consequences of non-payment
    And the alert should include payment instructions
    And the alert should mention late fees and interest charges if applicable
    And the alert should be logged in the system with status 'SENT'

    Examples:
      | account_id | last_4_digits | due_date   | overdue_amount | days_overdue |
      | ACC-009    | 4321          | 2024-01-15 | 250.00         | 5            |
      | ACC-010    | 8765          | 2024-01-10 | 1500.50        | 10           |
      | ACC-011    | 2109          | 2024-01-20 | 75.25          | 3            |
      | ACC-012    | 6543          | 2024-01-05 | 3200.00        | 15           |

  @functional @overdue-alert @negative
  Scenario Outline: Do not send overdue alert if payment was made
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the payment due date '<due_date>' has passed
    And a payment of '<payment_amount>' was recorded on '<payment_date>'
    And the current date is '<days_overdue>' days past the due date
    When the overdue balance detection process is triggered
    Then an overdue balance alert should NOT be generated
    And no notification should be sent to the cardholder
    And the account status should be '<expected_status>'

    Examples:
      | account_id | last_4_digits | due_date   | payment_amount | payment_date | days_overdue | expected_status |
      | ACC-013    | 1111          | 2024-01-15 | 250.00         | 2024-01-14   | 5            | PAID            |
      | ACC-014    | 2222          | 2024-01-10 | 1500.50        | 2024-01-09   | 10           | PAID            |
      | ACC-015    | 3333          | 2024-01-20 | 75.25          | 2024-01-20   | 3            | PAID            |

  @functional @collection-notification @positive
  Scenario Outline: Send formal collection notification for significantly delinquent account
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the account has been overdue for '<days_delinquent>' days
    And the total overdue amount is '<total_overdue>'
    And previous reminder notifications were sent on '<reminder_dates>'
    And previous overdue alerts were sent on '<overdue_dates>'
    And the account is flagged for collection escalation
    When the collection notification process is triggered
    Then a formal collection notification should be generated
    And the notification should include total amount owed '<total_overdue>'
    And the notification should include a detailed breakdown of charges
    And the notification should itemize late fees '<late_fees>'
    And the notification should itemize interest charges '<interest_charges>'
    And the notification should display only last 4 digits '<last_4_digits>'
    And the notification should use formal and appropriate legal language
    And the notification should state a clear deadline for response '<response_deadline>'
    And the notification should outline consequences of continued non-payment
    And the notification should provide contact information for resolution
    And the collection notification should be logged with stage 'COLLECTION_NOTICE'

    Examples:
      | account_id | last_4_digits | days_delinquent | total_overdue | late_fees | interest_charges | reminder_dates | overdue_dates | response_deadline |
      | ACC-016    | 4444          | 60              | 1350.00       | 50.00     | 100.00           | 2024-01-10     | 2024-01-20    | 2024-03-30        |
      | ACC-017    | 5555          | 75              | 3200.75       | 100.00    | 250.75           | 2024-01-05     | 2024-01-15    | 2024-04-01        |
      | ACC-018    | 6666          | 90              | 875.50        | 35.00     | 90.50            | 2024-01-12     | 2024-01-22    | 2024-04-05        |
      | ACC-019    | 7777          | 65              | 5500.00       | 150.00    | 450.00           | 2024-01-08     | 2024-01-18    | 2024-03-28        |

  @functional @payment-plan @positive
  Scenario Outline: Generate and send payment plan proposal for overdue account
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the account has an overdue balance of '<overdue_balance>'
    And the cardholder has indicated inability to pay full balance
    And the account qualifies for payment plan with eligibility status '<eligibility_status>'
    And the payment plan duration is '<plan_duration>' months
    And the reduced interest rate is '<reduced_rate>' percent
    When a payment plan proposal is generated
    Then the proposal should include a structured repayment schedule
    And the proposal should specify '<plan_duration>' monthly installments
    And the proposal should calculate monthly payment amount based on '<overdue_balance>' and '<plan_duration>'
    And the proposal should state the reduced interest rate '<reduced_rate>'%
    And the proposal should clearly outline any fee reductions
    And the proposal should display only last 4 digits '<last_4_digits>'
    And the proposal should specify total amount to be repaid
    And the proposal should include clear terms and conditions
    And the proposal should provide instructions for accepting the plan
    And the proposal should include acceptance deadline '<acceptance_deadline>'
    And the proposal should be delivered to the cardholder
    And the proposal generation should be logged with status 'PLAN_OFFERED'

    Examples:
      | account_id | last_4_digits | overdue_balance | eligibility_status | plan_duration | reduced_rate | acceptance_deadline |
      | ACC-020    | 8888          | 1200.00         | ELIGIBLE           | 6             | 5.0          | 2024-03-15          |
      | ACC-021    | 9999          | 3500.00         | ELIGIBLE           | 12            | 3.5          | 2024-03-20          |
      | ACC-022    | 0000          | 800.00          | ELIGIBLE           | 4             | 6.0          | 2024-03-10          |
      | ACC-023    | 1212          | 5000.00         | ELIGIBLE           | 18            | 4.0          | 2024-03-25          |

  @functional @payment-plan @negative
  Scenario Outline: Reject payment plan for ineligible account
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the account has an overdue balance of '<overdue_balance>'
    And the account eligibility status is '<eligibility_status>'
    And the ineligibility reason is '<ineligibility_reason>'
    When a payment plan proposal generation is attempted
    Then the payment plan should be rejected
    And the rejection reason should be '<ineligibility_reason>'
    And a notification should be sent explaining ineligibility
    And alternative options should be provided if available
    And the rejection should be logged with reason '<ineligibility_reason>'

    Examples:
      | account_id | last_4_digits | overdue_balance | eligibility_status | ineligibility_reason                    |
      | ACC-024    | 3434          | 15000.00        | INELIGIBLE         | Balance exceeds maximum plan threshold  |
      | ACC-025    | 5656          | 500.00          | INELIGIBLE         | Previous payment plan defaulted         |
      | ACC-026    | 7878          | 2500.00         | INELIGIBLE         | Account flagged for fraud investigation |
      | ACC-027    | 9090          | 1000.00         | INELIGIBLE         | Minimum balance not met                 |

  @functional @collection-agency @positive
  Scenario Outline: Escalate severely delinquent account to collection agency
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the account has been delinquent for '<days_delinquent>' days
    And the total outstanding amount is '<outstanding_amount>'
    And multiple previous notifications were sent without response on dates '<notification_dates>'
    And the account meets criteria for collection agency referral
    And the collection agency name is '<agency_name>'
    When the collection agency referral process is triggered
    Then the account should be prepared for transfer to collection agency
    And the account data package should include account ID '<account_id>'
    And the account data package should include only last 4 digits '<last_4_digits>'
    And the account data package should include outstanding amount '<outstanding_amount>'
    And the account data package should include delinquency history
    And the account data package should NOT include full credit card number
    And the data should be transmitted securely to '<agency_name>'
    And a notification should be sent to cardholder about agency involvement
    And the notification should include collection agency name '<agency_name>'
    And the notification should include collection agency contact information
    And the escalation should be logged with stage 'COLLECTION_AGENCY'
    And the account status should be updated to 'REFERRED_TO_AGENCY'

    Examples:
      | account_id | last_4_digits | days_delinquent | outstanding_amount | notification_dates                    | agency_name           |
      | ACC-028    | 1313          | 95              | 2500.00            | 2024-01-10,2024-01-25,2024-02-10      | Premier Collections   |
      | ACC-029    | 2424          | 105             | 4750.50            | 2024-01-05,2024-01-20,2024-02-05      | National Recovery Inc |
      | ACC-030    | 3535          | 120             | 1875.75            | 2024-01-08,2024-01-23,2024-02-08      | Elite Credit Services |
      | ACC-031    | 4646          | 100             | 6200.00            | 2024-01-12,2024-01-27,2024-02-12      | Apex Collections LLC  |

  @functional @collection-agency @security
  Scenario: Verify full credit card number is never transmitted to collection agency
    Given a severely delinquent account with account ID 'ACC-SECURITY-001'
    And the credit card has full number '4532-1234-5678-9012'
    And the credit card has last 4 digits '9012'
    And the account is being prepared for collection agency referral
    When the account data package is generated for transmission
    And the data package is reviewed for security compliance
    Then the data package should contain last 4 digits '9012'
    And the data package should NOT contain full number '4532-1234-5678-9012'
    And the data package should NOT contain any variation of the full number
    And security scan should confirm no plain text card number exposure
    And the transmission should be encrypted with TLS 1.2 or higher
    And the data transfer should be logged with security audit trail

  @functional @legal-action @positive
  Scenario Outline: Initiate legal action for extreme default cases
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the account has been in extreme default for '<days_default>' days
    And the total debt amount is '<total_debt>'
    And all previous collection efforts have been documented as failed
    And the legal department has approved the case on '<approval_date>'
    And the account meets legal action criteria for reason '<legal_reason>'
    When the legal action initiation process is triggered
    Then legal documentation should be generated successfully
    And the documentation should include account ID '<account_id>'
    And the documentation should display only last 4 digits '<last_4_digits>'
    And the documentation should NOT display full credit card number in plain text
    And the documentation should include complete account history
    And the documentation should include total amount owed '<total_debt>'
    And the documentation should include all collection attempt records
    And the legal action should be logged in the system with timestamp
    And the legal action details should include case reference number
    And a formal legal notice should be sent to the cardholder
    And the account status should be updated to 'LEGAL_ACTION_INITIATED'

    Examples:
      | account_id | last_4_digits | days_default | total_debt | approval_date | legal_reason                        |
      | ACC-032    | 5757          | 125          | 7500.00    | 2024-03-01    | Failure to respond to all notices   |
      | ACC-033    | 6868          | 140          | 12000.50   | 2024-03-05    | Refused payment plan options        |
      | ACC-034    | 7979          | 150          | 4250.75    | 2024-03-10    | Unreachable after multiple attempts |
      | ACC-035    | 8080          | 135          | 9800.00    | 2024-03-08    | Disputed charges without resolution |

  @functional @security @critical
  Scenario Outline: Verify full credit card number is never displayed across all collection lifecycle stages
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has full number '<full_card_number>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the account is at collection lifecycle stage '<lifecycle_stage>'
    When a notification is generated for stage '<lifecycle_stage>'
    And the notification content is reviewed for security compliance
    Then the notification should display only last 4 digits '<last_4_digits>'
    And the notification should NOT display full card number '<full_card_number>'
    And the card number should be properly masked as '**** **** **** <last_4_digits>'
    And a security scan should confirm no plain text exposure of '<full_card_number>'
    And the notification should pass PCI DSS compliance check

    Examples:
      | account_id | full_card_number    | last_4_digits | lifecycle_stage        |
      | ACC-036    | 4532-1234-5678-9012 | 9012          | DUE_REMINDER           |
      | ACC-037    | 5412-7534-8642-1357 | 1357          | OVERDUE_ALERT          |
      | ACC-038    | 3782-8224-6310-2468 | 2468          | COLLECTION_NOTICE      |
      | ACC-039    | 6011-1111-2222-3333 | 3333          | PAYMENT_PLAN_OFFER     |
      | ACC-040    | 5105-1051-0510-5100 | 5100          | COLLECTION_AGENCY      |
      | ACC-041    | 4111-1111-1111-1111 | 1111          | LEGAL_ACTION           |

  @functional @security @database
  Scenario Outline: Verify credit card data is encrypted in database storage
    Given database access is available for security audit
    And a credit card account exists with account ID '<account_id>'
    And the credit card has full number '<full_card_number>'
    When the database record is queried for account '<account_id>'
    Then the credit card number field should be encrypted
    And the encrypted value should NOT match '<full_card_number>'
    And the encryption algorithm should be '<encryption_algorithm>' or stronger
    And decryption should require proper authorization
    And access to the encrypted data should be logged in audit trail

    Examples:
      | account_id | full_card_number    | encryption_algorithm |
      | ACC-042    | 4532-1234-5678-9012 | AES-256              |
      | ACC-043    | 5412-7534-8642-1357 | AES-256              |
      | ACC-044    | 3782-8224-6310-2468 | AES-256              |

  @functional @workflow @positive
  Scenario: Complete collection lifecycle progression through all stages
    Given a new credit card account with account ID 'ACC-LIFECYCLE-001'
    And the credit card has last 4 digits '5555'
    And the payment due date is set to '2024-02-15'
    And the current system date is '2024-02-10'
    When the system date advances to '2024-02-10'
    Then a due reminder notification should be sent
    And the notification should display last 4 digits '5555'
    And the account stage should be 'DUE_REMINDER_SENT'
    When the system date advances to '2024-02-16' and no payment is made
    Then an overdue alert should be triggered
    And the account stage should be 'OVERDUE_ALERT_SENT'
    When the system date advances to '2024-04-16' (60 days overdue) and no payment is made
    Then a formal collection notification should be sent
    And the account stage should be 'COLLECTION_NOTICE_SENT'
    When the system date advances to '2024-05-16' (90 days overdue) and no response is received
    Then a payment plan proposal should be generated
    And the account stage should be 'PAYMENT_PLAN_OFFERED'
    When the system date advances to '2024-05-31' and no response is received
    Then the account should be referred to collection agency
    And the account stage should be 'REFERRED_TO_AGENCY'
    When the system date advances to '2024-06-30' (135 days overdue) and collection fails
    Then legal action should be initiated
    And the account stage should be 'LEGAL_ACTION_INITIATED'
    And all stage transitions should be logged with timestamps
    And all notifications should display only last 4 digits '5555'

  @functional @workflow @payment-made
  Scenario Outline: Handle payment made during collection lifecycle
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the account is at collection stage '<current_stage>'
    And the outstanding balance is '<outstanding_balance>'
    And future notifications are scheduled for dates '<scheduled_dates>'
    When a payment of '<payment_amount>' is processed on '<payment_date>'
    And the payment type is '<payment_type>'
    Then the collection activities should be '<collection_action>'
    And all future scheduled notifications should be '<notification_action>'
    And a payment confirmation should be sent to the cardholder
    And the confirmation should display only last 4 digits '<last_4_digits>'
    And the account status should be updated to '<new_status>'
    And the remaining balance should be '<remaining_balance>'
    And the payment should be logged with amount '<payment_amount>' and date '<payment_date>'

    Examples:
      | account_id | last_4_digits | current_stage      | outstanding_balance | payment_amount | payment_type | payment_date | scheduled_dates | collection_action | notification_action | new_status       | remaining_balance |
      | ACC-045    | 1010          | OVERDUE_ALERT_SENT | 1000.00             | 1000.00        | FULL         | 2024-03-15   | 2024-03-20      | STOPPED           | CANCELLED           | PAID_IN_FULL     | 0.00              |
      | ACC-046    | 2020          | COLLECTION_NOTICE  | 2500.00             | 1000.00        | PARTIAL      | 2024-03-15   | 2024-03-25      | PAUSED            | MODIFIED            | PARTIAL_PAYMENT  | 1500.00           |
      | ACC-047    | 3030          | REFERRED_TO_AGENCY | 5000.00             | 5000.00        | FULL         | 2024-03-15   | 2024-03-30      | STOPPED           | CANCELLED           | PAID_IN_FULL     | 0.00              |
      | ACC-048    | 4040          | PAYMENT_PLAN       | 3000.00             | 500.00         | INSTALLMENT  | 2024-03-15   | 2024-04-15      | CONTINUED         | ADJUSTED            | ON_PAYMENT_PLAN  | 2500.00           |

  @functional @multi-channel @positive
  Scenario Outline: Deliver notifications through multiple communication channels
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the cardholder has email '<email>' configured
    And the cardholder has phone '<phone>' configured
    And the cardholder has mailing address '<mailing_address>' configured
    And app notifications are '<app_status>'
    And multi-channel notification preference is enabled
    And the notification type is '<notification_type>'
    When the '<notification_type>' notification is triggered
    Then an email notification should be sent to '<email>' if email is valid
    And an SMS notification should be sent to '<phone>' if phone is valid
    And an app push notification should be sent if '<app_status>' is 'ENABLED'
    And a postal mail should be generated if '<notification_type>' requires formal delivery
    And all channels should display only last 4 digits '<last_4_digits>'
    And each channel delivery should be logged separately with timestamps
    And the content should be formatted appropriately for each channel

    Examples:
      | account_id | last_4_digits | email                  | phone          | mailing_address           | app_status | notification_type  |
      | ACC-049    | 5050          | user1@email.com        | +1-555-1001    | 123 Main St, City, 12345  | ENABLED    | OVERDUE_ALERT      |
      | ACC-050    | 6060          | user2@email.com        | +1-555-1002    | 456 Oak Ave, Town, 67890  | DISABLED   | COLLECTION_NOTICE  |
      | ACC-051    | 7070          | user3@email.com        | +1-555-1003    | 789 Elm Dr, Village, 11111| ENABLED    | PAYMENT_PLAN_OFFER |
      | ACC-052    | 8080          | user4@email.com        | +1-555-1004    | 321 Pine Rd, County, 22222| ENABLED    | LEGAL_ACTION       |

  @functional @edge-case @negative
  Scenario Outline: Handle invalid or missing contact information
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the cardholder email is '<email_status>'
    And the cardholder phone is '<phone_status>'
    And a collection notification needs to be sent
    When the notification delivery is attempted
    Then the email delivery should '<email_result>'
    And the SMS delivery should '<sms_result>'
    And the failed delivery should be logged with reason '<failure_reason>'
    And the system should attempt '<retry_count>' retries for failed channels
    And an alert should be raised for contact information update
    And alternative delivery methods should be attempted if available

    Examples:
      | account_id | last_4_digits | email_status | phone_status | email_result | sms_result | failure_reason              | retry_count |
      | ACC-053    | 9090          | INVALID      | VALID        | FAIL         | SUCCESS    | Invalid email address       | 3           |
      | ACC-054    | 0101          | VALID        | INVALID      | SUCCESS      | FAIL       | Invalid phone number        | 3           |
      | ACC-055    | 1212          | MISSING      | MISSING      | FAIL         | FAIL       | No contact information      | 0           |
      | ACC-056    | 2323          | BOUNCED      | DISCONNECTED | FAIL         | FAIL       | Email bounced, phone disconnected | 3     |

  @functional @audit @positive
  Scenario Outline: Log all collection lifecycle activities in audit trail
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    And the collection activity type is '<activity_type>'
    And the activity is performed by user '<user_id>'
    And the activity timestamp is '<activity_timestamp>'
    When the collection activity '<activity_type>' is executed
    Then the activity should be logged in the audit trail
    And the audit log should include account ID '<account_id>'
    And the audit log should include only last 4 digits '<last_4_digits>'
    And the audit log should include activity type '<activity_type>'
    And the audit log should include user ID '<user_id>'
    And the audit log should include timestamp '<activity_timestamp>'
    And the audit log should include activity status '<activity_status>'
    And the audit log should be immutable and tamper-proof
    And the audit log should NOT contain full credit card number

    Examples:
      | account_id | last_4_digits | activity_type            | user_id    | activity_timestamp      | activity_status |
      | ACC-057    | 3434          | DUE_REMINDER_SENT        | SYSTEM     | 2024-03-15T10:30:00Z    | SUCCESS         |
      | ACC-058    | 4545          | OVERDUE_ALERT_SENT       | SYSTEM     | 2024-03-20T14:15:00Z    | SUCCESS         |
      | ACC-059    | 5656          | COLLECTION_NOTICE_SENT   | ADMIN-001  | 2024-03-25T09:45:00Z    | SUCCESS         |
      | ACC-060    | 6767          | PAYMENT_PLAN_GENERATED   | AGENT-123  | 2024-03-30T11:20:00Z    | SUCCESS         |
      | ACC-061    | 7878          | REFERRED_TO_AGENCY       | ADMIN-002  | 2024-04-05T16:00:00Z    | SUCCESS         |
      | ACC-062    | 8989          | LEGAL_ACTION_INITIATED   | LEGAL-001  | 2024-04-10T13:30:00Z    | SUCCESS         |

  # ==========================================
  # NON-FUNCTIONAL TEST SCENARIOS
  # ==========================================

  @non-functional @performance @timeliness
  Scenario Outline: Verify notification delivery within acceptable time frames
    Given '<notification_count>' cardholder accounts are reaching trigger condition simultaneously
    And the notification type is '<notification_type>'
    And performance monitoring is enabled
    And the expected SLA for '<notification_type>' is '<sla_minutes>' minutes
    When the notification trigger event occurs for all '<notification_count>' accounts
    And the system processes all notifications
    Then all '<notification_count>' notifications should be generated within '<generation_time>' minutes
    And all email notifications should be delivered within '<email_delivery_sla>' minutes
    And all SMS notifications should be delivered within '<sms_delivery_sla>' minutes
    And the system should maintain performance metrics within acceptable thresholds
    And no notifications should be missed or delayed beyond SLA '<sla_minutes>' minutes
    And CPU utilization should remain below '<max_cpu>'%
    And memory utilization should remain below '<max_memory>'%
    And the performance metrics should be logged for analysis

    Examples:
      | notification_count | notification_type | sla_minutes | generation_time | email_delivery_sla | sms_delivery_sla | max_cpu | max_memory |
      | 1000               | DUE_REMINDER      | 60          | 30              | 5                  | 2                | 80      | 75         |
      | 1500               | OVERDUE_ALERT     | 120         | 60              | 5                  | 2                | 80      | 75         |
      | 500                | COLLECTION_NOTICE | 240         | 120             | 10                 | 5                | 85      | 80         |
      | 250                | PAYMENT_PLAN      | 480         | 240             | 15                 | 5                | 75      | 70         |

  @non-functional @performance @load
  Scenario Outline: Handle increasing notification volume under load
    Given the baseline account volume is '<baseline_volume>'
    And the notification type is '<notification_type>'
    And performance monitoring tools are active
    When the account volume increases by '<increase_percentage>'%
    And all notifications are triggered simultaneously
    Then the system should process '<expected_volume>' notifications successfully
    And the average response time should be within '<response_time_threshold>' seconds
    And the notification delivery success rate should be at least '<success_rate>'%
    And no system errors should occur during processing
    And system resources should scale appropriately if auto-scaling is configured
    And performance should degrade gracefully if capacity is reached

    Examples:
      | baseline_volume | notification_type | increase_percentage | expected_volume | response_time_threshold | success_rate |
      | 1000            | DUE_REMINDER      | 50                  | 1500            | 5                       | 99           |
      | 1000            | OVERDUE_ALERT     | 100                 | 2000            | 10                      | 98           |
      | 1000            | COLLECTION_NOTICE | 200                 | 3000            | 15                      | 97           |

  @non-functional @security @encryption
  Scenario Outline: Verify credit card data encryption and PCI DSS compliance
    Given access to security testing environment
    And a credit card account with account ID '<account_id>'
    And the credit card full number is '<full_card_number>'
    And security scanning tools are configured
    When the database storage is examined for account '<account_id>'
    Then the credit card number should be encrypted at rest using '<encryption_at_rest>'
    And when API communication is examined
    Then all transmissions should use '<encryption_in_transit>' or higher
    And when user interfaces are examined
    Then only last 4 digits should be displayed
    And when attempting unauthorized access to full card number
    Then access should be denied and logged
    And when audit logs are examined
    Then full card numbers should NOT appear in plain text
    And when notification content is scanned
    Then no full card numbers should be detected
    And a PCI DSS vulnerability scan should return '<scan_result>'
    And encryption key management should follow best practices

    Examples:
      | account_id | full_card_number    | encryption_at_rest | encryption_in_transit | scan_result |
      | ACC-063    | 4532-1234-5678-9012 | AES-256            | TLS 1.2               | PASS        |
      | ACC-064    | 5412-7534-8642-1357 | AES-256            | TLS 1.3               | PASS        |
      | ACC-065    | 3782-8224-6310-2468 | AES-256            | TLS 1.2               | PASS        |

  @non-functional @security @access-control
  Scenario Outline: Verify access control and authorization for sensitive data
    Given a user with role '<user_role>' and user ID '<user_id>'
    And a credit card account with account ID '<account_id>'
    And the credit card has last 4 digits '<last_4_digits>'
    When the user attempts to access account data for '<account_id>'
    Then access should be '<access_result>'
    And if access is 'GRANTED', only last 4 digits '<last_4_digits>' should be visible
    And if access is 'DENIED', the attempt should be logged with reason '<denial_reason>'
    And all access attempts should be recorded in audit trail with timestamp

    Examples:
      | user_role           | user_id    | account_id | last_4_digits | access_result | denial_reason                |
      | COLLECTION_AGENT    | AGENT-001  | ACC-066    | 1111          | GRANTED       | N/A                          |
      | CUSTOMER_SERVICE    | CS-001     | ACC-067    | 2222          | GRANTED       | N/A                          |
      | LEGAL_TEAM          | LEGAL-001  | ACC-068    | 3333          | GRANTED       | N/A                          |
      | UNAUTHORIZED_USER   | UNKNOWN-01 | ACC-069    | 4444          | DENIED        | Insufficient permissions     |
      | GUEST               | GUEST-001  | ACC-070    | 5555          | DENIED        | Authentication required      |

  @non-functional @availability @uptime
  Scenario Outline: Verify system availability and uptime requirements
    Given the collection lifecycle system is monitored over '<monitoring_period>' days
    And uptime monitoring tools are active
    And the required uptime SLA is '<required_uptime>'%
    When the monitoring period completes
    Then the actual uptime should be at least '<required_uptime>'%
    And any downtime incidents should be logged with details
    And the total downtime should not exceed '<max_downtime_minutes>' minutes
    And if downtime occurs, failover should activate within '<failover_time>' seconds
    And no notifications should be permanently lost during downtime
    And the system should recover automatically within '<recovery_time>' minutes

    Examples:
      | monitoring_period | required_uptime | max_downtime_minutes | failover_time | recovery_time |
      | 30                | 99.9            | 43                   | 30            | 5             |
      | 7                 | 99.95           | 5                    | 20            | 3             |

  @non-functional @availability @failover
  Scenario Outline: Test failover and disaster recovery procedures
    Given the primary data center is operational
    And the disaster recovery site is configured at '<dr_location>'
    And '<pending_notifications>' notifications are pending in the queue
    And the RTO is '<rto_minutes>' minutes
    And the RPO is '<rpo_minutes>' minutes
    When a complete data center failure is simulated at '<failure_time>'
    And disaster recovery procedures are initiated
    Then the system should failover to DR site within '<rto_minutes>' minutes
    And data loss should be limited to last '<rpo_minutes>' minutes
    And all '<pending_notifications>' notifications should be preserved in the queue
    And notification processing should resume at DR site
    And all integrations should reconnect successfully
    And the failover should be completed by '<recovery_time>'
    And the event should be logged in disaster recovery audit trail

    Examples:
      | dr_location   | pending_notifications | rto_minutes | rpo_minutes | failure_time         | recovery_time        |
      | US-WEST       | 500                   | 120         | 15          | 2024-03-15T10:00:00Z | 2024-03-15T12:00:00Z |
      | EU-CENTRAL    | 1000                  | 90          | 10          | 2024-03-20T14:00:00Z | 2024-03-20T15:30:00Z |

  @non-functional @scalability @horizontal
  Scenario Outline: Test horizontal scalability under increasing load
    Given the current system capacity is '<current_capacity>' notifications per hour
    And '<current_instances>' application instances are running
    And auto-scaling is configured with threshold '<scaling_threshold>'%
    When the notification load increases to '<target_load>' notifications per hour
    And the system load exceeds '<scaling_threshold>'%
    Then auto-scaling should trigger and add '<additional_instances>' new instances
    And the total instances should reach '<total_instances>'
    And the system should handle '<target_load>' notifications per hour successfully
    And response times should remain within '<response_time>' seconds
    And no notifications should fail due to capacity constraints
    And when load decreases, instances should scale down appropriately

    Examples:
      | current_capacity | current_instances | scaling_threshold | target_load | additional_instances | total_instances | response_time |
      | 10000            | 2                 | 75                | 15000       | 1                    | 3               | 5             |
      | 10000            | 2                 | 75                | 20000       | 2                    | 4               | 7             |
      | 10000            | 2                 | 75                | 30000       | 4                    | 6               | 10            |

  @non-functional @reliability @retry
  Scenario Outline: Verify notification retry mechanism for failed deliveries
    Given a notification of type '<notification_type>' is queued for delivery
    And the delivery channel is '<delivery_channel>'
    And the initial delivery attempt fails with error '<error_type>'
    And the retry policy specifies '<max_retries>' maximum retries
    And the retry delay is '<retry_delay>' minutes between attempts
    When the initial delivery fails
    Then the system should automatically schedule retry attempt
    And the first retry should occur after '<retry_delay>' minutes
    And retries should continue up to '<max_retries>' attempts
    And if all retries fail, the notification should be marked as '<final_status>'
    And an alert should be raised for manual intervention if '<alert_required>' is 'true'
    And all retry attempts should be logged with timestamps and error details

    Examples:
      | notification_type | delivery_channel | error_type           | max_retries | retry_delay | final_status    | alert_required |
      | DUE_REMINDER      | EMAIL            | TEMPORARY_FAILURE    | 3           | 5           | RETRY_EXHAUSTED | true           |
      | OVERDUE_ALERT     | SMS              | NETWORK_ERROR        | 5           | 2           | RETRY_EXHAUSTED | true           |
      | COLLECTION_NOTICE | EMAIL            | MAILBOX_FULL         | 3           | 10          | RETRY_EXHAUSTED | true           |
      | PAYMENT_PLAN      | APP_PUSH         | DEVICE_OFFLINE       | 4           | 15          | RETRY_EXHAUSTED | false          |

  @non-functional @audit @retention
  Scenario Outline: Verify audit log retention and immutability
    Given audit logs exist for account ID '<account_id>'
    And the logs contain collection lifecycle events
    And the log creation date is '<log_creation_date>'
    And the retention policy requires '<retention_years>' years retention
    When the current date is '<current_date>'
    And the log age is calculated
    Then logs should be retained if age is less than '<retention_years>' years
    And logs should be archived if age is between '<retention_years>' and '<archive_years>' years
    And logs older than '<archive_years>' years should follow deletion policy
    And all logs should be immutable and tamper-proof
    And any attempt to modify logs should be detected and blocked
    And log integrity verification should pass

    Examples:
      | account_id | log_creation_date | retention_years | archive_years | current_date |
      | ACC-071    | 2020-01-01        | 7               | 10            | 2024-03-15   |
      | ACC-072    | 2018-06-15        | 7               | 10            | 2024-03-15   |
      | ACC-073    | 2015-03-20        | 7               | 10            | 2024-03-15   |

  @non-functional @accessibility @wcag
  Scenario Outline: Verify accessibility compliance for notification interfaces
    Given the notification type is '<notification_type>'
    And the delivery channel is '<delivery_channel>'
    And accessibility testing tools are configured
    When the notification interface is tested for WCAG 2.1 compliance
    Then the interface should meet WCAG 2.1 Level '<compliance_level>' standards
    And color contrast ratio should be at least '<contrast_ratio>'
    And all interactive elements should be keyboard navigable
    And screen reader compatibility should be '<screen_reader_compatible>'
    And images should have descriptive alt text
    And font sizes should be adjustable
    And the accessibility score should be at least '<min_score>'%

    Examples:
      | notification_type | delivery_channel | compliance_level | contrast_ratio | screen_reader_compatible | min_score |
      | DUE_REMINDER      | EMAIL            | AA               | 4.5:1          | true                     | 90        |
      | OVERDUE_ALERT     | WEB_PORTAL       | AA               | 4.5:1          | true                     | 90        |
      | COLLECTION_NOTICE | MOBILE_APP       | AA               | 4.5:1          | true                     | 85        |
      | PAYMENT_PLAN      | WEB_PORTAL       | AAA              | 7:1            | true                     | 95        |

  @non-functional @localization @multi-language
  Scenario Outline: Verify multi-language support for notifications
    Given a cardholder account with account ID '<account_id>'
    And the cardholder preferred language is '<preferred_language>'
    And the notification type is '<notification_type>'
    And templates exist for language '<preferred_language>'
    When the notification is generated for '<notification_type>'
    Then the notification should be in language '<preferred_language>'
    And date format should follow '<date_format>' convention
    And currency should be displayed as '<currency_format>'
    And text direction should be '<text_direction>'
    And all content should be properly translated
    And cultural conventions should be respected

    Examples:
      | account_id | preferred_language | notification_type | date_format | currency_format | text_direction |
      | ACC-074    | ENGLISH            | DUE_REMINDER      | MM/DD/YYYY  | $1,234.56       | LTR            |
      | ACC-075    | SPANISH            | OVERDUE_ALERT     | DD/MM/YYYY  | 1.234,56 €      | LTR            |
      | ACC-076    | CHINESE            | COLLECTION_NOTICE | YYYY-MM-DD  | ¥1,234.56       | LTR            |
      | ACC-077    | FRENCH             | PAYMENT_PLAN      | DD/MM/YYYY  | 1 234,56 €      | LTR            |
      | ACC-078    | ARABIC             | DUE_REMINDER      | DD/MM/YYYY  | 1,234.56 د.إ    | RTL            |

  @non-functional @delivery-rate @success-metrics
  Scenario Outline: Measure notification delivery success rates across channels
    Given '<sample_size>' notifications of type '<notification_type>' are sent
    And the delivery channel is '<delivery_channel>'
    And delivery tracking is enabled
    When all '<sample_size>' notifications are processed
    And delivery status is tracked for '<tracking_period>' hours
    Then the delivery success rate should be at least '<target_success_rate>'%
    And the actual success rate should be '<actual_success_rate>'%
    And bounce rate should be less than '<max_bounce_rate>'%
    And spam complaint rate should be less than '<max_spam_rate>'%
    And average delivery time should be less than '<max_delivery_time>' minutes
    And failed deliveries should be analyzed and categorized by failure reason

    Examples:
      | sample_size | notification_type | delivery_channel | tracking_period | target_success_rate | actual_success_rate | max_bounce_rate | max_spam_rate | max_delivery_time |
      | 1000        | DUE_REMINDER      | EMAIL            | 24              | 95                  | 96                  | 3               | 1             | 5                 |
      | 1000        | OVERDUE_ALERT     | SMS              | 2               | 98                  | 99                  | 1               | 0.5           | 2                 |
      | 500         | COLLECTION_NOTICE | EMAIL            | 24              | 95                  | 94                  | 4               | 1             | 10                |
      | 500         | PAYMENT_PLAN      | APP_PUSH         | 12              | 90                  | 92                  | 5               | 0             | 15                |

  @non-functional @data-integrity @validation
  Scenario Outline: Verify data integrity throughout collection lifecycle
    Given a cardholder account with account ID '<account_id>'
    And initial account balance is '<initial_balance>'
    And late fees of '<late_fees>' are applied
    And interest charges of '<interest_charges>' are applied
    And a payment of '<payment_amount>' is made
    When the account data is retrieved from multiple system components
    Then the database should show total owed as '<calculated_total>'
    And the notification content should match the database total
    And the collection agency data should match the database total
    And audit logs should reflect all transactions accurately
    And no data discrepancies should be found across systems
    And data checksums should validate successfully

    Examples:
      | account_id | initial_balance | late_fees | interest_charges | payment_amount | calculated_total |
      | ACC-079    | 1000.00         | 50.00     | 25.00            | 0.00           | 1075.00          |
      | ACC-080    | 2500.00         | 100.00    | 75.00            | 500.00         | 2175.00          |
      | ACC-081    | 500.00          | 25.00     | 15.00            | 540.00         | 0.00             |

  @non-functional @compliance @regulatory
  Scenario Outline: Verify regulatory compliance for collection practices
    Given the regulatory framework is '<regulatory_framework>'
    And the collection activity type is '<activity_type>'
    And compliance rules for '<regulatory_framework>' are configured
    When the collection activity '<activity_type>' is executed
    Then the activity should comply with '<regulatory_framework>' requirements
    And required disclosures should be included in communications
    And opt-out mechanisms should be provided where required
    And collection timing should respect '<time_restrictions>'
    And communication frequency should not exceed '<max_frequency>' per '<frequency_period>'
    And all compliance validations should pass
    And compliance adherence should be logged in audit trail

    Examples:
      | regulatory_framework | activity_type          | time_restrictions           | max_frequency | frequency_period |
      | FDCPA                | COLLECTION_NOTICE      | 8AM-9PM local time          | 7             | week             |
      | TCPA                 | SMS_NOTIFICATION       | No calls before 8AM/after 9PM | 3           | day              |
      | GDPR                 | DATA_SHARING_AGENCY    | Explicit consent required   | N/A           | N/A              |
      | CCPA                 | PAYMENT_PLAN_OFFER     | Right to opt-out provided   | 5             | week             |
