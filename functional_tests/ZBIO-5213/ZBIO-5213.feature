Feature: Credit Card Collection Lifecycle Notification System
As a financial institution, I want to manage the collection lifecycle with secure, compliant, and effective notifications
So that I can recover delinquent balances while protecting customer data and maintaining regulatory compliance

Background:
  Given the collection notification system is configured
  And the card number masking system is enabled
  And all communication channels are available

@positive @payment-reminders
Scenario Outline: Payment due reminders with masked card details
  Given a cardholder has an active credit card ending in "<last_four_digits>"
  And the payment due date is <days_before> days from now
  And the cardholder has "<contact_preference>" notification preference
  And the minimum payment amount is <payment_amount>
  When the automated payment reminder system triggers
  Then the cardholder should receive a notification via "<contact_preference>"
  And the notification should contain the due date
  And the notification should contain the minimum payment amount of <payment_amount>
  And the notification should display the masked card number "****<last_four_digits>"
  And the notification should include payment options
  And the full card number should never be displayed

  Examples:
    | last_four_digits | days_before | contact_preference | payment_amount |
    | 1234            | 3           | email             | 125.00         |
    | 5678            | 5           | SMS               | 75.50          |
    | 9012            | 4           | push_notification | 200.00         |
    | 3456            | 3           | email             | 50.25          |

@positive @overdue-alerts
Scenario Outline: Overdue balance alerts for missed payments
  Given a cardholder has a credit card ending in "<last_four_digits>"
  And the payment due date was <days_overdue> days ago
  And no payment was made by the due date
  And the outstanding balance is <balance_amount>
  When the overdue balance alert system triggers
  Then the cardholder should receive an overdue alert within 24 hours
  And the alert should contain the overdue amount of <balance_amount>
  And the alert should display the masked card number "****<last_four_digits>"
  And the alert should include late fee information
  And the alert should include consequences of continued non-payment
  And the alert should provide payment instructions
  And the alert should include customer service contact information

  Examples:
    | last_four_digits | days_overdue | balance_amount |
    | 1234            | 1            | 325.75         |
    | 5678            | 2            | 150.00         |
    | 9012            | 1            | 500.50         |
    | 3456            | 3            | 89.25          |

@positive @collection-notices
Scenario Outline: Formal collection notifications for significantly delinquent accounts
  Given a cardholder has a credit card ending in "<last_four_digits>"
  And the account is <days_past_due> days past due
  And multiple overdue alerts have been sent
  And the total amount owed is <total_amount>
  When the formal collection notification process triggers
  Then a formal collection notice should be generated
  And the notice should contain the total amount owed of <total_amount>
  And the notice should display the masked card number "****<last_four_digits>"
  And the notice should include breakdown of principal and fees
  And the notice should include legal consequences information
  And the notice should include dispute rights information
  And the notice should include collection agency contact information
  And the notice should include regulatory compliance statements

  Examples:
    | last_four_digits | days_past_due | total_amount |
    | 1234            | 60            | 1250.00      |
    | 5678            | 75            | 875.50       |
    | 9012            | 90            | 2100.75      |
    | 3456            | 65            | 650.25       |

@positive @multiple-cards
Scenario Outline: Multiple cards with correct card identification
  Given a cardholder has multiple credit cards
  And card ending in "<card_one>" has a current balance
  And card ending in "<card_two>" has an overdue balance of <overdue_amount>
  When the collection notification system triggers for the overdue account
  Then the notification should specify the card ending in "<card_two>"
  And the notification should display "****<card_two>" only
  And the notification should not reference card ending in "<card_one>"
  And there should be no confusion between the card accounts

  Examples:
    | card_one | card_two | overdue_amount |
    | 1234     | 5678     | 450.00         |
    | 9012     | 3456     | 275.50         |
    | 7890     | 2468     | 825.75         |
    | 1357     | 8024     | 125.25         |

