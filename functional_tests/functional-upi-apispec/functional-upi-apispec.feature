Feature: HSBC UPI Merchant API Suite - Comprehensive Functional, Boundary, Negative, Audit, Security, and E2E Test Coverage

  # API Test Scenarios

  Background:
    # API Test Setup
    Given the API base URL is set to the HSBC UPI endpoint
    And all requests are made over HTTPS with valid SSL certificates
    And valid test merchant credentials and keys are provisioned

  @api @functional
  Scenario Outline: Dynamic VPA Validation API - Successful and Failure Response Verification
    Given a merchant is registered and logged in
    And the Dynamic VPA Validation API endpoint is accessible
    When I send a POST request to '/api/dynamicVpaValidation' with payload
      """
      {
        "subscriberId": "<subscriberId>",
        "source": "<source>",
        "Rmn": "<rmn>"
      }
      """
    Then the response status should be 200
    And the 'transStatus' field should be '<expectedTransStatus>'
    And the 'transMessage' field should contain '<expectedMessage>'
    And the 'accountDetails' array should <accountDetailsExpectation>
    And no sensitive data should be present in response or logs

    Examples:
      | subscriberId        | source | rmn  | expectedTransStatus | expectedMessage                                               | accountDetailsExpectation                         |
      | VZNADT012310002     | SCB    |      | Success             | Success                                                       | contain subscriberId, accountStatus, subscriberName|
      | vznadt012310003     | SCB    |      | Failure             | Record not available for this Loan/Proposal No : vznadt012310003 | be empty                                         |
      | A                   | SCB    |      | Success             | Success                                                       | contain subscriberId, accountStatus, subscriberName|
      | VZNADT012310002     | SCB    | AB   | Success             | Success                                                       | contain subscriberId, accountStatus, subscriberName|
      |                     | SCB    |      | Failure             | Invalid subscriberId                                          | be empty                                         |
      | TOOLONG0123100034AB | SCB    |      | Failure             | Invalid subscriberId                                          | be empty                                         |

  @api @boundary
  Scenario Outline: Dynamic VPA Validation - Boundary SubscriberId Input Enforcement
    Given the Dynamic VPA Validation API endpoint is online
    When I send a POST request to '/api/dynamicVpaValidation' with payload
      """
      {
        "subscriberId": "<subscriberId>",
        "source": "SCB"
      }
      """
    Then the API should respond with status <status>
    And the response 'transStatus' field should be '<transStatus>'
    And the response 'transMessage' should reflect "<transMessage>"

    Examples:
      | subscriberId                | status | transStatus | transMessage                                   |
      | A                          | 200    | Success     | Success                                        |
      | VZNADT012310002            | 200    | Success     | Success                                        |
      |                            | 400    | Failure     | subscriberId Validation error                  |
      | TOOLONG0123100034AB        | 400    | Failure     | subscriberId Validation error                  |

  @api @functional
  Scenario Outline: Dynamic VPA Validation API - Optional Field RMN Handling
    Given the merchant is registered and API endpoint is live
    When I send a POST request to '/api/dynamicVpaValidation' with payload
      """
      {
        "subscriberId": "VZNADT012310002",
        "source": "SCB",
        "Rmn": "<Rmn>"
      }
      """
    Then the API should respond with status 200
    And 'transStatus' should be 'Success'
    And 'accountDetails' should contain subscriberId and subscriberName

    Examples:
      | Rmn   |
      |       |
      | AB    |

  @api @functional
  Scenario Outline: Pre-Credit VPA Validation API - Success and Failure
    Given the Pre-Credit Validation API endpoint is accessible
    When I send a POST request to '/api/preCreditValidation' with payload
      """
      {
        "refNo": "<refNo>",
        "payerId": "<payerId>",
        "payerVPA": "<payerVPA>",
        "transRemarks": "<transRemarks>",
        "transAmount": "<transAmount>",
        "transID": "<transID>",
        "transRRN": "<transRRN>",
        "source": "<source>",
        "addInfo1": "<addInfo1>",
        "addInfo2": "<addInfo2>"
      }
      """
    Then the response status should be 200
    And 'transStatus' should be '<transStatus>'
    And 'transMessage' should be '<transMessage>'
    And 'refNo' in response should match payload
    And 'transRRN' in response should be '<expectedTransRRN>'

    Examples:
      | refNo   | payerId    | payerVPA           | transRemarks      | transAmount | transID                       | transRRN       | source | addInfo1    | addInfo2 | transStatus | transMessage  | expectedTransRRN      |
      | 12837   | 9820982020 | aditya@hsbc        | Payment remarks   | 100.00      | HSB527498730B1B1BC3E053142433823107 | 717215233641 | HSBC   | info01      | info02   | S           | Success       | 717215233641          |
      | 12837   | 99999999   | invalidVPA@hsbc    | Payment attempt   | 100.00      | HSB527498730B1B1BC3E053142433823107 |              | HSBC   |             |          | F           | Invalid VPA   | (blank or empty)      |

  @api @boundary
  Scenario Outline: Pre-Credit Validation API - Boundary Check for refNo Input Length
    Given the Pre-Credit API endpoint is available
    When I send a POST request with refNo "<refNo>" and other valid mandatory fields
    Then the response status should be <status>
    And the response 'transStatus' should be '<transStatus>'
    And 'transMessage' should include "<message>"

    Examples:
      | refNo                 | status | transStatus | message              |
      | 12345                 | 400    | F           | refNo Validation error |
      | 123456                | 200    | S           | Success                |
      | 1234567890123456      | 200    | S           | Success                |
      | 12345678901234567     | 400    | F           | refNo Validation error |

  @api @functional @boundary
  Scenario Outline: Pre-Credit Validation API - Conditional transAmount Field
    Given the Pre-Credit API endpoint is running and merchant is authenticated
    When I send a POST request with transAmount "<transAmount>" and required fields
    Then the response status should be <status>
    And the response 'transStatus' should be '<transStatus>'
    And the response 'transMessage' should contain "<message>"

    Examples:
      | transAmount           | status | transStatus | message                        |
      | 100.00                | 200    | S           | Success                        |
      |                       | 400    | F           | transAmount Validation error   |
      | 100000000000000000    | 400    | F           | transAmount Validation error   |
      | -1                    | 400    | F           | Negative amount not allowed    |

  @api @audit
  Scenario Outline: Pre-Credit Validation API - Duplicity Handling with refNo
    Given the API endpoint is running with audit trail enabled
    When a POST request is made to '/api/preCreditValidation' with refNo "<refNo>"
    And a subsequent duplicate POST request is made with the same refNo
    Then the first response status should be 200 and 'transStatus' should be 'S'
    And the second response status should be 200 or 409 and should indicate duplicate refNo error
    And audit logs should record both attempts with timestamp, refNo, and detection event

    Examples:
      | refNo      |
      | ABC12345   |

  @api @functional
  Scenario Outline: Pre-Credit Validation API - Optional addInfo1-10 Handling
    Given the API endpoint is active
    When I send a POST request including addInfo fields as follows
      """
      {
        "addInfo1": "<addInfo1>",
        "addInfo2": "<addInfo2>",
        "addInfo3": "<addInfo3>",
        "addInfo4": "<addInfo4>",
        "addInfo5": "<addInfo5>",
        "addInfo6": "<addInfo6>",
        "addInfo7": "<addInfo7>",
        "addInfo8": "<addInfo8>",
        "addInfo9": "<addInfo9>",
        "addInfo10": "<addInfo10>"
      }
      """
    Then the response status should be 200
    And each addInfo field in the response should match the sent request
    And omission or empty fields should not trigger an error

    Examples:
      | addInfo1     | addInfo2     | addInfo3 | addInfo4 | addInfo5 | addInfo6 | addInfo7 | addInfo8 | addInfo9 | addInfo10                                         |
      | TestVal1     |              | 987      |          | Info     |          |          |          |          |                                                  |
      |              |              |          |          |          |          |          |          |          |                                                  |
      | testA        | testB        | empty    | TestD    | 12345    | testF    | testG    | testH    | testI    | testJ                                            |

  @api @boundary
  Scenario Outline: Pre-Credit Validation API - Boundary Value for transID Field
    Given the API endpoint for Pre-Credit Validation is accessible
    When I send a POST request with transID "<transID>"
    Then the response status should be <status>
    And the response 'transStatus' should be '<transStatus>'
    And the response 'transMessage' should include "<message>"

    Examples:
      | transID                                 | status | transStatus | message              |
      | HSB527498730B1B1BC3E053142433823107     | 200    | S           | Success              |
      | HSB527498730B1B1BC3E05314243382310      | 400    | F           | Invalid transID      |
      | HSB527498730B1B1BC3E053142433823107XX   | 400    | F           | Invalid transID      |
      | HSB527!98730B1B1BC3E053142433823107     | 400    | F           | Invalid transID      |

  @api @functional
  Scenario Outline: Post Credit / Final Response-Notification API - Success and Failure
    Given the Post Credit Notification API endpoint is whitelisted and reachable
    When HSBC POSTs to the merchant endpoint with payload
      """
      {
        "confStatus": "<confStatus>",
        "confMessage": "<confMessage>",
        "confId": "<confId>"
      }
      """
    Then the API response should be acknowledged with 200 or documented status
    And confStatus equals "<confStatus>"
    And confMessage equals "<confMessage>"
    And confId is <confIdExpectation>
    And logs record the notification with relevant fields

    Examples:
      | confStatus | confMessage | confId           | confIdExpectation           |
      | SUCCESS    | SUCCESS     | 1290381293989    | valid 13 digit numeric      |
      | FAILURE    | Reason      |                  | blank or omitted            |

  @api @boundary
  Scenario Outline: Post Credit / Final Response-Notification API - Boundary Check for confId Field
    Given a completed transaction notification is received
    When the merchant responds with confId "<confId>"
    Then the response is accepted if confId length <= 50
    And is rejected if confId length > 50
    And omission of confId does not cause an error

    Examples:
      | confId                                             | expectation      |
      | ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789AB | accepted        |
      | ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789A  | accepted        |
      | ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABC| rejected        |
      |                                                    | accepted        |

  @api @functional
  Scenario Outline: Post Credit / Final Response-Notification API - Optional addInfo1-10 Handling
    Given the merchant endpoint is live and receiving notification request
    When the response payload is submitted with addInfo fields as follows
      """
      {
        "addInfo1": "<addInfo1>",
        "addInfo2": "<addInfo2>",
        "addInfo3": "<addInfo3>",
        "addInfo4": "<addInfo4>",
        "addInfo5": "<addInfo5>",
        "addInfo6": "<addInfo6>",
        "addInfo7": "<addInfo7>",
        "addInfo8": "<addInfo8>",
        "addInfo9": "<addInfo9>",
        "addInfo10": "<addInfo10>"
      }
      """
    Then the notification is processed regardless of addInfo field presence or values
    And addInfo fields are echoed or persisted as submitted
    And missing/empty addInfo fields cause no error in processing

    Examples:
      | addInfo1     | addInfo2 | addInfo3      | addInfo4 | addInfo5      | addInfo6 | addInfo7    | addInfo8 | addInfo9        | addInfo10    |
      | TestAddInfo1 |          |               |          |               |          |             |          |                 |              |
      | 12345678901234567890123456789012345678901234567890|12345678901234567890123456789012345678901234567890|12345678901234567890123456789012345678901234567890|12345678901234567890123456789012345678901234567890|12345678901234567890123456789012345678901234567890|12345678901234567890123456789012345678901234567890|12345678901234567890123456789012345678901234567890|12345678901234567890123456789012345678901234567890|12345678901234567890123456789012345678901234567890|12345678901234567890123456789012345678901234567890|
      |              |          |               |          |               |          |             |          |                 |              |
      |             |          |               |          |               |          |             |          |                 |              |

  @api @state-transition
  Scenario Outline: Post Credit / Final Response-Notification - State Transition for Credit Card Transaction
    Given the merchant system supports credit card transactions and endpoint is active
    When a notification payload includes
      """
      {
        "addInfo4": "<addInfo4>",
        "transType": "<transType>",
        "payerAccNo": "<payerAccNo>",
        "payerBankIFSC": "<payerBankIFSC>"
      }
      """
    Then the merchant records the transaction as credit card payment with masked account details
    And the system logs addInfo4, transType, payerAccNo, and payerBankIFSC in audit trail
    And no sensitive fields are exposed outside permitted context

    Examples:
      | addInfo4 | transType | payerAccNo    | payerBankIFSC |
      | CREDIT   | PAY       | 071107734006  | HSBC0560002   |

  @api @functional
  Scenario Outline: VPA Status Validation API - Success and Failure
    Given the merchant integration is active
    When I send a POST request to '/api/vpaStatusValidation' with meRefNo "<meRefNo>", payerVPA "<payerVPA>", pgMerchantId '<pgMerchantId>'
    Then the response 'valStatusCode' should be "<valStatusCode>"
    And the response 'valStatusDesc' should be "<valStatusDesc>"
    And payerName is <payerNameExpectation>

    Examples:
      | meRefNo      | payerVPA          | pgMerchantId           | valStatusCode | valStatusDesc      | payerNameExpectation   |
      | 450824145    | aditya@hsbc       | HSBB000000000001       | VE            | VPA is valid       | present               |
      | 991000003    | notfound99999@invalid | HSBB000000000001   | VN            | VPA not available  | not present           |

  @api @boundary
  Scenario Outline: VPA Status Validation API - Boundary Value for meRefNo Field
    Given the API endpoint for VPA Status Validation is accessible
    When I send a POST request with meRefNo "<meRefNo>"
    Then the response status should be <status>
    And the response 'valStatusCode' should be '<valStatusCode>'
    And the response 'valStatusDesc' should reflect "<desc>"

    Examples:
      | meRefNo                       | status | valStatusCode | desc                                |
      | ME0001                        | 200    | VE            | Success                             |
      | ME0000000000000000000000000001| 200    | VE            | Success                             |
      | ME001                         | 400    | V             | meRefNo Validation error            |
      | ME00000000000000000000000000001| 400   | V             | meRefNo Validation error            |

  @api @functional
  Scenario Outline: VPA Status Validation API - Conditional payerName Retrieval
    Given the API endpoint for VPA Status Validation is accessible
    When a POST request is sent with a valid payerVPA "<payerVPA>" and meRefNo "<meRefNo>"
    Then the response contains payerName if available, otherwise field is omitted or empty

    Examples:
      | payerVPA            | meRefNo      | payerNameExpectation   |
      | aditya@hsbc         | ME0006       | present                |
      | doname@nowhere      | ME0007       | absent or empty        |

  @api @functional
  Scenario Outline: Collect Request API - Success and Failure Scenarios
    Given the merchant is active and Collect Request API is accessible
    When I send a POST request to '/api/meCollect' with payload
      """
      {
        "pgMerchantID": "<pgMerchantID>",
        "meOrderNo": "<meOrderNo>",
        "payerVPA": "<payerVPA>",
        "transAmount": "<transAmount>",
        "expiryValue": "<expiryValue>",
        "transRemarks": "<transRemarks>",
        "payerName": "<payerName>",
        "addInfo1": "<addInfo1>",
        "addInfo2": "<addInfo2>"
      }
      """
    Then the API responds with collStatus "<collStatus>"
    And collStatusDesc equals "<collStatusDesc>"
    And transAmount is echoed if success
    And error should be returned for invalid or missing mandatory fields

    Examples:
      | pgMerchantID      | meOrderNo     | payerVPA         | transAmount | expiryValue | transRemarks         | payerName      | addInfo1 | addInfo2 | collStatus | collStatusDesc         |
      | HSBB000000000001  | COLL10001     | testuser@hsbc    | 500.00      | 64800       | Collect from testuser|               |          |          | I          | Transaction Initiated  |
      | HSBB000000000001  | FAIL10001     | invaliduser@hsbc |             | -5          | Failure test         |               |          |          | F          | Failure                |
      | HSBB000000000001  | EXCEP1001     | testuser@hsbc    | 100.00      | 64801       | Edge expiry value    |               |          |          | E          | Exception at UPI      |

  @api @boundary
  Scenario Outline: Collect Request API - Boundary Value for expiryValue
    Given the collect API endpoint is running
    When I submit a request with expiryValue "<expiryValue>"
    Then the API returns collStatus '<collStatus>'
    And collStatusDesc reflects the processing result

    Examples:
      | expiryValue | collStatus | collStatusDesc          |
      | 64800       | I          | Transaction Initiated   |
      | 64801       | F          | expiryValue Validation error |

  @api @functional
  Scenario Outline: Collect Request API - Optional payerName Field
    Given the collect API endpoint is running
    When a request is submitted with payerName "<payerName>"
    Then the response includes payerName if set
    And response omits payerName if not set
    And downstream logs/audit reference payerName if present

    Examples:
      | payerName             | expectation     |
      | OPTIONUSER TEST       | present         |
      |                      | absent/not present |

  @api @boundary
  Scenario Outline: Collect Request API - Boundary Value for transAmount
    Given the collect API endpoint is available
    When a request is submitted with transAmount "<transAmount>"
    Then the API returns collStatus '<collStatus>'
    And collStatusDesc matches result
    And only valid amounts should create transactions

    Examples:
      | transAmount               | collStatus | collStatusDesc        |
      | 0.01                      | I          | Transaction Initiated |
      | 9999999999999999.99       | I          | Transaction Initiated |
      | 10000000000000000         | F          | transAmount Validation error |

  @api @functional
  Scenario Outline: Collect Request API - Optional addInfo1-10 Field Usage
    Given collect API endpoint is live
    When the collect request includes addInfo fields as follows
      """
      {
        "addInfo1": "<addInfo1>",
        "addInfo2": "<addInfo2>",
        "addInfo3": "<addInfo3>",
        "addInfo4": "<addInfo4>",
        "addInfo5": "<addInfo5>",
        "addInfo6": "<addInfo6>",
        "addInfo7": "<addInfo7>",
        "addInfo8": "<addInfo8>",
        "addInfo9": "<addInfo9>",
        "addInfo10": "<addInfo10>"
      }
      """
    Then the API response returns addInfo fields as submitted
    And no error is thrown for blank or omitted fields

    Examples:
      | addInfo1     | addInfo2 | addInfo3     | addInfo4  | addInfo5 | addInfo6 | addInfo7 | addInfo8 | addInfo9 | addInfo10    |
      | TESTDATA1    |          | TESTDATA3    | TESTDATA4 |          |          |          |          |          | TESTDATA10   |
      |              |          |              |           |          |          |          |          |          |              |

  @api @functional
  Scenario Outline: Transaction Status Enquiry API - Success and Conditional Field Presence
    Given the Transaction Status Enquiry API is active
    When a POST request is sent with meRefNo "<meRefNo>", transRRN "<transRRN>", meOrderNo "<meOrderNo>", and pgMerchantID "<pgMerchantID>"
    Then the response should have transStatus "<transStatus>"
    And transMessage "<transMessage>"
    And transRRN is <transRRNExpectation>
    And audit log records completion or pending as per status

    Examples:
      | meRefNo   | transRRN      | meOrderNo | pgMerchantID         | transStatus | transMessage      | transRRNExpectation        |
      | ENQ1001   | 700000000001  | ENQ1001   | HSBB000000000001     | S           | Payment Successful | present                    |
      | ENQ1002   |               | ENQ1002   | HSBB000000000001     | P           | Pending Approval   | absent or blank            |

  @api @state-transition
  Scenario Outline: Transaction Status Enquiry API - Multi-stage State Checks
    Given the status enquiry API is running
    When a transaction exists in "<state>" state
    And I submit status enquiry
    Then the response transStatus is "<state>"
    And status message is correct per specification

    Examples:
      | state | message                    |
      | S     | Payment Successful         |
      | P     | Pending for Approval       |
      | F     | Failed                     |
      | R     | Rejected                   |
      | X     | Expired                    |
      | E     | Exception at UPI           |

  @api @functional
  Scenario Outline: Refund API - Success and Failure Scenarios
    Given Refund API endpoint '/api/meRefund' is accessible
    When a merchant submits a refund request with
      """
      {
        "pgMerchantId": "<pgMerchantId>",
        "newMeOrderNo": "<newMeOrderNo>",
        "orgMeOrderNo": "<orgMeOrderNo>",
        "orgTransId": "<orgTransId>",
        "orgTransRRN": "<orgTransRRN>",
        "refundAmount": "<refundAmount>",
        "addInfo1": "<addInfo1>",
        "addInfo5": "<addInfo5>",
        "addInfo10": "<addInfo10>"
      }
      """
    Then the API response should have refundStatus "<refundStatus>"
    And refundMessage "<refundMessage>"
    And refundAmount matches request
    And no refund is processed for failure scenarios

    Examples:
      | pgMerchantId         | newMeOrderNo  | orgMeOrderNo | orgTransId        | orgTransRRN     | refundAmount          | addInfo1       | addInfo5   | addInfo10    | refundStatus | refundMessage            |
      | HSBB000000000001     | REF10001      | ENQ1001      | TXN987654321      | 700000000001    | 100.00               |                |            |              | S            | Success                  |
      | HSBB000000000001     | REF10002      | ENQ1002      | BADTXN999999999   | 700000000009    | 100.00               |                |            |              | F            | Record not available      |
      | HSBB000000000001     | REF10003      | ENQ1001      | TXN987654321      | 700000000001    | 0.99                 |                |            |              | F            | refundAmount Validation error |
      | HSBB000000000001     | REF10004      | ENQ1001      | TXN987654321      | 700000000001    | 99999999999999.99    | testdata01     | info88888  | 12345678901234567890123456789012345678901234567890 | S | Success        |
      | HSBB000000000001     | REF10005      | ENQ1001      | TXN987654321      | 700000000001    | 1000000000000000.00  |                |            |              | F            | refundAmount Validation error |
      | HSBB000000000001     | REF10006      | ENQ1001      | TXN987654321      | 700000000001    | 10.001               |                |            |              | F            | refundAmount Precision error |

  @api @functional
  Scenario Outline: Refund API - Optional addInfo1-10 Field Verification
    Given Refund API endpoint is available
    When merchant submits refund request with addInfo fields as follows
      """
      {
        "addInfo1": "<addInfo1>",
        "addInfo5": "<addInfo5>",
        "addInfo10": "<addInfo10>"
      }
      """
    Then API responds with refundStatus 'S' for valid refund
    And addInfo fields in response match the request if present
    And blank or omitted fields do not cause error

    Examples:
      | addInfo1     | addInfo5      | addInfo10                                         |
      |              |               |                                                  |
      | testdata01   | info88888     | 12345678901234567890123456789012345678901234567890|
      | fieldA       | fieldB        | fieldC                                            |

  # Security Test Scenarios

  @security
  Scenario Outline: API Encryption and Decryption with UPIKit (DotNet/Java)
    Given the merchant key is securely provisioned by HSBC
    When the merchant constructs request payload and invokes Encrypt() from UPIKit with key "<encryptionKey>"
    Then the requestMsg field is populated with ciphertext and sent over HTTPS
    And HSBC server accepts and processes encrypted messages
    When the merchant receives encrypted reply, invokes Decrypt() method with correct key "<decryptionKey>"
    Then the decrypted fields match expected values
    But using incorrect keys "<wrongKey>" rejects requests or fails decryption

    Examples:
      | encryptionKey              | decryptionKey               | wrongKey             |
      | easd343dsdsdsdsde3243dfffdeerfff | easd343dsdsdsdsde3243dfffdeerfff | randomkey123      |
      | hsbc-merch-key123          | hsbc-merch-key123           | nothsbc-merch        |

  @security
  Scenario Outline: Certificate Exchange and SSL Validation
    Given merchant server keystore is configured for API access
    When HSBC-issued certificate is NOT imported or imported with incorrect alias "<alias>"
    Then outgoing API requests fail authentication/connection
    When certificate is imported with valid alias "<validAlias>"
    Then API requests successfully connect
    And audit logs reflect all connection/result diagnostics

    Examples:
      | alias     | validAlias   |
      | wrongalias| mykey        |
      |           | hsbc-key     |

  @security
  Scenario Outline: SSL Certificate Network Validation for API Access
    Given merchant server has SSL certificate installed
    When API requests are sent over HTTPS with valid certificate
    Then connection is successful
    When SSL certificate is invalid or missing
    Then API request fails with documented error
    When request is sent over HTTP (non-SSL)
    Then API request is rejected/not processed

    Examples:
      | scenario          |
      | valid SSL         |
      | invalid SSL       |
      | missing SSL       |
      | HTTP connection   |

  @security
  Scenario Outline: Public IP Whitelisting for Final Response Callback Acceptance
    Given merchant callback URL is registered and firewall rules are set
    When requests are received from IP "<sourceIP>"
    Then request is accepted if IP matches whitelisted range
    And rejected/blocked if not in allowed range
    And logs are created for all attempts

    Examples:
      | sourceIP           | expectation       |
      | 203.171.209.5      | accepted         |
      | 203.171.222.6      | accepted         |
      | 203.171.209.8      | rejected         |

  @security
  Scenario Outline: HTTPS Communication Enforcement for API
    Given merchant API endpoint is configured
    When API requests are submitted over HTTPS (SSL)
    Then connection and transaction succeeds
    When API requests are submitted over HTTP or with expired certificate
    Then connection is refused or error is returned

    Examples:
      | protocol  | expectation      |
      | HTTPS     | success          |
      | HTTP      | rejected         |
      | HTTPS-expired | error        |

  # Toolkit Integration Test Scenarios

  @functional
  Scenario Outline: DLL Integration for Encryption (.NET Stack)
    Given upikit.dll is present in project directory and added as reference
    When UPISecurity.Encrypt() is called with string "<plainMessage>" and key "<encKey>"
    Then the result is valid ciphertext string
    And ciphertext is used in API requestMsg field sent to HSBC
    And no sensitive data appears in logs

    Examples:
      | plainMessage       | encKey                  |
      | "test encrypt .net"| easd343dsdsdsdsde3243dfffdeerfff |
      | "sample foo"       | hsbc-merch-key123       |

  @functional
  Scenario Outline: Jar Integration for Encryption (Java Stack)
    Given UPIKit.jar is present and added to Java classpath
    When UPISecurity.encrypt() is called with message "<plainMessage>" and key "<encKey>"
    Then encrypted data is used in requestMsg for API outbound payload
    And HSBC API endpoint accepts encrypted request
    And logs show no sensitive data leaks

    Examples:
      | plainMessage       | encKey                  |
      | "message which needs to be encrypted"| hsbc-java-key        |
      | "foo bar"          | easd343dsdsdsdsde3243dfffdeerfff |

  @audit
  Scenario Outline: PHP Toolkit Zip File Validation
    Given UPI_Merchant_Tool_Kit_PHP.zip1 is downloaded
    When file is renamed to 'UPI_Merchant_Tool_Kit_PHP.zip'
    And extraction is performed
    Then installation succeeds with all files present
    And wrapper files can be referenced in sample PHP code for encrypt/decrypt
    And toolkit functions as documented

    Examples:
      | toolkitZip         |
      | UPI_Merchant_Tool_Kit_PHP.zip1 |

  # E2E Test Scenarios

  @e2e
  Scenario Outline: End-to-End Collect Request to Final Notification
    Given merchant UPI integration is complete and callback endpoint registered/whitelisted
    When merchant initiates a Collect Request for meOrderNo "<meOrderNo>" and payerVPA "<payerVPA>"
    And customer approves payment at PSP app
    And HSBC triggers FINAL Response callback with confStatus "<confStatus>" and confId "<confId>"
    Then merchant logs confirm transaction status and confirmation fields are consistent

    Examples:
      | meOrderNo   | payerVPA        | confStatus | confId           |
      | COLL20001   | enduser@hsbc    | SUCCESS    | 1456789012345    |

  @e2e
  Scenario Outline: End-to-End Flow with Status Enquiry and Refund
    Given merchant UPI system and callback endpoint are in place
    When merchant initiates collect request, receives payment, sends status enquiry with meOrderNo "<meOrderNo>", transRRN "<transRRN>", then invokes refund API with orgMeOrderNo, orgTransRRN "<orgTransRRN>"
    Then status enquiry returns transStatus "<transStatus>"
    And refund API responds with refundStatus "<refundStatus>", refundMessage "<refundMessage>"
    And all IDs are properly linked and returned

    Examples:
      | meOrderNo   | transRRN     | orgTransRRN    | transStatus | refundStatus | refundMessage |
      | COLL20002   | 700000000011 | 700000000011   | S           | S            | Success       |

  @e2e
  Scenario Outline: End-to-End Payment with VPA Validation prior to Collect
    Given merchant account and API access are set up
    When VPA Status Validation API is invoked for payerVPA "<payerVPA>"
    And API returns valStatusCode "<valStatusCode>" and payerName "<payerName>"
    And Collect Request API is initiated only for valid VPA
    Then payment workflow proceeds to completion and merchant receives final notification

    Examples:
      | payerVPA         | valStatusCode | payerName     |
      | validuser@hsbc   | VE            | ADITYA SHARMA |

  @state-transition
  Scenario Outline: Transaction Status Enquiry API - All State Transitions and Rejections
    Given merchant UPI integration and status enquiry API access
    When merchant requests status for transaction in state "<state>"
    Then response shows transStatus "<state>" and appropriate message
    And invalid status transition attempts are rejected

    Examples:
      | state | message                         |
      | S     | Payment Successful              |
      | P     | Pending for Approval            |
      | F     | Failed                          |
      | R     | Rejected                        |
      | X     | Expired                         |
      | E     | Exception at UPI                |

