Feature: Credit Card Collection Lifecycle Notification System
  As a credit card issuer
  I want to automate the collection lifecycle notification process
  So that cardhollers receive timely payment reminders and collection notices while maintaining security and compliance

  Background:
    Given the notification service is enabled and operational
    And the cardholder contact information is valid and up-to-date
    And credit card numbers are encrypted and masked to show only last 4 digits

  # Functional Test Scenarios - Collection Lifecycle Notifications

  @functional @payment-reminder @TC-ZBIO-5213-001
  Scenario Outline: Send automated due reminder notification before payment due date
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the payment due date is "<due_date>"
    And the reminder is configured to send <days_before> days before due date
    And the account status is "<account_status>"
    When the reminder trigger date is reached
    Then a due reminder notification should be generated automatically
    And the notification should contain the payment due date "<due_date>"
    And the notification should display only the last 4 digits "<last_4_digits>" of the credit card
    And the full credit card number should not be visible
    And the notification should be delivered via "<delivery_channel>"
    And the notification should include payment instructions
    And the outstanding balance "<balance_amount>" should be displayed

    Examples:
      | last_4_digits | due_date   | days_before | account_status | delivery_channel | balance_amount |
      | 1234          | 2024-02-15 | 5           | active         | email            | $1,250.00      |
      | 5678          | 2024-02-20 | 7           | active         | sms              | $3,450.89      |
      | 9012          | 2024-02-28 | 3           | active         | email,sms        | $575.25        |
      | 3456          | 2024-03-01 | 5           | good_standing  | email            | $2,100.50      |

  @functional @overdue-alert @TC-ZBIO-5213-002
  Scenario Outline: Send overdue balance alert when payment due date is missed
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the payment due date "<due_date>" has passed without payment
    And the account status is marked as "<account_status>"
    And the overdue balance is "<overdue_amount>"
    When the system detects the missed payment on "<detection_date>"
    Then an overdue balance alert should be generated automatically
    And the alert should clearly state the overdue balance "<overdue_amount>"
    And the alert should display only the last 4 digits "<last_4_digits>" of the credit card
    And the full credit card number should not be visible
    And the alert should mention potential consequences: "<consequences>"
    And the notification should be sent to the cardholder via "<delivery_channel>"
    And the alert timestamp should indicate it was sent after the due date

    Examples:
      | last_4_digits | due_date   | detection_date | account_status | overdue_amount | consequences                              | delivery_channel |
      | 5678          | 2024-01-15 | 2024-01-16     | overdue        | $1,250.00      | late fees, interest charges               | email            |
      | 2468          | 2024-01-20 | 2024-01-21     | overdue        | $3,450.89      | late fees, credit score impact            | sms              |
      | 7890          | 2024-01-31 | 2024-02-01     | overdue        | $575.25        | interest charges, additional penalties    | email,sms        |
      | 1357          | 2024-02-05 | 2024-02-06     | past_due       | $5,000.00      | collection actions, credit score damage   | email            |

  @functional @collection-notice @TC-ZBIO-5213-003
  Scenario Outline: Send formal collection notification for significantly delinquent account
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the account has an overdue balance of "<overdue_amount>"
    And the account is overdue for <days_overdue> days
    And the account has reached "<delinquency_status>" status
    And previous reminders and alerts have been sent
    When the delinquency threshold of <threshold_days> days is reached
    Then a formal collection notification should be generated automatically
    And the notification should have a formal collection tone
    And the total amount owed "<total_amount>" should be clearly detailed
    And additional charges should be itemized: "<additional_charges>"
    And only the last 4 digits "<last_4_digits>" should be displayed
    And the full credit card number should not be visible
    And the notification should include deadline "<payment_deadline>" for payment
    And the notification should mention consequences: "<escalation_consequences>"
    And the notification should be delivered via "<delivery_channel>"

    Examples:
      | last_4_digits | overdue_amount | days_overdue | delinquency_status        | threshold_days | total_amount | additional_charges                    | payment_deadline | escalation_consequences          | delivery_channel |
      | 9012          | $1,250.00      | 60           | significantly_delinquent  | 60             | $1,375.00    | $75 late fee, $50 interest            | 2024-03-30       | collection agency referral       | email,postal     |
      | 4321          | $3,450.89      | 75           | severely_delinquent       | 60             | $3,650.89    | $150 late fee, $50 interest           | 2024-04-15       | legal action, credit reporting   | postal           |
      | 6543          | $5,000.00      | 90           | critically_delinquent     | 60             | $5,300.00    | $200 late fee, $100 interest          | 2024-04-30       | lawsuit, asset seizure           | email,postal     |

  @functional @payment-plan @TC-ZBIO-5213-004
  Scenario Outline: Generate and send payment plan proposal for unable-to-pay cardholder
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the cardholder has an overdue balance of "<overdue_amount>"
    And the cardholder has indicated inability to pay full amount
    And the account is eligible for payment plan based on "<eligibility_criteria>"
    When a payment plan proposal is initiated with "<plan_duration>" months duration
    And the monthly installment amount is calculated as "<installment_amount>"
    And the interest rate is reduced to "<reduced_interest_rate>"
    Then the payment plan proposal should be generated successfully
    And the proposal should include a structured repayment schedule
    And the proposal should state reduced interest rate "<reduced_interest_rate>"
    And the proposal should specify total repayment amount "<total_repayment>"
    And only the last 4 digits "<last_4_digits>" should be displayed
    And the full credit card number should not be visible
    And terms and conditions should be included
    And acceptance instructions should be provided
    And the proposal should be delivered via "<delivery_channel>"

    Examples:
      | last_4_digits | overdue_amount | eligibility_criteria | plan_duration | installment_amount | reduced_interest_rate | total_repayment | delivery_channel |
      | 3456          | $3,000.00      | hardship_request     | 12            | $270.00            | 5%                    | $3,240.00       | email            |
      | 7891          | $5,000.00      | unemployment         | 18            | $305.56            | 3%                    | $5,500.00       | email,postal     |
      | 2345          | $7,500.00      | medical_emergency    | 24            | $343.75            | 0%                    | $8,250.00       | postal           |
      | 6789          | $2,000.00      | reduced_income       | 6             | $350.00            | 8%                    | $2,100.00       | email            |

  @functional @collection-agency @TC-ZBIO-5213-005
  Scenario Outline: Involve collection agency when cardholder fails to respond
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the account has significant overdue balance of "<overdue_amount>"
    And the account is overdue for <days_overdue> days
    And multiple previous notifications have been sent without response
    And the last notification was sent on "<last_notification_date>"
    When the collection agency referral threshold of <referral_threshold> days is reached
    Then collection agency involvement should be initiated automatically
    And a data package should be prepared for the collection agency
    And the data package should include only the last 4 digits "<last_4_digits>"
    And the full credit card number should not be shared
    And the data package should include account details and overdue amount
    And a notification should be sent to the cardholder about agency involvement
    And the notification should include collection agency name "<agency_name>"
    And the notification should include agency contact information "<agency_contact>"
    And the account status should be updated to "<new_status>"
    And the escalation event should be logged with timestamp

    Examples:
      | last_4_digits | overdue_amount | days_overdue | last_notification_date | referral_threshold | agency_name              | agency_contact      | new_status              |
      | 7890          | $3,500.00      | 90           | 2024-01-15             | 90                 | ABC Collections Inc      | 1-800-555-0123      | agency_referred         |
      | 1122          | $5,000.00      | 95           | 2024-01-10             | 90                 | National Recovery Corp   | 1-888-555-0456      | third_party_collection  |
      | 3344          | $8,000.00      | 105          | 2024-01-05             | 90                 | Premier Collections LLC  | 1-877-555-0789      | external_collection     |
      | 5566          | $2,500.00      | 120          | 2023-12-25             | 90                 | First Recovery Services  | 1-866-555-0321      | agency_active           |

  @functional @legal-action @TC-ZBIO-5213-006
  Scenario Outline: Initiate legal action documentation for extreme non-payment cases
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the account has severe delinquency with balance of "<delinquent_amount>"
    And the account is overdue for <days_overdue> days
    And all previous collection efforts have been exhausted
    And the account meets legal action criteria: "<legal_criteria>"
    When the legal action threshold of <legal_threshold> days is reached
    And legal department approval is obtained
    Then the legal action process should be initiated successfully
    And legal documentation should be generated from templates
    And all documents should display only last 4 digits "<last_4_digits>"
    And the full credit card number should not appear in any legal document
    And documents should include complete account history
    And documents should detail amounts owed: "<total_owed>"
    And documents should list collection attempts made: <attempt_count>
    And a formal notification should be sent to the cardholder
    And the notification should include deadline "<legal_deadline>" to avoid proceedings
    And the system should maintain audit trail of legal action initiation
    And internal approvals should be documented

    Examples:
      | last_4_digits | delinquent_amount | days_overdue | legal_criteria              | legal_threshold | total_owed | attempt_count | legal_deadline |
      | 2468          | $10,000.00        | 120          | amount_exceeds_threshold    | 120             | $10,500.00 | 8             | 2024-05-30     |
      | 1357          | $15,000.00        | 135          | no_response_to_agency       | 120             | $15,750.00 | 12            | 2024-06-15     |
      | 9753          | $25,000.00        | 150          | fraudulent_intent_suspected | 120             | $26,250.00 | 15            | 2024-06-30     |
      | 8642          | $8,500.00         | 180          | repeated_payment_defaults   | 120             | $9,000.00  | 20            | 2024-07-15     |

  @functional @security @TC-ZBIO-5213-007
  Scenario Outline: Validate credit card number security across all communications
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the account is at collection lifecycle stage "<lifecycle_stage>"
    When a "<notification_type>" notification is generated
    And the notification is prepared for delivery via "<delivery_channel>"
    Then the notification should display credit card number as "<masked_format>"
    And only the last 4 digits "<last_4_digits>" should be visible
    And the full credit card number should never appear in plain text
    And the notification content should be validated for security compliance
    And the database should store full numbers in encrypted format
    And system logs should contain only last 4 digits
    And the masking should be enforced at data presentation layer
    And access to full number should require special authorization
    And all security validations should pass

    Examples:
      | last_4_digits | lifecycle_stage          | notification_type      | delivery_channel | masked_format      |
      | 1234          | due_reminder             | payment_reminder       | email            | **** **** **** 1234 |
      | 5678          | overdue                  | overdue_alert          | sms              | ****5678           |
      | 9012          | collection               | collection_notice      | email,postal     | **** **** **** 9012 |
      | 3456          | payment_plan             | payment_plan_proposal  | email            | **** **** **** 3456 |
      | 7890          | agency_referred          | agency_notification    | postal           | **** **** **** 7890 |
      | 2468          | legal_action             | legal_notice           | email,postal     | **** **** **** 2468 |

  @functional @lifecycle-progression @TC-ZBIO-5213-008
  Scenario Outline: Validate collection lifecycle progression sequence
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the payment due date is "<due_date>"
    And the current date is "<current_date>"
    And reminder notification is configured for <reminder_days> days before due date
    And overdue alert is configured for <overdue_days> days after due date
    And collection notice is configured for <collection_days> days delinquency
    When the lifecycle progresses based on configured timelines
    Then the current lifecycle stage should be "<expected_stage>"
    And the appropriate notification "<expected_notification>" should be sent
    And the notification should include last 4 digits "<last_4_digits>"
    And the stage transition should be logged with timestamp
    And the account status should reflect "<expected_status>"

    Examples:
      | last_4_digits | due_date   | current_date | reminder_days | overdue_days | collection_days | expected_stage  | expected_notification  | expected_status      |
      | 4567          | 2024-02-15 | 2024-02-10   | 5             | 1            | 30              | reminder        | payment_reminder       | active               |
      | 8901          | 2024-02-15 | 2024-02-16   | 5             | 1            | 30              | overdue         | overdue_alert          | overdue              |
      | 2345          | 2024-01-15 | 2024-02-20   | 5             | 1            | 30              | collection      | collection_notice      | delinquent           |
      | 6789          | 2024-01-01 | 2024-04-15   | 5             | 1            | 90              | agency_referral | agency_notification    | agency_referred      |
      | 1357          | 2023-12-01 | 2024-05-01   | 5             | 1            | 120             | legal_action    | legal_notice           | legal_proceedings    |

  @functional @payment-plan-execution @TC-ZBIO-5213-009
  Scenario Outline: Execute accepted payment plan and adjust collection lifecycle
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And a payment plan proposal has been sent
    And the payment plan has "<plan_duration>" monthly installments of "<installment_amount>"
    When the cardholder accepts the payment plan on "<acceptance_date>"
    Then the system should create <plan_duration> scheduled payment entries
    And the collection lifecycle notifications should be "<lifecycle_action>"
    And the account status should be updated to "<new_status>"
    And the first scheduled payment should process on "<first_payment_date>"
    And payment confirmations should display last 4 digits "<last_4_digits>"
    And the payment plan history should be maintained in account records

    Examples:
      | last_4_digits | plan_duration | installment_amount | acceptance_date | lifecycle_action | new_status         | first_payment_date |
      | 5432          | 12            | $250.00            | 2024-02-15      | paused           | payment_plan_active | 2024-03-01        |
      | 9876          | 18            | $300.00            | 2024-02-20      | modified         | repayment_schedule  | 2024-03-05        |
      | 3210          | 24            | $350.00            | 2024-02-25      | suspended        | plan_in_progress    | 2024-03-10        |
      | 7654          | 6             | $500.00            | 2024-03-01      | paused           | payment_plan_active | 2024-03-15        |

  @functional @payment-plan-default @TC-ZBIO-5213-009
  Scenario Outline: Handle payment plan default and reactivate collection lifecycle
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the cardholder is on an active payment plan
    And the payment plan has "<remaining_installments>" remaining installments
    When the cardholder misses <missed_payments> consecutive payment(s)
    And the missed payment scenario is "<default_scenario>"
    Then a payment plan warning notification should be sent
    And the warning should display last 4 digits "<last_4_digits>"
    And if missed payments reach <threshold> the plan should be "<plan_action>"
    And the collection lifecycle should be "<lifecycle_action>"
    And the account status should change to "<new_status>"

    Examples:
      | last_4_digits | remaining_installments | missed_payments | default_scenario     | threshold | plan_action | lifecycle_action | new_status              |
      | 1111          | 10                     | 1               | single_missed        | 2         | active      | on_hold          | payment_plan_delinquent |
      | 2222          | 8                      | 2               | double_missed        | 2         | defaulted   | reactivated      | plan_defaulted          |
      | 3333          | 6                      | 3               | multiple_missed      | 2         | terminated  | full_resume      | collection_resumed      |
      | 4444          | 12                     | 1               | first_time_miss      | 3         | warning     | monitoring       | payment_plan_warning    |

  @functional @multi-channel-delivery @TC-ZBIO-5213-010
  Scenario Outline: Deliver notifications across multiple communication channels
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the cardholder has configured notification preferences: "<preferences>"
    And valid contact information exists for "<available_channels>"
    When a "<notification_type>" notification is triggered
    Then the notification should be sent via "<delivery_channels>"
    And the email notification should be properly formatted if email is used
    And the SMS notification should be concise if SMS is used
    And the postal mail should be queued if mail is used
    And all channels should display only last 4 digits "<last_4_digits>"
    And the content should be consistent across all channels
    And delivery confirmation should be received for each channel
    And all notification attempts should be logged with timestamps

    Examples:
      | last_4_digits | preferences    | available_channels | notification_type      | delivery_channels |
      | 6789          | email_only     | email,sms,postal   | payment_reminder       | email             |
      | 2468          | sms_only       | email,sms,postal   | overdue_alert          | sms               |
      | 1357          | email_and_sms  | email,sms,postal   | collection_notice      | email,sms         |
      | 9753          | all_channels   | email,sms,postal   | payment_plan_proposal  | email,sms,postal  |
      | 3698          | postal_only    | email,sms,postal   | legal_notice           | postal            |

  @functional @multi-channel-fallback @TC-ZBIO-5213-010
  Scenario Outline: Handle notification delivery failures with channel fallback
    Given a cardholder account exists with credit card ending in "<last_4_digits>"
    And the primary delivery channel is "<primary_channel>"
    And the fallback delivery channel is "<fallback_channel>"
    When a notification is sent via "<primary_channel>"
    And the delivery fails with reason "<failure_reason>"
    Then the system should attempt delivery via fallback channel "<fallback_channel>"
    And the fallback attempt should include last 4 digits "<last_4_digits>"
    And both delivery attempts should be logged
    And if fallback succeeds the notification status should be "<final_status>"

    Examples:
      | last_4_digits | primary_channel | fallback_channel | failure_reason        | final_status          |
      | 4321          | email           | sms              | invalid_email         | delivered_via_fallback |
      | 8765          | sms             | email            | phone_disconnected    | delivered_via_fallback |
      | 1593          | email           | postal           | mailbox_full          | delivered_via_fallback |
      | 7531          | sms             | postal           | sms_gateway_timeout   | delivered_via_fallback |

  # Non-Functional Test Scenarios

  @non-functional @performance @load-testing @TC-ZBIO-5213-NF-001
  Scenario Outline: Validate notification system performance under high load
    Given the notification system is configured with production-level resources
    And a dataset of <account_count> accounts is prepared
    And accounts are due for "<notification_type>" notifications
    And performance monitoring tools are active
    When batch notification processing is triggered for all accounts
    Then all <account_count> notifications should be processed within <max_processing_time> minutes
    And CPU utilization should remain below <max_cpu_percent>%
    And memory usage should remain stable
    And database response times should be less than <max_db_response_ms> ms
    And notification throughput should exceed <min_throughput> notifications per minute
    And error rate should be below <max_error_rate>%
    And all notifications should correctly display last 4 digits only
    And the system should remain responsive to other operations

    Examples:
      | account_count | notification_type   | max_processing_time | max_cpu_percent | max_db_response_ms | min_throughput | max_error_rate |
      | 10000         | payment_reminder    | 30                  | 75              | 500                | 400            | 0.1            |
      | 50000         | overdue_alert       | 120                 | 80              | 600                | 500            | 0.1            |
      | 100000        | collection_notice   | 180                 | 80              | 700                | 600            | 0.2            |
      | 250000        | mixed_notifications | 300                 | 85              | 800                | 800            | 0.3            |

  @non-functional @security @encryption @TC-ZBIO-5213-NF-002
  Scenario Outline: Validate credit card data encryption at rest and in transit
    Given the system has encryption mechanisms implemented
    And database encryption is configured with "<encryption_algorithm>"
    And TLS/SSL version "<tls_version>" is enabled for communications
    And test accounts with credit card data exist
    When credit card data is stored in the database
    Then the data should be encrypted using "<encryption_algorithm>"
    And direct database queries should show encrypted data only
    And network traffic should use "<tls_version>" or higher encryption
    And application logs should contain only last 4 digits
    And decryption should require "<auth_level>" authorization
    And encryption keys should be managed according to "<key_policy>"
    And security scans should reveal no credit card data exposure
    And the system should achieve PCI-DSS compliance level "<compliance_level>"

    Examples:
      | encryption_algorithm | tls_version | auth_level        | key_policy              | compliance_level |
      | AES-256              | TLS 1.2     | admin_only        | 90_day_rotation         | Level 1          |
      | AES-256-GCM          | TLS 1.3     | authorized_role   | quarterly_rotation      | Level 1          |
      | AES-256              | TLS 1.2     | multi_factor_auth | 180_day_rotation        | Level 2          |
      | ChaCha20-Poly1305    | TLS 1.3     | admin_only        | quarterly_rotation      | Level 1          |

  @non-functional @audit @compliance-logging @TC-ZBIO-5213-NF-003
  Scenario Outline: Validate audit trail and compliance logging for collection activities
    Given audit logging functionality is enabled
    And log storage has sufficient capacity for <retention_period> years
    And a cardholder account exists at "<lifecycle_stage>" stage
    When a "<collection_activity>" is performed
    Then an audit log entry should be created
    And the log should include timestamp, actor, action, and outcome
    And the log should contain only last 4 digits of credit card
    And the log entry should have severity level "<log_severity>"
    And logs should be retained for <retention_period> years minimum
    And logs should be stored in tamper-proof format
    And log queries should retrieve events within <query_time_seconds> seconds
    And audit trail should support "<regulatory_requirement>" compliance

    Examples:
      | lifecycle_stage | collection_activity      | log_severity | retention_period | query_time_seconds | regulatory_requirement |
      | overdue         | overdue_alert_sent       | INFO         | 7                | 5                  | FDCPA                  |
      | collection      | collection_notice_sent   | WARNING      | 7                | 5                  | CFPB                   |
      | agency_referred | agency_data_shared       | CRITICAL     | 10               | 3                  | FDCPA,TCPA             |
      | legal_action    | legal_notice_generated   | CRITICAL     | 10               | 3                  | State_Law              |
      | payment_plan    | payment_plan_accepted    | INFO         | 7                | 5                  | CFPB                   |

  @non-functional @reliability @fault-tolerance @TC-ZBIO-5213-NF-004
  Scenario Outline: Validate notification system fault tolerance and recovery
    Given the notification system has retry mechanisms configured
    And maximum retry attempts are set to <max_retries>
    And a cardholder notification is queued for delivery
    When a "<failure_type>" failure occurs during notification processing
    And the failure scenario is "<failure_scenario>"
    Then the system should handle the failure gracefully
    And the notification should be queued for retry
    And retry attempts should not exceed <max_retries>
    And upon service restoration notifications should be delivered
    And no duplicate notifications should be sent
    And deduplication logic should prevent duplicates
    And failed notification alerts should be sent to operations team
    And notification state should be maintained across failures
    And recovered notifications should display last 4 digits correctly

    Examples:
      | failure_type          | failure_scenario       | max_retries |
      | email_service_down    | temporary_outage       | 3           |
      | database_connection   | connection_timeout     | 5           |
      | sms_gateway_failure   | provider_unavailable   | 3           |
      | application_crash     | server_restart         | 5           |
      | network_failure       | connectivity_loss      | 4           |

  @non-functional @compliance @regulatory @TC-ZBIO-5213-NF-005
  Scenario Outline: Validate regulatory compliance for collection communications
    Given regulatory compliance rules are implemented
    And notification templates include required legal language
    And time-of-day restrictions are configured for "<time_zone>"
    And the current local time is "<current_time>"
    And frequency limits allow maximum <max_frequency> contacts per <frequency_period>
    When a "<notification_type>" notification is scheduled
    Then the notification should include "<required_disclosure>" disclosure
    And the notification should respect time restrictions: "<allowed_time_range>"
    And if current time is outside allowed range the notification should be "<action>"
    And frequency limits should be enforced and tracked
    And opt-out mechanisms should be available
    And ceased communication requests should be honored within <compliance_hours> hours
    And dispute rights information should be included
    And mini-Miranda warning should be present where required

    Examples:
      | notification_type  | required_disclosure | time_zone | current_time | allowed_time_range | action     | max_frequency | frequency_period | compliance_hours |
      | collection_notice  | FDCPA_notice        | EST       | 10:00        | 08:00-21:00        | send       | 3             | week             | 24               |
      | collection_notice  | FDCPA_notice        | EST       | 22:00        | 08:00-21:00        | postpone   | 3             | week             | 24               |
      | overdue_alert      | amount_owed         | PST       | 07:30        | 08:00-21:00        | postpone   | 5             | week             | 48               |
      | agency_notice      | FDCPA_validation    | CST       | 15:00        | 08:00-21:00        | send       | 2             | week             | 24               |
      | legal_notice       | legal_rights        | MST       | 20:30        | 08:00-21:00        | send       | 1             | month            | 24               |

  @non-functional @accessibility @WCAG @TC-ZBIO-5213-NF-006
  Scenario Outline: Validate accessibility of collection notifications
    Given email notification templates are designed with accessibility
    And WCAG 2.1 level "<wcag_level>" compliance is required
    And a cardholder account exists with accessibility preference "<accessibility_preference>"
    When a "<notification_type>" notification is generated
    Then the email should use semantic HTML with proper heading structure
    And screen readers should correctly interpret all content
    And color contrast should meet "<wcag_level>" standards with minimum ratio <min_contrast_ratio>
    And important information should not depend on color alone
    And email content should be readable with images disabled
    And font sizes should be adjustable without breaking layout
    And all images should have descriptive alternative text
    And keyboard navigation should work for interactive elements
    And alternative formats "<alt_format>" should be available upon request
    And content should be understandable at reading level "<reading_level>"

    Examples:
      | notification_type   | wcag_level | min_contrast_ratio | accessibility_preference | alt_format    | reading_level |
      | payment_reminder    | AA         | 4.5:1              | standard                 | none          | grade_8       |
      | overdue_alert       | AA         | 4.5:1              | screen_reader            | audio         | grade_6       |
      | collection_notice   | AAA        | 7:1                | large_print              | large_print   | grade_8       |
      | payment_plan        | AA         | 4.5:1              | high_contrast            | none          | grade_9       |
      | legal_notice        | AA         | 4.5:1              | braille                  | braille       | grade_10      |