@positive @progressive-workflow
Scenario Outline: Progressive collection escalation workflow
  Given a credit card account ending in "<last_four_digits>"
  And the account has a payment due date
  When <days_elapsed> days have elapsed without payment
  Then the system should send a "<notification_type>" notification
  And the notification should display "****<last_four_digits>"
  And the notification tone should be "<escalation_level>"
  And the consequences mentioned should be "<consequence_level>"

  Examples:
    | last_four_digits | days_elapsed | notification_type    | escalation_level | consequence_level |
    | 1234            | 1            | overdue_alert       | moderate         | late_fees         |
    | 1234            | 30           | escalated_alert     | firm             | credit_impact     |
    | 1234            | 60           | collection_notice   | formal           | legal_action      |
    | 5678            | 1            | overdue_alert       | moderate         | late_fees         |
    | 5678            | 30           | escalated_alert     | firm             | credit_impact     |

@positive @customer-response
Scenario Outline: Collection workflow response to customer actions
  Given a credit card account ending in "<last_four_digits>" is in collection status
  And the account balance is <initial_balance>
  When the customer "<customer_action>" with amount <action_amount>
  Then the collection workflow should "<workflow_response>"
  And future notifications should reflect the "<updated_status>"
  And the remaining balance should be <final_balance>

  Examples:
    | last_four_digits | initial_balance | customer_action    | action_amount | workflow_response | updated_status    | final_balance |
    | 1234            | 500.00          | makes_payment      | 250.00        | modify_notices    | partial_payment   | 250.00        |
    | 5678            | 300.00          | makes_full_payment | 300.00        | stop_collections  | account_current   | 0.00          |
    | 9012            | 750.00          | arranges_plan      | 150.00        | pause_collections | payment_plan      | 600.00        |
    | 3456            | 200.00          | contacts_service   | 0.00          | log_interaction   | customer_contact  | 200.00        |

@positive @cross-channel-consistency
Scenario Outline: Consistent information across communication channels
  Given a cardholder has an overdue account ending in "<last_four_digits>"
  And the overdue amount is <amount>
  And notifications are configured for multiple channels
  When collection notifications are sent via "<channel_one>" and "<channel_two>"
  Then both notifications should display "****<last_four_digits>"
  And both notifications should show the same overdue amount of <amount>
  And both notifications should have the same due dates
  And both notifications should have identical payment instructions
  And only formatting should differ between channels

  Examples:
    | last_four_digits | amount | channel_one       | channel_two   |
    | 1234            | 425.50 | email             | SMS           |
    | 5678            | 175.25 | push_notification | postal_mail   |
    | 9012            | 650.00 | email             | postal_mail   |
    | 3456            | 89.75  | SMS               | email         |

@positive @payment-plans
Scenario Outline: Payment plan proposals for customers unable to pay full balance
  Given a credit card account ending in "<last_four_digits>"
  And the account has a high overdue balance of <overdue_balance>
  And the cardholder has indicated inability to pay full balance
  And payment plan configuration is available
  When the payment plan proposal system triggers
  Then a payment plan proposal should be generated and sent to the cardholder
  And the proposal should display the masked card number "****<last_four_digits>"
  And the proposal should include a structured repayment schedule
  And the proposal should include reduced interest rates of <reduced_rate>%
  And the proposal should include clear terms and conditions
  And the proposal should include acceptance instructions
  And the proposal should include customer service contact information

  Examples:
    | last_four_digits | overdue_balance | reduced_rate |
    | 1234            | 5500.00         | 3.5          |
    | 5678            | 7250.00         | 2.9          |
    | 9012            | 6000.00         | 4.1          |
    | 3456            | 8100.00         | 2.5          |

@positive @collection-agency
Scenario Outline: Collection agency involvement for severely delinquent accounts
  Given a credit card account ending in "<last_four_digits>"
  And the account is <days_delinquent> days past due
  And all previous collection notifications have been ignored
  And the total amount owed is <total_amount>
  When the collection agency transfer process is initiated
  Then the collection agency should receive account information
  And the information should include the masked card number "****<last_four_digits>"
  And the information should include the total amount owed of <total_amount>
  And the information should include payment history
  And the information should include contact information
  And the full card number should never be transmitted to the collection agency
  And the cardholder should be notified of collection agency involvement
  And the notification should display "****<last_four_digits>"

  Examples:
    | last_four_digits | days_delinquent | total_amount |
    | 1234            | 90              | 3200.00      |
    | 5678            | 105             | 1850.75      |
    | 9012            | 95              | 4500.50      |
    | 3456            | 120             | 2750.25      |

