Feature: Credit Card Notification Masking, State Transitions, Audit, and Compliance

  # Background for API scenarios (authentication, base URL)
  Background:
    Given the API base URL is 'https://api.creditcardplatform.test'
    And authorization is enabled with role-specific tokens

  # ------------------- API Test Scenarios -------------------

  @api
  Scenario Outline: Automated Credit Card Due Reminder Notification Workflow (CCCN-01)
    Given cardholder '<cardholder_id>' has an active account with due date in 5 days and valid contact details
    When a POST request is made to "/api/notifications/reminder" with payload:
      """
      {
        "cardholderId": "<cardholder_id>",
        "scheduledAt": "<due_date_minus_5_days>"
      }
      """
    Then the response status should be 201
    And the notification sent to cardholder should only display last 4 digits "<masked_digits>"
    And no full card number should be present in content
    And the audit trail shows notification trigger and delivery timestamp

    Examples:
      | cardholder_id | due_date_minus_5_days | masked_digits     |
      | CH001         | 2024-07-25            | **** **** **** 1234 |

  @api
  Scenario Outline: Overdue Balance Alert at Escalation Threshold (Boundary) (CCCN-02)
    Given cardholder '<cardholder_id>' missed payment deadline; balance is exactly at escalation threshold
    When a POST request is made to "/api/notifications/overdue" with payload:
      """
      {
        "cardholderId": "<cardholder_id>",
        "overdueAmount": "<threshold_amount>",
        "cardNumberMasked": "<masked_digits>"
      }
      """
    Then the response status should be 201
    And overdue alert notification is sent promptly
    And notification displays only the last 4 digits "<masked_digits>"
    And escalation trigger is enabled
    And audit logs show proper masking and delivery

    Examples:
      | cardholder_id | threshold_amount | masked_digits     |
      | CH002         | 1000             | **** **** **** 5678 |

  @api
  Scenario Outline: System Blocks Notification With Unmasked/Card Exposed (Negative PII Masking) (CCCN-03)
    Given notification template with full card number "<full_card_number>" inserted for cardholder '<cardholder_id>'
    When a POST request is made to "/api/notifications/send" with payload:
      """
      {
        "cardholderId": "<cardholder_id>",
        "cardNumber": "<full_card_number>",
        "method": "<method>"
      }
      """
    Then the response status should be 400
    And system blocks delivery with masking validation error
    And audit logs show failure due to masking check
    And no UI or integration displays full card number

    Examples:
      | cardholder_id | full_card_number     | method    |
      | CH003         | 4111 2222 3333 9876  | email     |
      | CH003         | 4111 2222 3333 9876  | SMS       |
      | CH003         | 4111 2222 3333 9876  | letter    |
      | CH003         | 4111 2222 3333 9876  | integration |

  @api
  Scenario Outline: Payment Plan Proposal, Acceptance, and Cancellation (State-Transition) (CCCN-04)
    Given overdue account '<cardholder_id>' is eligible for payment plan proposal
    When the issuer triggers payment plan proposal via POST "/api/paymentplans/propose" with payload:
      """
      {
        "cardholderId": "<cardholder_id>"
      }
      """
    Then the response status should be 201
    And proposal notification with masked last 4 digits "<masked_digits>" delivered to cardholder
    When cardholder accepts payment plan via PATCH "/api/paymentplans/<proposal_id>/accept"
    Then state transitions from overdue to payment plan
    When cardholder cancels payment plan via PATCH "/api/paymentplans/<proposal_id>/cancel"
    Then system reverts account to prior state (overdue)
    And audit logs record proposal, acceptance, cancellation, masking

    Examples:
      | cardholder_id | masked_digits         |
      | CH004         | **** **** **** 4321   |

  @api
  Scenario Outline: Overdue Alert Batch for Multiple Cards (Boundary) (CCCN-06)
    Given cardholder '<cardholder_id>' has multiple overdue credit cards on same day
    When a POST request is made to "/api/notifications/overdue/batch" with payload:
      """
      {
        "cardholderId": "<cardholder_id>",
        "cards": [
          {"cardId": "<card1_id>", "maskedCard": "<masked_digits_1>"},
          {"cardId": "<card2_id>", "maskedCard": "<masked_digits_2>"}
        ]
      }
      """
    Then separate overdue notifications are sent for each card
    And each notification contains correct masked last 4 digits <masked_digits_1> and <masked_digits_2>
    And audit logs show independent triggers and masking verification per card
    And no cross-account contamination occurs

    Examples:
      | cardholder_id | card1_id | masked_digits_1      | card2_id | masked_digits_2      |
      | CH005         | C001     | **** **** **** 2468  | C002     | **** **** **** 1357  |

  @api
  Scenario Outline: Unauthorized Collection Agency Access Attempt (Negative Security) (CCCN-07)
    Given collection agency user '<agency_user>' is logged in but handover not completed
    When a GET request is made to "/api/accounts/overdue" as agency user
    Then the response status should be 403
    And no card information (masked or full) is revealed
    And audit log records access attempt and security event

    Examples:
      | agency_user |
      | AG001       |

  @api
  Scenario Outline: Irreversible Escalation to Legal Action (State-Transition) (CCCN-08)
    Given issuer initiates legal action for account '<cardholder_id>' post-agency escalation
    When a POST request is made to "/api/legal/escalate" with payload:
      """
      {
        "cardholderId": "<cardholder_id>"
      }
      """
    Then legal documentation contains only masked last 4 digits "<masked_digits>"
    And account state changes to legal escalation and cannot be reverted
    And audit trail captures escalation and masking validation
    When issuer attempts to reverse legal state via PATCH "/api/legal/escalate/revert"
    Then system blocks state change and logs audit event

    Examples:
      | cardholder_id | masked_digits         |
      | CH006         | **** **** **** 8520   |

  @api
  Scenario Outline: Payment Plan Eligibility and Alert Override Decision Table (Calculation/Decision Table) (CCCN-10)
    Given issuer triggers payment plan proposal workflow for overdue account '<cardholder_id>' with balance '<balance>' and payment history '<history>'
    When a POST request is made to "/api/paymentplans/propose" with payload:
      """
      {
        "cardholderId": "<cardholder_id>",
        "balance": <balance>,
        "history": "<history>"
      }
      """
    Then eligibility selection matches decision table
    And for eligible, proposal sent with masked digits "<masked_digits>"
    And for rejected, masked rejection alert sent
    And audit logs record eligibility calculation and masking check

    Examples:
      | cardholder_id | balance | history    | eligibility | masked_digits          |
      | CH010         | 1200    | good       | eligible    | **** **** **** 5892    |
      | CH011         | 900     | failed     | rejected    | **** **** **** 3920    |

  @api
  Scenario Outline: Overdue Amount Recalculation with Partial Payments (Calculation) (CCCN-14)
    Given cardholder '<cardholder_id>' has multiple overdue cards with partial payments posted
    When a PATCH request is made to "/api/accounts/<card_id>/payment" with payload:
      """
      {
        "amount": <partial_payment>
      }
      """
    And system recalculates overdue balance for each account
    When batch overdue alert is triggered via POST "/api/notifications/overdue/batch"
    Then each alert contains last 4 digits "<masked_digits>"
    And audit logs record recalculation and alert delivery

    Examples:
      | cardholder_id | card_id  | partial_payment | masked_digits         |
      | CH014         | C021     | 300             | **** **** **** 3927   |
      | CH014         | C022     | 150             | **** **** **** 7048   |


  # ------------------- UI Test Scenarios -------------------

  @ui
  Scenario Outline: Cross-Role Notification UI Content Review (CCCN-09)
    Given issuer logs into UI dashboard and locates delinquent account '<cardholder_id>'
    When issuer generates collection notification via UI
    And reviews content in notification preview
    Then masked identifier "<masked_digits>" is visible and no full number displayed
    When cardholder logs in and views notification
    Then masked identifier is confirmed in cardholder UI
    And both issuer and cardholder review audit trail for notification event

    Examples:
      | cardholder_id | masked_digits         |
      | CH009         | **** **** **** 7777   |

  @ui
  Scenario Outline: Payment Plan Cancellation UI Workflow (Boundary) (CCCN-11)
    Given cardholder '<cardholder_id>' is enrolled in payment plan with partial payment complete
    When cardholder initiates cancellation request from UI
    And issuer reviews cancellation eligibility at boundary condition
    Then cancellation notification shows only last 4 digits "<masked_digits>" in UI/email/SMS
    And account state transitions from payment plan to overdue or delinquent
    And audit log records payment, cancellation, masking, and state transition

    Examples:
      | cardholder_id | masked_digits         |
      | CH011         | **** **** **** 9573   |

  @ui
  Scenario Outline: Legal Documentation Download with Masking and Audit (CCCN-15)
    Given legal participant logs into UI dashboard for legal accounts
    When legal user selects account '<cardholder_id>' for documentation review and download
    Then communication history displays only masked last 4 digits "<masked_digits>"
    And legal documentation download always enforces masking
    And audit log records access, download, masking validation
    When legal user attempts to view or edit card data
    Then system blocks display of unmasked card number
    And audit log records attempted edit

    Examples:
      | cardholder_id | masked_digits         |
      | CH015         | **** **** **** 2831   |

  @ui
  Scenario Outline: Erroneous Collection Notification Recurrence Blocked (Negative) (CCCN-13)
    Given issuer is on communication dashboard with closed account '<cardholder_id>'
    When collection notification recurrence job is simulated via UI
    And issuer attempts to trigger collection notification for closed account
    Then system blocks notification sending
    And no template is generated for email/SMS/UI
    And audit log records blocked event and reason
    And system blocks manual override attempts
    And no masked or unmasked card number appears anywhere

    Examples:
      | cardholder_id |
      | CH013         |

  @ui
  Scenario Outline: Collection Agency Communication and Audit Trail via UI (State-Transition) (CCCN-12)
    Given collection agency user logs into UI post-handover for account '<cardholder_id>'
    When agency initiates communication for overdue balance via UI
    Then content preview and sent message show only masked last 4 digits "<masked_digits>"
    And agency user accesses audit log and verifies masking for each communication event
    When agency edits or regenerates message template in UI
    Then masking enforcement is validated
    And audit log records edit attempt

    Examples:
      | cardholder_id | masked_digits         |
      | CH012         | **** **** **** 6432   |

  @ui
  Scenario Outline: Credit Card Collections Journey: Role-based UI Workflow (End-to-End) (CCCN-05)
    Given cardholder, issuer, collection agency, and legal roles are enabled for account '<cardholder_id>'
    When due reminder, overdue alert, collection notification, payment plan, agency communications, and legal actions are triggered in sequence via UI workflows
    Then all notifications display only last 4 digits "<masked_digits>"
    And each workflow step is recorded in audit log with masking validation
    And no unmasked card number is exposed at any stage
    And system timing matches alerting policy for each step

    Examples:
      | cardholder_id | masked_digits         |
      | CH005         | **** **** **** 1111   |
