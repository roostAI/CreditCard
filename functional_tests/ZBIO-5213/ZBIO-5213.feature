Feature: Credit Card Collection Lifecycle Notification, Masking, and Audit Compliance

  # Background setup for UI and API scenarios
  Background:
    Given the system environment is set with notification, audit logging, and masking features enabled
    And test cardholder and operator accounts are provisioned as needed

  # UI Test Scenarios

  @ui @positive
  Scenario Outline: End-to-End Credit Card Due Reminder to Collection Notification Workflow
    Given I am logged in as a <role> in the collection admin UI
    And a cardholder account with card ending in <masked_card> and payment due on <due_date> is present
    When I navigate to the upcoming payment dashboard
    And I confirm due reminder configuration for the cardholder
    And I trigger an automated due reminder
    Then I should see a due reminder message in the outbox displaying only the last 4 digits: <masked_card>
    When the payment is not made by <due_date>
    Then an overdue alert is generated and delivered with only the last 4 digits, amount <overdue_amount>
    When I advance the workflow to formal collection stage and send collection notification (with extra charges <extra_charges>)
    Then all notifications in UI, email, SMS, and app show only <masked_card>, never the full card number
    And the workflow status in UI updates as follows: Due → Overdue → Collection
    And audit trail entries exist for each state transition and notification sent

    Examples:
      | role           | masked_card | due_date   | overdue_amount | extra_charges |
      | Bank Operator  | 1234        | 2024-07-15 | 100.00        | 15.00         |
      | Bank Operator  | 9876        | 2024-07-20 | 250.00        | 25.00         |

  @ui @negative
  Scenario Outline: PII Exposure Edge Case Validation - Notification Content Never Contains Full Card Number
    Given I am logged in as <role> and have access to notification configuration
    When I edit the <notification_type> template to include a full card number field
    And I trigger the <notification_type> notification for card ending in <card_number>
    Then the UI and outbox must not display any unmasked card number
    When I attempt a handoff to an external agency using a payload containing the full card number
    Then the system triggers an error, logs the attempt in audit trail, and compliance alerts are issued
    When I review generated legal documents and external notifications
    Then only the last 4 digits <masked_card> are present; no full card number ever exposed
    And the audit log contains entries for all exposure attempts and enforcement actions

    Examples:
      | role     | notification_type | card_number         | masked_card |
      | Admin    | Reminder         | 4111222233334444    | 4444        |
      | Agency   | Agency           | 5678567856785678    | 5678        |
      | Legal    | Legal            | 9999888877776666    | 6666        |

  @ui @boundary
  Scenario Outline: UI Boundary and State Transition - Monetary Fields and Workflow Advancement
    Given I am logged in as admin and have a cardholder with card ending <masked_card>
    And the cardholder balance is set to <balance>
    When I trigger a due reminder notification
    Then the notification logs/contents must include only the last 4 digits: <masked_card>
    When I set overdue to <overdue_trigger> and simulate missed payment
    Then overdue alert is sent or error is handled per business rule
    When I move account to collection stage (if permitted for value)
    Then audit logs, status workflow, and UI reflect the correct state and event
    When I trigger agency handoff
    Then the corresponding state and masking are validated according to outcome
    But if <balance> is negative or exceeds max, the UI and audit log display appropriate error, no notification sent

    Examples:
      | masked_card | balance    | overdue_trigger | comment                      |
      | 1255        | 0          | 0.01           | zero balance valid           |
      | 3399        | 100000     | 100000         | max balance                  |
      | 8888        | -50        | 1              | negative - error             |
      | 3000        | 1000000000 | 5000000        | boundary overflow            |
      | 5577        | 0.01       | 0.01           | minimum positive             |

  @ui @positive
  Scenario Outline: Payment Plan Proposal, Negotiation, Acceptance, and Early Reversal
    Given I am logged in as a <role> and the cardholder is in collection status for card ending <masked_card>
    When I trigger a payment plan proposal with repayment terms <terms>
    Then I review the structured repayment in UI and confirm notification (masked as <masked_card>) is sent
    When the cardholder accepts terms within the app
    Then the workflow transitions to payment plan status and confirmation notification (last 4 digits only) is sent
    When an early lump sum payment of <early_payment> is made via app
    Then the workflow reverses from payment plan to closed, closure notification is sent, and masking is maintained
    And audit trail captures all actions and reversals

    Examples:
      | role          | masked_card | terms                 | early_payment |
      | Bank Operator | 9999        | "3x monthly of 100"   | 400           |
      | Cardholder    | 8686        | "6x monthly of 50"    | 295           |

  @ui @error
  Scenario Outline: Error Handling and Audit Trail for Notification & Legal Document Integration Failures
    Given I am logged in as <role> and the cardholder account status is set to <workflow_stage>
    When I attempt to send a <notification_type> notification but simulate delivery failure on the <integration_platform>
    Then the UI displays an error alert, audit trail logs the failure, and no unmasked card number is exposed
    When I move workflow to handoff or document generation and simulate failure on <integration_platform>
    Then the UI and audit log reflect the error and allow manual recovery
    When I perform manual recovery actions
    Then audit log traces the attempt, masking, and recovery outcome

    Examples:
      | role    | workflow_stage | notification_type | integration_platform    |
      | Admin   | Overdue        | Overdue          | Notification           |
      | Operator| Collection     | Collection       | Agency API             |
      | Admin   | Legal          | Legal            | Legal Docs             |

  @ui @positive
  Scenario Outline: Role-Based Access Control and Approval Workflow for Notifications
    Given I am logged in as a <role> in the collection UI and notification workflow is enabled
    When I attempt to create or edit a <notification_type> template and trigger preview
    Then only authorized roles may proceed, unauthorized users see an access denied error
    When a supervisor role approves a template change or escalation
    Then the approval is logged in the audit trail and notifications sent are masked (last 4 digits <masked_card>)
    When I trigger overdue alert or payment plan as <role>
    Then escalation approval and access logs are enforced
    When I attempt agency handoff or legal generation as compliance officer
    Then only allowable actions are permitted and all audit/modification events are logged

    Examples:
      | role              | notification_type | masked_card | access_expected |
      | Collection Admin  | Reminder         | 2345        | allowed         |
      | Supervisor        | Overdue          | 5555        | allowed         |
      | Teller            | Payment Plan     | 6789        | denied          |
      | Compliance Officer| Agency           | 1010        | allowed         |

  @ui @positive
  Scenario Outline: Multi-Missed Payment Workflow with Late Fee, Notification, and Reversal
    Given a cardholder account with due date <due_date> and card ending <masked_card>
    When the due reminder is sent and the payment is missed
    Then an overdue alert is triggered and late fee <late_fee_amt> is applied and reflected in the notification and UI, all with mask <masked_card>
    When a second payment is also missed, escalate to collection stage and send collection notification (masked)
    When the cardholder pays full amount <full_payment_after_fees>, workflow reverses from collection to normal status
    Then closure notification (masked) is sent, and UI/audit reflect reversal

    Examples:
      | due_date   | masked_card | late_fee_amt | full_payment_after_fees |
      | 2024-07-10 | 7890        | 20.00        | 140.00                  |
      | 2024-08-01 | 4441        | 35.00        | 335.00                  |

  @ui @positive @api
  Scenario Outline: Agency Handoff - Notification and API Payload Masking Validation
    Given a cardholder is at collection stage for card ending <masked_card>
    When I initiate agency handoff workflow from the admin UI
    Then the outgoing API payload to the agency includes only the last 4 digits: <masked_card> and overdue amount <overdue_amt>
    When a manual API call containing the full card number <card_number> is attempted
    Then the system should reject the payload, log an error and regulatory compliance warning
    And audit logs must capture all handoff and API data attempts

    Examples:
      | masked_card | overdue_amt | card_number         |
      | 3444        | 500.00      | 4242424242424242    |
      | 8888        | 1200.50     | 9999888877776666    |

  # API & Integration Test Scenarios

  @api @negative
  Scenario Outline: Notification Trigger and Content Validation for Invalid Card Numbers
    Given user <role> attempts to initiate the <notification_type> workflow via <source>
    And the card number provided is <card_number>
    When the workflow is triggered
    Then the API/UI should reject the trigger and display error "Invalid card number"
    And the response should have status <status>
    And no notification is sent, no unmasked data is shown or transmitted
    And audit logs entry for masking enforcement and failed attempt exists

    Examples:
      | role    | notification_type | card_number      | status | source   |
      | Admin   | Reminder         | 123              | 400    | UI       |
      | Operator| Overdue          | ABCD5678         | 400    | UI       |
      | Admin   | Collection       | 4444333322221111 | 400    | API      |
      | Operator| Payment Plan     | 5678X            | 400    | API      |

  @ui @positive
  Scenario Outline: Legal Action Initiation - Notification, Document Masking, and Compliance Audit
    Given a cardholder is in legal escalation status with card ending <masked_card>
    When I initiate the legal action workflow from the admin UI
    Then the legal notification preview in UI only displays the last 4 digits: <masked_card>
    When I trigger legal document generation
    Then the generated document contains only masked card, not the full number
    When the document is routed for approval to <approver>
    Then approval is recorded in the audit system and legal notification sent (masked)
    When storing generated documents in the secure repository
    Then access rules and audit logs for document and PII masking are validated

    Examples:
      | masked_card | approver          |
      | 5050        | Compliance Officer|
      | 7878        | Supervisor        |

  @ui @positive
  Scenario Outline: Due Reminder Reconfiguration and Notification Retest with Date Adjustment
    Given I am logged in as Collection Admin with access to collection dashboard
    And a cardholder with card ending <masked_card> is scheduled for payment due on <orig_due_date>
    When I edit the upcoming due date to <new_due_date> and save
    Then the UI updates the schedule and allows retrigger of the due reminder
    When I retrigger the automated due reminder notification
    Then the notification outbox shows the new due date and content with only <masked_card>
    And the audit trail logs the date change, retrigger attempt, and maintains masking
    When I review historical reminders
    Then only last 4 digits <masked_card> are ever shown; no duplicate notifications are generated for the same period

    Examples:
      | masked_card | orig_due_date | new_due_date |
      | 6066        | 2024-07-10    | 2024-07-15   |
      | 8811        | 2024-08-01    | 2024-08-08   |

  @ui @negative
  Scenario Outline: Duplicate Notification Prevention for Overdue Alerts
    Given a cardholder is in overdue status with card ending <masked_card>
    When an operator sends an overdue alert from UI at <timestamp>
    Then an alert is sent and masked correctly
    When another overdue alert is attempted within <repeat_window> via UI or API
    Then the system blocks the duplicate, displays an error or warning, and does not send notification
    And the audit outbox must not contain duplicates, and logs both initial and duplicate attempt
    And no full card number is ever shown

    Examples:
      | masked_card | timestamp           | repeat_window |
      | 4777        | 2024-07-16T10:00:00 | 24h           |
      | 3210        | 2024-08-02T15:30:00 | 48h           |

  @ui @positive
  Scenario Outline: Audit Review and Notification Tracking Across Multi-Channel Delivery
    Given a cardholder has notifications enabled for email, SMS, and app - card ending <masked_card>
    When I trigger overdue alert and payment plan proposal simultaneously
    Then the notification logs for each channel's delivery status are accessible in admin UI and all messages show only <masked_card>
    When I access the audit trail for sent notifications
    Then each channel and notification type has a corresponding audit entry with PII masking
    When accessing the UI reconciliation dashboard
    Then status mapping for each channel is accurate
    When one delivery channel <failed_channel> is offline
    Then delivery failure is shown, with audit log
    When I reattempt delivery after restoring <failed_channel>
    Then the audit logs record the new attempt, all messages remain masked

    Examples:
      | masked_card | failed_channel |
      | 4567        | SMS           |
      | 1313        | Email         |

  @ui @api @positive
  Scenario Outline: Data Refresh and Overwrite Post Payment after Agency Handoff
    Given a cardholder is already at agency handoff for card ending <masked_card>
    When I trigger notification and API handoff to agency, confirming masking
    When the cardholder makes a <payment_type> payment of <amount> via <channel>
    Then system updates balance, recalculates overdue/charges, and refreshes workflow
    When closure notification is retriggered, all displays and notifications show only <masked_card>
    When the agency receives update via API, only masked card data should be present
    When I review the admin UI for agency to normal/closed workflow reversal
    Then audit trail logs payment, state reversal, notification, and agency update with masking

    Examples:
      | masked_card | payment_type | amount | channel  |
      | 1111        | full        | 600    | portal   |
      | 2323        | partial     | 250    | app      |

  @ui @negative
  Scenario Outline: Multi-Stage Notification Failure Simulation with Manual Recovery and Compliance Checking
    Given cardholder accounts are staged at <workflow_stage> with notification engine enabled
    When I initiate <notification_type> notification and induce delivery failure
    Then the system logs the failure in audit trail, allows manual resend or alternate channel delivery, only sends masked card (last 4 digits <masked_card>)
    When I advance workflow to next stage and repeat failure simulation
    Then recovery logs and audit are updated, no unmasked card data exposed
    When regulatory compliance is triggered for repeated failures
    Then compliance alerts are generated and action logged

    Examples:
      | workflow_stage | notification_type | masked_card |
      | Due           | Reminder          | 9933        |
      | Overdue       | Overdue           | 6444        |
      | Collection    | Collection        | 7711        |
      | Legal         | Legal             | 2327        |

  # API Test Scenarios for Outbound Integration & Masking Enforcement

  @api @positive
  Scenario Outline: API Handoff Payload Masking and Compliance - Outbound Call to External Agency
    Given the base API URL is 'https://bankcore/api'
    And the authorization header is set with a valid bank operator token
    When I send a POST request to '/agency/handoff' with payload:
    """
    {
      "cardLast4": "<masked_card>",
      "overdueAmount": <overdue_amt>,
      "accountId": "<account_id>"
    }
    """
    Then the response status should be 200
    And the agency API only receives 'cardLast4' and no field with 'cardNumber' or full PII
    When a POST request is sent with full card number field
    Then the response status should be 400 and a compliance breach log is created

    Examples:
      | masked_card | overdue_amt | account_id   |
      | 3321        | 950.00      | ACCT10099    |
      | 8812        | 2500.55     | ACCT20981    |