@positive @legal-action
Scenario Outline: Legal action initiation for extreme delinquency cases
  Given a credit card account ending in "<last_four_digits>"
  And the account is <days_delinquent> days past due
  And collection efforts have failed
  And the total amount owed is <total_amount>
  When the legal action preparation process is initiated
  Then legal documentation should be generated
  And all legal documents should include the masked card number "****<last_four_digits>"
  And all legal documents should include the total amount owed of <total_amount>
  And all legal documents should include payment history
  And all legal documents should include collection efforts timeline
  And the full card number should never be included in legal documentation
  And court filings should properly identify the account using masked card number
  And the cardholder should be notified of legal action
  And the notification should display "****<last_four_digits>"

  Examples:
    | last_four_digits | days_delinquent | total_amount |
    | 1234            | 120             | 5200.00      |
    | 5678            | 135             | 3750.75      |
    | 9012            | 125             | 6800.50      |
    | 3456            | 150             | 4250.25      |

@positive @regulatory-compliance
Scenario Outline: Regulatory compliance in collection notices
  Given a collection notification is being generated
  And the account is in "<delinquency_stage>" status
  And the jurisdiction is "<region>"
  When the notification is created for card ending in "<last_four_digits>"
  Then the notification should include required legal disclosures for "<region>"
  And the notification should include dispute rights information
  And the notification should include opt-out instructions
  And the notification should display "****<last_four_digits>"
  And the notification should use compliant language for "<delinquency_stage>"
  And timing restrictions should be observed

  Examples:
    | last_four_digits | delinquency_stage | region |
    | 1234            | early_delinquent  | US     |
    | 5678            | late_delinquent   | US     |
    | 9012            | collection_ready  | US     |
    | 3456            | early_delinquent  | CA     |

@negative @system-failures
Scenario Outline: System failure during critical collection periods
  Given credit card accounts approaching "<milestone>" notifications
  And the "<primary_channel>" service fails
  When the notification system attempts to send communications
  Then the system should activate "<backup_channel>" notifications
  And no notifications should be lost
  And card numbers should remain masked as "****XXXX" in backup channels
  And failed attempts should be logged
  And notifications should be queued for retry when "<primary_channel>" recovers

  Examples:
    | milestone        | primary_channel | backup_channel |
    | due_date_reminder| email          | SMS            |
    | overdue_alert    | SMS            | postal_mail    |
    | collection_notice| email          | postal_mail    |
    | escalated_notice | push_notification| email       |

@negative @invalid-data
Scenario Outline: Invalid card data in collection system
  Given a credit card account with "<data_condition>" card data
  When the collection notification system attempts to process the account
  Then the system should handle the invalid data gracefully
  And error alerts should be sent to the operations team
  And the notification should use "<fallback_identifier>" for account identification
  And corrupted card data should never be displayed to customers
  And customer service should be notified of data issues

  Examples:
    | data_condition     | fallback_identifier    |
    | corrupted_number   | account_id            |
    | missing_last_four  | customer_name         |
    | invalid_format     | account_reference     |
    | completely_missing | phone_last_four       |

@negative @duplicate-prevention
Scenario Outline: Prevention of duplicate collection notifications
  Given an overdue account ending in "<last_four_digits>"
  And a "<notification_type>" was sent <hours_ago> hours ago
  When the collection system triggers the same "<notification_type>" again
  Then the duplicate notification should be blocked
  And only one notification per type should be sent within <time_window> hours
  And the deduplication should be logged
  And the customer should not receive harassment-level communications

  Examples:
    | last_four_digits | notification_type | hours_ago | time_window |
    | 1234            | overdue_alert     | 2         | 24          |
    | 5678            | collection_notice | 6         | 72          |
    | 9012            | payment_reminder  | 1         | 12          |
    | 3456            | escalated_alert   | 12        | 48          |

