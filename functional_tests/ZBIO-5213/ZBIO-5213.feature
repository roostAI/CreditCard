Feature: Credit Card Debt Collection System
  As a credit card company
  I want to automate debt collection processes with proper compliance and PII protection
  So that I can efficiently manage overdue accounts while maintaining regulatory compliance

  Background:
    Given the collection system is operational
    And PII masking is configured to show only last 4 digits of card numbers
    And regulatory compliance rules are active
    And notification channels are configured

  @collection @notification @pii-masking
  Scenario Outline: Automated due reminder notifications with PII masking
    Given a credit card account with number "<card_number>" has balance due
    And the payment due date is in <days_before_due> days
    And customer notification preferences are set to "<channel>"
    When the automated due reminder job executes
    Then a due reminder notification should be generated
    And the card number should be masked as "<masked_card>"
    And the notification should contain due date, minimum payment amount, and total balance
    And the notification should be delivered via "<channel>"
    And the delivery should be logged in the audit trail

    Examples:
      | card_number      | days_before_due | channel    | masked_card        |
      | 4532123456789012 | 7              | email      | XXXX-XXXX-XXXX-9012 |
      | 5555444433332222 | 7              | SMS        | XXXX-XXXX-XXXX-2222 |
      | 4111111111111111 | 7              | mobile_app | XXXX-XXXX-XXXX-1111 |

  @collection @overdue @escalation
  Scenario Outline: Overdue balance alert escalation workflow
    Given a credit card account with balance "<balance>" is <days_overdue> days past due
    And the account current status is "<current_status>"
    When the overdue processing batch job executes
    Then the account status should be updated to "<new_status>"
    And an overdue alert should be generated with masked card number
    And a late fee of "<late_fee>" should be applied
    And escalation timer should be set for "<next_escalation>" days

    Examples:
      | balance | days_overdue | current_status | new_status        | late_fee | next_escalation |
      | 500.00  | 1           | Current        | 30-Days-Overdue  | 35.00    | 30             |
      | 1200.00 | 31          | 30-Days-Overdue| 60-Days-Overdue  | 35.00    | 30             |
      | 2500.00 | 61          | 60-Days-Overdue| 90-Days-Overdue  | 35.00    | 30             |
      | 25.00   | 1           | Current        | Current           | 0.00     | 0              |

  @collection @legal @fdcpa
  Scenario Outline: Formal collection notification generation with legal requirements
    Given an account is <days_delinquent> days delinquent with balance "<balance>"
    And the account is eligible for formal collection notice
    When the collection notification generation process executes
    Then a formal collection notice should be generated
    And the notice should include FDCPA Section 809 debt validation requirements
    And the card number should be masked in all documentation
    And the notice should be sent via "<delivery_method>"
    And a 30-day dispute period timer should be activated
    And the account status should be updated to "<new_status>"

    Examples:
      | days_delinquent | balance  | delivery_method | new_status        |
      | 60             | 1500.00  | certified_mail  | Formal Collection |
      | 75             | 3200.00  | certified_mail  | Formal Collection |
      | 90             | 5000.00  | certified_mail  | Legal Review      |

  @collection @payment-plan @hardship
  Scenario Outline: Payment plan proposal creation and approval workflow
    Given a delinquent account with balance "<balance>" requests a payment plan
    And the customer has provided hardship documentation
    And the account meets eligibility criteria
    When a payment plan proposal is generated for "<plan_duration>" months
    Then the system should calculate monthly payment of "<monthly_payment>"
    And the interest rate should be reduced to "<reduced_rate>"%
    And the plan should be routed for approval based on balance threshold
    And upon approval, a payment plan agreement should be generated
    And the account status should be updated to "Payment Plan Active"

    Examples:
      | balance  | plan_duration | monthly_payment | reduced_rate |
      | 1500.00  | 6            | 250.00         | 9.99        |
      | 3000.00  | 12           | 250.00         | 9.99        |
      | 5000.00  | 12           | 416.67         | 9.99        |

  @collection @external-agency @data-transfer
  Scenario Outline: Collection agency handoff with secure data transfer
    Given an account is <days_delinquent> days delinquent with balance "<balance>"
    And the account meets collection agency handoff criteria
    When the collection agency assignment process executes
    Then the account should be assigned to an appropriate collection agency
    And an encrypted data file should be generated with masked card information
    And the data should be transferred via secure FTP with audit logging
    And the account status should be updated to "External Collection"
    And if balance exceeds legal action threshold, legal referral should be generated

    Examples:
      | days_delinquent | balance  |
      | 90             | 1200.00  |
      | 120            | 2800.00  |
      | 150            | 5500.00  |

  @collection @multi-channel @failure-recovery
  Scenario Outline: Multi-channel notification delivery with failure recovery
    Given a customer has "<primary_channel>", "<secondary_channel>", and postal address configured
    And an overdue notification needs to be delivered
    When the notification delivery process attempts "<primary_channel>" delivery
    And the "<primary_channel>" delivery fails with reason "<failure_reason>"
    Then the system should automatically retry "<retry_count>" times
    And after max retries, should fallback to "<secondary_channel>"
    And if "<secondary_channel>" fails, should fallback to postal mail
    And all delivery attempts should be logged with timestamps

    Examples:
      | primary_channel | secondary_channel | failure_reason | retry_count |
      | email          | SMS              | bounce         | 3          |
      | SMS            | email            | carrier_error  | 2          |
      | mobile_app     | email            | device_offline | 2          |

  @collection @rehabilitation @status-recovery
  Scenario Outline: Account rehabilitation during active collection
    Given an account in "External Collection" status with overdue balance "<overdue_balance>"
    And a collection agency is assigned
    When a customer payment of "<payment_amount>" is received
    And the payment meets rehabilitation criteria of <percentage>% of overdue balance
    Then the account should be recalled from collection agency
    And the account status should be updated to "<new_status>"
    And collection fees should be reversed
    And a rehabilitation confirmation should be sent with masked card number
    And credit bureau should be updated with current payment status

    Examples:
      | overdue_balance | payment_amount | percentage | new_status |
      | 2000.00        | 1000.00       | 50        | Current    |
      | 1500.00        | 1500.00       | 100       | Current    |
      | 3000.00        | 1800.00       | 60        | Current    |

  @collection @integration @failure-recovery
  Scenario Outline: System integration failure recovery and data consistency
    Given multiple systems are integrated for collection processing
    When a "<failure_type>" occurs during "<operation>"
    And the failure happens at "<failure_point>" of the process
    Then the system should initiate "<recovery_action>"
    And data integrity should be maintained through transaction rollback
    And the process should retry with exponential backoff
    And discrepancies should be identified during reconciliation
    And error notifications should be sent to system administrators

    Examples:
      | failure_type    | operation           | failure_point | recovery_action     |
      | network_timeout | agency_data_transfer| 50%          | transaction_rollback|
      | api_unavailable | payment_processing  | validation   | retry_queue         |
      | data_corruption | status_update       | commit       | rollback_restart    |

  @collection @fdcpa @regulatory-compliance
  Scenario Outline: FDCPA compliance validation across collection communications
    Given collection communication templates are configured with FDCPA requirements
    When a "<communication_type>" is generated for account in "<collection_stage>"
    Then the communication should include all required FDCPA disclosures
    And prohibited language should be blocked from the message
    And timing restrictions should be enforced for "<contact_time>"
    And debt validation notice should be included per Section 809
    And customer rights explanation should be present
    And card number should be masked as specified

    Examples:
      | communication_type | collection_stage     | contact_time |
      | initial_notice    | 30-Days-Overdue     | business_hours|
      | validation_notice | Formal Collection    | business_hours|
      | final_notice      | Pre-Legal           | business_hours|
      | legal_notice      | Legal Action        | any_time     |

  @collection @segmentation @strategy-assignment
  Scenario Outline: Dynamic collection strategy assignment based on customer segmentation
    Given a customer with payment history score "<payment_score>" and account balance "<balance>"
    And customer tenure of "<tenure_months>" months
    And risk assessment score of "<risk_score>"
    When the account becomes "<days_overdue>" days overdue
    Then the system should assign collection strategy "<strategy>"
    And notification frequency should be set to "<frequency>"
    And escalation timing should be configured for "<escalation_days>" days
    And strategy performance should be tracked for optimization

    Examples:
      | payment_score | balance  | tenure_months | risk_score | days_overdue | strategy    | frequency | escalation_days |
      | excellent     | 5000.00  | 36           | low        | 30          | soft        | weekly    | 21             |
      | good          | 2000.00  | 24           | medium     | 30          | standard    | bi-weekly | 14             |
      | poor          | 800.00   | 6            | high       | 30          | aggressive  | daily     | 7              |

  @collection @batch-processing @payment-handling
  Scenario Outline: Batch payment processing during collection cycles
    Given accounts in collection status with various overdue amounts
    When batch payment processing executes with payment type "<payment_type>"
    And payment amount is "<payment_amount>" against overdue balance "<overdue_balance>"
    Then payment should be allocated per priority rules
    And account balance should be updated in real-time
    And account status should transition to "<new_status>"
    And appropriate notifications should be generated
    And collection agencies should be notified if applicable

    Examples:
      | payment_type | payment_amount | overdue_balance | new_status       |
      | partial      | 500.00        | 2000.00        | Partial Payment  |
      | full         | 2000.00       | 2000.00        | Current          |
      | overpayment  | 2500.00       | 2000.00        | Credit Balance   |

  @collection @communication-preferences @opt-out
  Scenario Outline: Customer communication preference management and compliance
    Given a customer has communication preferences configured
    When customer requests "<preference_change>" for "<communication_type>"
    And the request type is "<request_type>"
    Then the system should update preferences immediately
    And "<enforcement_action>" should be applied
    And legal collection communications should continue if required
    And preference changes should be synchronized across all systems

    Examples:
      | preference_change | communication_type | request_type      | enforcement_action    |
      | opt_out          | marketing         | marketing_only    | block_marketing       |
      | cease_communication| all              | complete_cease    | legal_only           |
      | email_only       | notifications     | channel_preference| update_delivery_rules |
      | attorney_represented| collections     | legal_representation| cease_direct_contact |

  @collection @fee-management @calculation-reversal
  Scenario Outline: Collection fee calculation and reversal workflow
    Given an account with terms allowing fees and current balance "<balance>"
    When account status changes to "<status>" for "<duration>" days
    Then appropriate fees should be calculated and applied
    And fee amount should be "<expected_fee>"
    And if customer disputes fee and dispute is "<dispute_result>"
    Then fee should be "<fee_action>"
    And accounting entries should be posted accordingly
    And customer should receive "<notification_type>"

    Examples:
      | balance  | status           | duration | expected_fee | dispute_result | fee_action | notification_type |
      | 1000.00  | 30-Days-Overdue  | 1       | 35.00       | valid         | maintained | fee_notice       |
      | 1500.00  | External Collection| 30     | 150.00      | invalid       | reversed   | reversal_notice  |
      | 2000.00  | Legal Action     | 60      | 300.00      | valid         | maintained | legal_fee_notice |

  @collection @legal-documentation @court-filing
  Scenario Outline: Legal documentation generation and court filing preparation
    Given an account meets legal action criteria with balance "<balance>"
    And account is <days_overdue> days overdue
    And jurisdiction is "<jurisdiction>"
    When legal documentation generation process executes
    Then complete legal case package should be created
    And documents should be formatted per "<court_requirements>"
    And PII should be masked showing only last 4 card digits
    And documents should be routed to appropriate law firm
    And legal case tracking should be initiated
    And estimated legal costs should be calculated as "<legal_costs>"

    Examples:
      | balance  | days_overdue | jurisdiction | court_requirements | legal_costs |
      | 2500.00  | 120         | California   | CA_Superior_Court  | 750.00     |
      | 5000.00  | 150         | New York     | NY_Civil_Court     | 950.00     |
      | 10000.00 | 180         | Texas        | TX_District_Court  | 1200.00    |

  @collection @international @cross-border
  Scenario Outline: Cross-border collection for international cardholders
    Given an international customer in "<country>" with overdue balance in "<original_currency>"
    And customer preferred language is "<language>"
    And local debt collection laws for "<country>" are configured
    When collection process initiates for international account
    Then overdue amount should be converted to local currency "<local_currency>"
    And collection notice should be generated in "<language>"
    And delivery should use international methods appropriate for "<country>"
    And compliance with "<country>" debt collection regulations should be enforced
    And currency conversion fees should be calculated and disclosed

    Examples:
      | country | original_currency | language | local_currency | 
      | Canada  | USD              | English  | CAD           |
      | Mexico  | USD              | Spanish  | MXN           |
      | Germany | USD              | German   | EUR           |
      | Japan   | USD              | Japanese | JPY           |
