Feature: Credit Card Collection Lifecycle Notification System
  As a credit card issuer
  I want to automate collection lifecycle notifications to cardholders
  So that payment reminders and collection actions are timely, secure, and compliant

  Background:
    Given the notification service is enabled and operational
    And the system is configured to mask credit card numbers showing only last 4 digits
    And audit logging is enabled for all collection activities

  # Functional Test Scenarios - Collection Lifecycle Notifications

  @functional @reminder @positive
  Scenario Outline: Send due reminder notification before payment due date
    Given a cardholder account exists with account ID '<account_id>'
    And the credit card ending in '<last_4_digits>' is active and in good standing
    And the payment due date is set to '<due_date>'
    And the system is configured to send reminders <reminder_days> days before due date
    And the cardholder has valid contact information '<contact_channel>' as '<contact_info>'
    When the reminder trigger date occurs
    Then a due reminder notification should be generated automatically
    And the notification should contain the payment due date '<due_date>'
    And the notification should display only the last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And the full credit card number should NOT be visible anywhere in the notification
    And the notification should be delivered via '<contact_channel>' to '<contact_info>'
    And the notification should include the payment amount due '<amount_due>'
    And the notification delivery should be logged with status 'SUCCESS'

    Examples:
      | account_id | last_4_digits | due_date   | reminder_days | contact_channel | contact_info              | amount_due |
      | ACC-001    | 1234          | 2024-02-15 | 5             | email           | cardholder1@example.com   | $500.00    |
      | ACC-002    | 5678          | 2024-02-20 | 7             | sms             | +1-555-0102               | $1200.50   |
      | ACC-003    | 9012          | 2024-02-28 | 3             | email           | cardholder3@example.com   | $750.25    |
      | ACC-004    | 3456          | 2024-03-01 | 5             | sms             | +1-555-0104               | $2000.00   |

  @functional @overdue @positive
  Scenario Outline: Send overdue balance alert after missed payment due date
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And the payment due date '<due_date>' has passed without payment
    And the account status is marked as overdue
    And the overdue balance is '<overdue_amount>'
    When the system detects the missed payment on '<detection_date>'
    Then an overdue balance alert should be generated automatically
    And the alert should clearly state the overdue balance amount '<overdue_amount>'
    And the alert should display only last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And the full credit card number should NOT be visible
    And the alert should include late fee information '<late_fee>'
    And the alert should mention potential consequences '<consequences>'
    And the alert should be delivered to the cardholder via '<contact_channel>'
    And the alert timestamp should indicate it was sent after '<due_date>'

    Examples:
      | account_id | last_4_digits | due_date   | detection_date | overdue_amount | late_fee | consequences                        | contact_channel |
      | ACC-005    | 7890          | 2024-01-15 | 2024-01-16     | $500.00        | $35.00   | late fees and interest charges      | email           |
      | ACC-006    | 2468          | 2024-01-20 | 2024-01-21     | $1200.50       | $39.00   | credit score impact                 | sms             |
      | ACC-007    | 1357          | 2024-01-25 | 2024-01-26     | $750.25        | $35.00   | additional interest and late fees   | email           |
      | ACC-008    | 8642          | 2024-02-01 | 2024-02-02     | $2500.00       | $45.00   | account suspension                  | sms             |

  @functional @collection @positive
  Scenario Outline: Send formal collection notification for significantly delinquent accounts
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And the account has been overdue for <days_overdue> days
    And the delinquency threshold for collection is <threshold_days> days
    And the total amount owed is '<total_owed>'
    And additional charges have accumulated: '<additional_charges>'
    And previous reminder and overdue alerts have been sent
    When the delinquency threshold is reached on '<escalation_date>'
    Then a formal collection notification should be generated
    And the notification tone should be formal and appropriate for collection purposes
    And the total amount owed '<total_owed>' should be clearly detailed
    And additional charges should be itemized: '<additional_charges>'
    And only last 4 digits '<last_4_digits>' should be displayed in format '**** <last_4_digits>'
    And the full credit card number should NOT be visible
    And the notification should include payment deadline '<payment_deadline>'
    And the notification should state consequences of continued non-payment
    And the notification should be delivered successfully

    Examples:
      | account_id | last_4_digits | days_overdue | threshold_days | total_owed | additional_charges           | escalation_date | payment_deadline |
      | ACC-009    | 9012          | 60           | 60             | $1500.00   | Late fees: $105, Interest: $75 | 2024-03-15      | 2024-03-30       |
      | ACC-010    | 5432          | 75           | 60             | $2200.00   | Late fees: $120, Interest: $110 | 2024-03-20      | 2024-04-05       |
      | ACC-011    | 6789          | 90           | 60             | $3500.00   | Late fees: $180, Interest: $200 | 2024-04-01      | 2024-04-15       |

  @functional @payment_plan @positive
  Scenario Outline: Generate and send payment plan proposal to cardholder
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And the account has significant overdue balance '<overdue_balance>'
    And the cardholder has indicated inability to pay full amount
    And the account is eligible for payment plan based on bank policies
    And payment plan terms are configured: duration '<plan_duration>' months, interest rate '<interest_rate>'%
    When the payment plan proposal is generated on '<generation_date>'
    Then the proposal should include a structured repayment schedule
    And the installment amount should be '<installment_amount>' for '<plan_duration>' months
    And the reduced interest rate '<interest_rate>'% should be clearly stated
    And the total amount to be repaid should be '<total_repayment>'
    And only last 4 digits '<last_4_digits>' should be visible in format '**** <last_4_digits>'
    And the full credit card number should NOT be displayed
    And terms and conditions should be included
    And acceptance instructions should be provided
    And the proposal should be delivered successfully via '<delivery_channel>'

    Examples:
      | account_id | last_4_digits | overdue_balance | plan_duration | interest_rate | installment_amount | total_repayment | generation_date | delivery_channel |
      | ACC-012    | 3456          | $1500.00        | 12            | 5.0           | $131.25            | $1575.00        | 2024-03-01      | email            |
      | ACC-013    | 7890          | $2200.00        | 18            | 4.5           | $128.33            | $2310.00        | 2024-03-05      | email            |
      | ACC-014    | 1122          | $3500.00        | 24            | 6.0           | $154.58            | $3710.00        | 2024-03-10      | postal_mail      |
      | ACC-015    | 4455          | $5000.00        | 36            | 3.5           | $145.83            | $5250.00        | 2024-03-12      | email            |

  @functional @collection_agency @positive
  Scenario Outline: Escalate to collection agency with secure data sharing
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And the account has significant overdue balance '<overdue_balance>'
    And <notification_count> previous notifications have been sent without response
    And the account has been overdue for <days_overdue> days
    And the threshold for collection agency referral is <referral_threshold> days
    When the collection agency referral threshold is reached on '<referral_date>'
    Then collection agency involvement should be initiated automatically
    And a data package should be prepared for the collection agency
    And the data package should include account details and overdue amount '<overdue_balance>'
    And the data package should contain only last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And the full credit card number should NOT be included in the data package
    And a notification should be sent to the cardholder about agency involvement
    And the notification should include agency name '<agency_name>' and contact info '<agency_contact>'
    And the account status should be updated to 'COLLECTION_AGENCY_INVOLVED'
    And the escalation event should be logged with timestamp

    Examples:
      | account_id | last_4_digits | overdue_balance | notification_count | days_overdue | referral_threshold | referral_date | agency_name              | agency_contact        |
      | ACC-016    | 7890          | $1500.00        | 5                  | 90           | 90                 | 2024-04-01    | Professional Collections | +1-800-555-0201       |
      | ACC-017    | 2468          | $2800.00        | 6                  | 105          | 90                 | 2024-04-10    | Rapid Recovery Services  | +1-800-555-0202       |
      | ACC-018    | 1357          | $4200.00        | 7                  | 120          | 90                 | 2024-04-15    | National Credit Bureau   | +1-800-555-0203       |

  @functional @legal_action @positive
  Scenario Outline: Initiate legal action documentation for extreme delinquency
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And the account has severe delinquency with <days_overdue> days overdue
    And all previous collection efforts have been exhausted
    And the outstanding balance is '<outstanding_balance>'
    And the account meets legal action criteria: minimum balance '<min_balance>' and minimum days '<min_days>'
    And legal department approval has been obtained
    When legal action initiation is triggered on '<initiation_date>'
    Then legal action documentation should be generated
    And all legal documents should be prepared according to templates
    And only last 4 digits '<last_4_digits>' should appear in format '**** <last_4_digits>' in all documents
    And the full credit card number should NOT be visible in any legal documentation
    And documents should include complete account history
    And documents should detail amounts owed '<outstanding_balance>' and collection attempts made
    And formal notification should be sent to cardholder about legal action
    And notification should include deadline '<legal_deadline>' for payment to avoid proceedings
    And system should maintain audit trail of legal action initiation
    And internal approvals should be documented

    Examples:
      | account_id | last_4_digits | days_overdue | outstanding_balance | min_balance | min_days | initiation_date | legal_deadline |
      | ACC-019    | 2468          | 120          | $5000.00            | $3000.00    | 120      | 2024-05-01      | 2024-05-31     |
      | ACC-020    | 9876          | 150          | $7500.00            | $3000.00    | 120      | 2024-05-10      | 2024-06-10     |
      | ACC-021    | 5544          | 180          | $10000.00           | $3000.00    | 120      | 2024-05-15      | 2024-06-15     |

  @functional @security @positive
  Scenario Outline: Validate credit card number masking across all notification types
    Given a cardholder account '<account_id>' with credit card number '<full_card_number>'
    And the last 4 digits are '<last_4_digits>'
    And the account is at collection lifecycle stage '<lifecycle_stage>'
    When a '<notification_type>' notification is generated for delivery channel '<channel>'
    Then the notification content should be retrieved
    And the notification should display credit card in masked format '**** **** **** <last_4_digits>'
    And only the last 4 digits '<last_4_digits>' should be visible
    And the full credit card number '<full_card_number>' should NOT appear in plain text
    And the notification should pass security validation
    And the masking rule should be enforced at data presentation layer
    And the notification should comply with PCI-DSS requirements

    Examples:
      | account_id | full_card_number | last_4_digits | lifecycle_stage      | notification_type      | channel      |
      | ACC-022    | 4532123456781234 | 1234          | reminder             | due_reminder           | email        |
      | ACC-023    | 5425233430109903 | 9903          | overdue              | overdue_alert          | sms          |
      | ACC-024    | 4916338506082832 | 2832          | collection           | collection_notice      | email        |
      | ACC-025    | 4532117080573700 | 3700          | payment_plan         | payment_plan_proposal  | postal_mail  |
      | ACC-026    | 5425233430109877 | 9877          | agency_involvement   | agency_notification    | email        |
      | ACC-027    | 4916338506082456 | 2456          | legal_action         | legal_notice           | postal_mail  |

  @functional @lifecycle_progression @positive
  Scenario Outline: Verify collection lifecycle progression through stages
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And the payment due date is '<due_date>'
    And lifecycle stage timelines are configured:
      | Stage              | Trigger Timing     |
      | reminder           | -5 days            |
      | overdue_alert      | +1 day             |
      | collection_notice  | +<collection_days> days |
      | agency_referral    | +<agency_days> days     |
      | legal_action       | +<legal_days> days      |
    When the due date approaches and passes without payment
    Then a reminder notification should be sent 5 days before '<due_date>'
    And the reminder should display last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And an overdue alert should be sent 1 day after '<due_date>'
    And the alert should display last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And a collection notice should be sent <collection_days> days after '<due_date>'
    And the notice should display last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And agency referral should occur <agency_days> days after '<due_date>'
    And legal action should be initiated <legal_days> days after '<due_date>'
    And each stage transition should be logged with timestamp and reason
    And no lifecycle stage should be skipped in the progression
    And the system should maintain complete audit trail

    Examples:
      | account_id | last_4_digits | due_date   | collection_days | agency_days | legal_days |
      | ACC-028    | 5678          | 2024-01-15 | 30              | 90          | 120        |
      | ACC-029    | 9012          | 2024-02-01 | 45              | 90          | 135        |
      | ACC-030    | 3456          | 2024-02-15 | 60              | 105         | 150        |

  @functional @payment_plan_execution @positive
  Scenario Outline: Execute accepted payment plan and modify lifecycle
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And an overdue balance of '<overdue_balance>' exists
    And a payment plan proposal has been sent with terms: '<plan_duration>' months at '<installment_amount>' per month
    When the cardholder accepts the payment plan on '<acceptance_date>'
    Then the system should record the payment plan acceptance
    And scheduled payments should be created for '<plan_duration>' monthly installments of '<installment_amount>'
    And the first payment should be scheduled for '<first_payment_date>'
    And collection lifecycle notifications should be paused
    And the account status should be updated to '<new_status>'
    And payment plan communications should display last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And the payment plan history should be maintained in account records

    Examples:
      | account_id | last_4_digits | overdue_balance | plan_duration | installment_amount | acceptance_date | first_payment_date | new_status           |
      | ACC-031    | 7890          | $1500.00        | 12            | $131.25            | 2024-03-15      | 2024-04-01         | PAYMENT_PLAN_ACTIVE  |
      | ACC-032    | 2468          | $2200.00        | 18            | $128.33            | 2024-03-20      | 2024-04-05         | PAYMENT_PLAN_ACTIVE  |
      | ACC-033    | 1357          | $3500.00        | 24            | $154.58            | 2024-03-25      | 2024-04-10         | PAYMENT_PLAN_ACTIVE  |

  @functional @payment_plan_execution @negative
  Scenario Outline: Reactivate collection lifecycle when payment plan defaults
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And an active payment plan with '<remaining_installments>' remaining installments
    And the account status is 'PAYMENT_PLAN_ACTIVE'
    And the next scheduled payment is '<scheduled_payment_date>' for amount '<installment_amount>'
    When the scheduled payment date passes without payment for <missed_payments> consecutive installments
    Then a payment plan default warning should be sent after the first missed payment
    And the warning should display last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And after <missed_payments> missed installments, the payment plan should be terminated
    And the full collection lifecycle should resume from stage '<resume_stage>'
    And the account status should be updated to '<updated_status>'
    And all missed installments should be added to the overdue balance

    Examples:
      | account_id | last_4_digits | remaining_installments | scheduled_payment_date | installment_amount | missed_payments | resume_stage     | updated_status  |
      | ACC-034    | 5432          | 8                      | 2024-06-01             | $131.25            | 2               | collection       | PLAN_DEFAULTED  |
      | ACC-035    | 6789          | 10                     | 2024-06-05             | $128.33            | 3               | collection       | PLAN_DEFAULTED  |
      | ACC-036    | 1122          | 15                     | 2024-06-10             | $154.58            | 2               | collection       | PLAN_DEFAULTED  |

  @functional @multi_channel @positive
  Scenario Outline: Deliver notifications across multiple communication channels
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And the cardholder has configured channel preferences: '<preferred_channels>'
    And valid contact information exists:
      | Channel      | Contact Info           |
      | email        | <email_address>        |
      | sms          | <phone_number>         |
      | postal_mail  | <mailing_address>      |
    And a '<notification_type>' notification needs to be sent
    When the notification is triggered for delivery
    Then the notification should be sent via channels '<preferred_channels>'
    And email notification should be properly formatted with all required information
    And SMS notification should be concise with essential information
    And all channels should display only last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And notification content should be consistent across all channels
    And delivery confirmation should be received and logged for each channel

    Examples:
      | account_id | last_4_digits | preferred_channels | notification_type | email_address           | phone_number   | mailing_address          |
      | ACC-037    | 6789          | email              | due_reminder      | user037@example.com     | +1-555-0137    | 123 Main St              |
      | ACC-038    | 1234          | sms                | overdue_alert     | user038@example.com     | +1-555-0138    | 456 Oak Ave              |
      | ACC-039    | 5678          | email,sms          | collection_notice | user039@example.com     | +1-555-0139    | 789 Pine Rd              |
      | ACC-040    | 9012          | email,postal_mail  | legal_notice      | user040@example.com     | +1-555-0140    | 321 Elm St               |

  @functional @multi_channel @negative
  Scenario Outline: Handle notification delivery failures with fallback mechanism
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And the primary delivery channel is '<primary_channel>'
    And the fallback delivery channel is '<fallback_channel>'
    And contact information exists: primary '<primary_contact>' and fallback '<fallback_contact>'
    And a '<notification_type>' notification needs to be sent
    When notification delivery via '<primary_channel>' fails with error '<error_reason>'
    Then the system should log the delivery failure with error '<error_reason>'
    And the fallback mechanism should automatically activate
    And the notification should be sent via fallback channel '<fallback_channel>' to '<fallback_contact>'
    And the notification should display last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And both delivery attempts should be logged with timestamps and status

    Examples:
      | account_id | last_4_digits | primary_channel | fallback_channel | notification_type | primary_contact         | fallback_contact  | error_reason         |
      | ACC-041    | 3456          | email           | sms              | due_reminder      | invalid@example.com     | +1-555-0141       | invalid_email        |
      | ACC-042    | 7890          | sms             | email            | overdue_alert     | +1-555-9999             | user042@example.com | invalid_phone       |
      | ACC-043    | 2468          | email           | postal_mail      | collection_notice | bounced@example.com     | 567 Maple Dr      | email_bounced        |

  @functional @negative
  Scenario Outline: Reject notification generation for invalid account states
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And the account status is '<account_status>'
    And a '<notification_type>' notification is requested
    When the system attempts to generate the notification
    Then the notification generation should be rejected
    And an error should be logged with reason '<rejection_reason>'
    And no notification should be sent to the cardholder
    And the account status should remain '<account_status>'

    Examples:
      | account_id | last_4_digits | account_status | notification_type      | rejection_reason                    |
      | ACC-044    | 1111          | CLOSED         | due_reminder           | account_closed                      |
      | ACC-045    | 2222          | FRAUDULENT     | overdue_alert          | account_marked_fraudulent           |
      | ACC-046    | 3333          | DECEASED       | collection_notice      | cardholder_deceased                 |
      | ACC-047    | 4444          | BANKRUPT       | payment_plan_proposal  | account_in_bankruptcy               |
      | ACC-048    | 5555          | DISPUTED       | agency_notification    | dispute_in_progress                 |

  @functional @edge_cases
  Scenario Outline: Handle edge cases in collection lifecycle
    Given a cardholder account '<account_id>' with credit card ending in '<last_4_digits>'
    And the account is in collection lifecycle stage '<current_stage>'
    And an edge case scenario occurs: '<edge_case_scenario>'
    When the system processes the edge case
    Then the system should handle it according to rule '<handling_rule>'
    And appropriate notifications should be sent if required: '<send_notification>'
    And notifications should display last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And the account status should be updated to '<new_status>'
    And the edge case handling should be logged with details

    Examples:
      | account_id | last_4_digits | current_stage    | edge_case_scenario                | handling_rule                        | send_notification | new_status           |
      | ACC-049    | 6666          | overdue          | payment_made_same_day_as_alert    | cancel_alert_send_confirmation       | yes               | CURRENT              |
      | ACC-050    | 7777          | collection       | full_payment_during_collection    | stop_collection_send_confirmation    | yes               | PAID_IN_FULL         |
      | ACC-051    | 8888          | agency_referral  | cardholder_files_bankruptcy       | recall_from_agency_update_status     | no                | BANKRUPT             |
      | ACC-052    | 9999          | payment_plan     | cardholder_pays_full_early        | close_plan_send_confirmation         | yes               | PAID_IN_FULL         |
      | ACC-053    | 1010          | legal_action     | cardholder_negotiates_settlement  | pause_legal_send_settlement_terms    | yes               | SETTLEMENT_PENDING   |

  # Non-Functional Test Scenarios - Performance, Security, and Compliance

  @non-functional @performance @load
  Scenario Outline: Process high volume of notifications under load
    Given the system is configured with production-level resources
    And a dataset of '<account_count>' test accounts requiring '<notification_type>' notifications exists
    And performance monitoring tools are active
    And each account has credit card ending in last 4 digits varying from 0000 to 9999
    When batch notification processing is triggered for all '<account_count>' accounts
    Then all notifications should be generated within '<max_generation_time>' minutes
    And all notifications should be delivered within '<max_delivery_time>' minutes
    And CPU utilization should remain below '<max_cpu_percent>'%
    And memory usage should remain stable without leaks
    And database response times should remain below '<max_db_response_ms>' milliseconds
    And notification throughput should achieve at least '<min_throughput>' notifications per minute
    And error rate should remain below '<max_error_rate>'%
    And all notifications should correctly display only last 4 digits in format '**** XXXX'
    And system should remain responsive to other operations during processing

    Examples:
      | account_count | notification_type | max_generation_time | max_delivery_time | max_cpu_percent | max_db_response_ms | min_throughput | max_error_rate |
      | 10000         | due_reminder      | 20                  | 60                | 80              | 500                | 500            | 0.1            |
      | 50000         | overdue_alert     | 90                  | 180               | 85              | 750                | 550            | 0.2            |
      | 100000        | collection_notice | 120                 | 240               | 80              | 500                | 800            | 0.1            |

  @non-functional @security @encryption
  Scenario Outline: Validate encryption of credit card data at rest and in transit
    Given the system has encryption mechanisms implemented
    And database encryption is configured with '<encryption_algorithm>'
    And TLS/SSL version '<tls_version>' is enabled for all communications
    And test account '<account_id>' exists with full credit card number '<full_card_number>'
    When database is queried directly for account '<account_id>'
    Then the credit card number should be stored in encrypted format
    And the full card number '<full_card_number>' should NOT be visible in plain text
    And network traffic should be captured during notification generation
    And all traffic should use '<tls_version>' or higher encryption
    And application logs should contain only last 4 digits '<last_4_digits>' not full number
    And decryption should require proper authentication and authorization
    And all decryption operations should be audited
    And the system should comply with PCI-DSS data protection requirements

    Examples:
      | account_id | full_card_number | last_4_digits | encryption_algorithm | tls_version |
      | ACC-054    | 4532123456781234 | 1234          | AES-256              | TLS 1.2     |
      | ACC-055    | 5425233430109903 | 9903          | AES-256              | TLS 1.3     |
      | ACC-056    | 4916338506082832 | 2832          | AES-256              | TLS 1.2     |

  @non-functional @security @audit
  Scenario Outline: Maintain comprehensive audit trails for compliance
    Given audit logging functionality is enabled
    And test account '<account_id>' with credit card ending in '<last_4_digits>' exists
    And the account is at lifecycle stage '<lifecycle_stage>'
    When the following collection activities occur:
      | Activity Type           | Details                        |
      | <activity_1>            | <activity_1_details>           |
      | <activity_2>            | <activity_2_details>           |
      | <activity_3>            | <activity_3_details>           |
    Then each activity should generate an audit log entry
    And each log entry should include timestamp, actor, action, and outcome
    And logs should contain only last 4 digits '<last_4_digits>' never full card number
    And failed notification attempts should be logged with specific error reasons
    And cardholder responses and payments should be logged with transaction details
    And logs should be retained for minimum '<retention_years>' years
    And logs should be stored in tamper-proof format with integrity verification
    And audit trail should support regulatory compliance requirements

    Examples:
      | account_id | last_4_digits | lifecycle_stage | activity_1            | activity_1_details                 | activity_2          | activity_2_details              | activity_3           | activity_3_details                | retention_years |
      | ACC-057    | 4321          | overdue         | notification_sent     | overdue_alert via email            | payment_received    | partial payment $100            | status_updated       | overdue to payment_plan_active    | 7               |
      | ACC-058    | 8765          | collection      | notification_sent     | collection_notice via sms          | notification_failed | sms delivery failed             | fallback_triggered   | resent via email                  | 7               |
      | ACC-059    | 5432          | agency_referral | agency_referral       | referred to Professional Collections | data_package_sent   | account details to agency       | cardholder_notified  | agency involvement notice sent    | 7               |

  @non-functional @reliability @fault_tolerance
  Scenario Outline: Ensure notification system fault tolerance and recovery
    Given the notification system is operational
    And test account '<account_id>' with credit card ending in '<last_4_digits>' requires '<notification_type>' notification
    And retry mechanism is configured with max '<max_retries>' attempts
    When a '<failure_type>' failure occurs during notification processing
    Then the system should handle the failure gracefully
    And the notification should be queued for retry
    And retry attempts should occur with exponential backoff
    And after service restoration, queued notifications should be delivered successfully
    And the notification should display last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And no duplicate notifications should be sent
    And deduplication logic should prevent multiple deliveries
    And operations team should receive alert if failure persists beyond '<max_retries>' attempts
    And notification state should be maintained across system restarts

    Examples:
      | account_id | last_4_digits | notification_type | failure_type           | max_retries |
      | ACC-060    | 1111          | due_reminder      | email_service_failure  | 3           |
      | ACC-061    | 2222          | overdue_alert     | database_connection_failure | 3      |
      | ACC-062    | 3333          | collection_notice | application_server_crash | 5         |
      | ACC-063    | 4444          | payment_plan_proposal | network_timeout     | 3           |

  @non-functional @compliance @regulatory
  Scenario Outline: Ensure regulatory compliance for collection communications
    Given regulatory compliance rules are documented and implemented
    And test account '<account_id>' with credit card ending in '<last_4_digits>' exists
    And the account requires '<notification_type>' notification
    And the cardholder timezone is '<cardholder_timezone>'
    And the current time in cardholder timezone is '<current_time>'
    When the system attempts to send the notification at '<current_time>'
    Then if '<current_time>' is outside allowed hours (8 AM - 9 PM), delivery should be delayed
    And the notification should include required FDCPA disclosures
    And the notification should state amount owed, creditor name, and consumer rights
    And dispute rights and validation process information should be clearly stated
    And mini-Miranda warning should be included where required
    And the notification should display last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And opt-out mechanism should be provided with clear instructions
    And all compliance requirements should be documented in audit logs

    Examples:
      | account_id | last_4_digits | notification_type | cardholder_timezone | current_time | delayed_to_time |
      | ACC-064    | 5555          | collection_notice | America/New_York    | 07:30 AM     | 08:00 AM        |
      | ACC-065    | 6666          | overdue_alert     | America/Chicago     | 09:30 PM     | 08:00 AM next day |
      | ACC-066    | 7777          | due_reminder      | America/Los_Angeles | 02:00 PM     | send_immediately |
      | ACC-067    | 8888          | agency_notification | America/Denver    | 10:00 PM     | 08:00 AM next day |

  @non-functional @compliance @accessibility
  Scenario Outline: Ensure accessibility compliance for notifications
    Given email notification templates are designed with accessibility in mind
    And test account '<account_id>' with credit card ending in '<last_4_digits>' requires email notification
    And the cardholder has accessibility preference '<accessibility_preference>'
    When the '<notification_type>' email notification is generated
    Then the email should use semantic HTML with proper heading hierarchy
    And color contrast should meet WCAG AA standards with ratio at least '<min_contrast_ratio>'
    And important information should not be conveyed by color alone
    And email content should be fully readable with images disabled
    And text should be readable at default sizes and adjustable
    And all images should have descriptive alternative text
    And the notification should display last 4 digits '<last_4_digits>' in format '**** <last_4_digits>'
    And if accessibility preference '<accessibility_preference>' is set, appropriate format should be provided
    And notification should be understandable at appropriate reading level

    Examples:
      | account_id | last_4_digits | notification_type      | accessibility_preference | min_contrast_ratio |
      | ACC-068    | 9999          | due_reminder           | screen_reader            | 4.5:1              |
      | ACC-069    | 1010          | overdue_alert          | large_print              | 7:1                |
      | ACC-070    | 2020          | collection_notice      | high_contrast            | 7:1                |
      | ACC-071    | 3030          | payment_plan_proposal  | standard                 | 4.5:1              |

  @non-functional @data_retention
  Scenario Outline: Validate data retention and archival policies
    Given the system has data retention policies configured
    And historical account '<account_id>' with credit card ending in '<last_4_digits>' exists
    And the account was closed on '<closure_date>'
    And retention period for collection records is '<retention_years>' years
    And current date is '<current_date>'
    When the data retention evaluation job runs
    Then if account age exceeds retention period, data should be archived
    And archived data should maintain only last 4 digits '<last_4_digits>' not full card number
    And full credit card data should be securely purged according to PCI-DSS requirements
    And audit logs should be retained per regulatory requirements
    And archived data should remain accessible for legal/compliance purposes
    And data purge operations should be logged and auditable

    Examples:
      | account_id | last_4_digits | closure_date | retention_years | current_date | should_archive |
      | ACC-072    | 4040          | 2016-06-30   | 7               | 2024-01-01   | yes            |
      | ACC-073    | 5050          | 2018-12-31   | 7               | 2024-01-01   | no             |
      | ACC-074    | 6060          | 2015-03-15   | 7               | 2024-01-01   | yes            |