@negative @zero-balance-prevention
Scenario Outline: Prevention of collection notices for zero balance accounts
  Given a credit card account ending in "<last_four_digits>"
  And the account initially had an overdue balance of <initial_balance>
  And a collection notification was scheduled
  When a payment of <payment_amount> brings the balance to <final_balance>
  Then collection notifications should be "<action_taken>"
  And the account status should be updated to "<new_status>"
  And no inappropriate collection communications should be sent

  Examples:
    | last_four_digits | initial_balance | payment_amount | final_balance | action_taken | new_status      |
    | 1234            | 300.00          | 300.00         | 0.00          | cancelled    | current         |
    | 5678            | 150.00          | 200.00         | -50.00        | cancelled    | credit_balance  |
    | 9012            | 500.00          | 250.00         | 250.00        | modified     | partial_payment |
    | 3456            | 75.00           | 75.00          | 0.00          | cancelled    | current         |

@negative @malformed-contact-data
Scenario Outline: Handling of malformed contact information
  Given an overdue account ending in "<last_four_digits>"
  And the contact information is "<contact_data>" with format "<contact_type>"
  When the collection notification system attempts to send communications
  Then the system should validate the contact information
  And invalid "<contact_type>" should trigger "<backup_method>" communication
  And error logs should capture the validation failure
  And customer service should be alerted for contact data correction

  Examples:
    | last_four_digits | contact_data          | contact_type | backup_method |
    | 1234            | invalid-email-format  | email        | SMS           |
    | 5678            | 555-INVALID           | phone        | email         |
    | 9012            | missing@              | email        | postal_mail   |
    | 3456            | 123                   | phone        | postal_mail   |

@performance @high-load
Scenario: Collection notification performance under high load
  Given 10000 overdue credit card accounts are eligible for collection notifications
  And each account has properly masked card numbers
  When the batch collection notification processing is triggered
  Then the system should process minimum 100 notifications per minute
  And database response times should remain under 2 seconds
  And notification delivery should complete within 4 hours
  And system resource utilization should stay below 80%
  And no notification failures should occur due to load
  And card number masking should be maintained at scale

@security @data-protection
Scenario Outline: Security measures and data protection validation
  Given the collection notification system is processing communications
  When security validation is performed for "<security_aspect>"
  Then "<security_requirement>" should be verified as compliant
  And all card data should be encrypted with AES-256
  And full card numbers should never appear in plain text
  And audit logging should track all card data access
  And PCI DSS compliance should be maintained

  Examples:
    | security_aspect        | security_requirement           |
    | data_at_rest          | AES-256_encryption             |
    | data_in_transit       | TLS_1.3_encryption             |
    | access_controls       | role_based_access              |
    | audit_logging         | comprehensive_card_data_access |
    | card_masking          | no_full_numbers_displayed      |

@reliability @system-uptime
Scenario Outline: System reliability and failover capabilities
  Given the collection notification system is processing "<notification_batch_size>" notifications
  When a "<failure_type>" occurs during processing
  Then automatic failover should complete within 30 seconds
  And no data should be lost during the failover event
  And notification queues should be preserved
  And system recovery should not cause duplicate notifications
  And card number masking should be consistent through failure scenarios

  Examples:
    | notification_batch_size | failure_type      |
    | 1000                   | primary_server    |
    | 5000                   | network_failure   |
    | 500                    | database_outage   |
    | 2000                   | service_restart   |

@accessibility @wcag-compliance
Scenario: Collection notification accessibility compliance
  Given collection notifications are being generated for various channels
  When accessibility compliance testing is performed
  Then email notifications should be compatible with screen readers
  And proper heading hierarchy should be used in HTML emails
  And color contrast ratios should meet 4.5:1 minimum standard
  And keyboard navigation should be fully functional for web notices
  And card masking "****1234" should be properly announced by screen readers
  And font sizes should meet 14pt minimum requirement
  And WCAG 2.1 AA compliance should be achieved

@internationalization @multi-language
Scenario Outline: Multi-language collection notification support
  Given a cardholder has language preference set to "<language>"
  And the cardholder has an overdue account ending in "<last_four_digits>"
  When a collection notification is generated
  Then the notification should be delivered in "<language>"
  And card masking format "****<last_four_digits>" should be consistent
  And regulatory disclosures should be properly translated for "<region>"
  And currency formatting should be localized for "<region>"
  And date formatting should follow "<region>" conventions
  And legal compliance should be maintained for "<region>" jurisdiction

  Examples:
    | language | last_four_digits | region |
    | English  | 1234            | US     |
    | Spanish  | 5678            | US     |
    | French   | 9012            | CA     |
    | English  | 3456            | CA     |
