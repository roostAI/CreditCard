Feature: HSBC UPI API Functional, Boundary, Security, Audit, and Resilience Test Coverage

  # API Tests – Merchant Onboarding & Encryption Key Generation
  @api @onboarding
  Scenario Outline: Merchant ID generation and uniqueness workflow
    Given the HSBC UPI onboarding API is live
    And merchant onboarding prerequisites are fulfilled with valid documents
    When I submit a merchant onboarding request with JSON payload:
      """
      {
        "companyName": "<companyName>",
        "legalEntityId": "<legalEntityId>",
        "contactEmail": "<email>"
      }
      """
    Then the API response status should be 201
    And the response should contain "merchantId" as a UUID
    And merchantId is persisted in HSBC onboarding database
    And no duplicate merchantId exists for "<legalEntityId>"
    And audit log entry is created for merchantId creation event

    Examples:
      | companyName    | legalEntityId   | email                |
      | Acme Solutions | ACME202357      | ops@acme.com         |
      | Test Merchant  | TEST001         | merchant@test.co.in  |

  # API Tests – Encryption Key Assignment & Receipt
  @api @encryption
  Scenario Outline: API encryption key assignment and secure transmission
    Given the merchant has a valid merchantId "<merchantId>" and onboarding confirmed
    When I request key assignment with merchantId "<merchantId>"
    Then HSBC generates a unique symmetric encryption key and responds with
      """
      {
        "encryptionKey": "<encryptionKey>"
      }
      """
    And the key is delivered securely via portal download or encrypted email
    And merchant imports the encryption key into application key store
    And merchant can decrypt HSBC test payload with the new key
    And audit logs validate key generation and delivery
    And encryption key is not exposed in logs or audit records

    Examples:
      | merchantId        | encryptionKey        |
      | HSBB000000001122  | abcd1234securekey!  |
      | HSBM000000001234  | testkey5678xyz!     |

  # API Tests – Merchant Endpoint Hosting Capability Validation
  @api @integration
  Scenario Outline: Merchant API endpoint readiness and accessibility
    Given merchant has deployed a test API endpoint "<merchantEndpointUrl>" with HTTPS and whitelisting
    When HSBC sends a test request to "<merchantEndpointUrl>" and merchant API responds with JSON
    Then HSBC receives a valid response within allowed latency
    And TLS is enabled and verified
    And endpoint setup is confirmed for production access

    Examples:
      | merchantEndpointUrl                  |
      | https://merchant1.com/api/testhost   |
      | https://acme.upi.com/api/readytest   |

  # Security Tests – HTTPS/SSL Connectivity Enforcement
  @security @ssl
  Scenario Outline: API SSL handshake validation and HTTPS-only enforcement
    Given merchant possesses HSBC-issued certificate file "<certFile>" and server is SSL configured
    When merchant attempts HTTPS handshake to HSBC UPI endpoint "<hsbcEndpoint>" using port 443 and valid cert
    Then handshake and API request is successful
    When merchant attempts plain HTTP connection to "<hsbcEndpoint>"
    Then connection is rejected and audit logs record the attempt
    And all API requests are validated by HSBC using merchant certificate

    Examples:
      | certFile              | hsbcEndpoint                      |
      | merchantSSL.cer       | https://upi.hsbc.com/secureapi    |
      | HSBCMerchantCert.cer  | https://api.hsbc.com/upi/v1       |

  # Boundary & Negative API Validation – Dynamic VPA Validation
  @api @negative @boundaries
  Scenario Outline: Dynamic VPA Validation API error path for invalid subscriberId
    Given merchant is onboarded and has API credentials
    When I POST Dynamic VPA Validation request with encrypted payload:
      """
      {
        "subscriberId": "<subscriberId>",
        "source": "SCB"
      }
      """
    To endpoint /api/vpa/validate
    Then API response contains "transStatus": "Failure"
    And "transMessage" is "Record not available for this Loan/Proposal No : <subscriberId>"
    And "accountDetails" array is empty
    And audit log entry is created for validation failure

    Examples:
      | subscriberId  |
      | testsub999    |
      | invalid001    |

  Scenario Outline: Boundary length test for Dynamic VPA subscriberId field
    Given Dynamic VPA Validation API is live and merchant credentials are available
    When I submit a request with subscriberId "<subscriberId>"
    Then If length is 1, response is either Success or boundary error
    And If length is empty, response contains field mandatory error
    And If length is >250, response contains length validation error

    Examples:
      | subscriberId                                |
      | A                                           |
      |                                             |
      | AB                                          |
      | AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA...A255 |  # 255 chars
      | AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA...A251 |  # 251 chars

  # API Tests – Optional Field Handling in Dynamic VPA Validation
  @api
  Scenario Outline: Dynamic VPA Validation API with optional and omitted Rmn field
    Given merchant credentials and endpoint access
    When I submit request with subscriberId "<subscriberId>" and optional field Rmn "<rmn>"
    Then API responds successfully and response is consistent regardless if Rmn is present or omitted

    Examples:
      | subscriberId | rmn   |
      | SCB1001      | XY    |
      | SCB1002      |       |

  # Functional API Test – Pre-Credit VPA Validation Success/Failure Response
  @api @precredit
  Scenario Outline: Pre-Credit VPA Validation API result for both positive and negative payerId input
    Given merchant onboarding and authorization complete
    When I send Pre-Credit VPA Validation API request with
      """
      {
        "refNo": "<refNo>",
        "payerId": "<payerId>",
        "transID": "<transID>",
        "transRRN": "<transRRN>"
      }
      """
    Then If payerId is valid, response contains "transStatus":"S", "transMessage":"Success", and matches provided RRN, pgMerchantId
    And If payerId is invalid, response contains "transStatus":"F", "transMessage":"Invalid VPA", and "transRRN" is empty

    Examples:
      | refNo   | payerId            | transID       | transRRN      |
      | 900123  | validpayer@bank    | TXN123456     | 717215233641  |
      | 900124  | badvpa@            | TXN123457     |               |
      | 900125  | invalidpayer@bank1 | TXN123458     |               |

  # State Transition Test – Duplicate refNo Handling for Idempotency (Pre-Credit VPA Validation)
  @api @idempotency
  Scenario Outline: Pre-Credit VPA Validation duplicate refNo flow
    Given merchant API endpoint and credentials in place
    When I submit Pre-Credit VPA Validation request with refNo "<refNo>"
    Then First submission returns "transStatus":"S"
    When I resubmit same request with identical refNo "<refNo>"
    Then Second/third submission is flagged/rejected for duplicate with "transStatus":"F" or duplicity error in "transMessage"

    Examples:
      | refNo    |
      | 456789   |
      | 789012   |

  # API Tests – Optional/Conditional Pre-Credit VPA API Fields
  @api
  Scenario Outline: Pre-Credit VPA Validation API with optional and conditional fields present, omitted, or empty
    Given merchant onboarding complete and API live
    When I submit request with the following permutations:
      """
      {
        "transRefID": "<transRefID>",
        "payerAccNo": "<payerAccNo>",
        "addInfo1": "<addInfo1>",
        "addInfo2": "<addInfo2>"
      }
      """
    Then All requests are accepted and return "transStatus":"S" unless input purposely invalid
    And API does not reject or fail for missing or empty optional/conditional fields

    Examples:
      | transRefID     | payerAccNo    | addInfo1     | addInfo2 |
      |                |               |              |          |
      | testRef123     | 123456789012  | TestInfo     | Info2    |
      |                |               |              | Info2    |

  # API Tests – Post Credit Notification Success Path (Merchant responses)
  @api @postcredit
  Scenario Outline: Post Credit Notification API Response with Confirmation ID
    Given merchant notification endpoint is whitelisted and ready
    When HSBC POSTS a final notification to merchant with:
      """
      {
        "refNo": "<refNo>",
        "transRRN": "<transRRN>",
        "pgMerchantId": "<pgMerchantId>"
      }
      """
    Then Merchant responds with
      """
      {
        "confStatus": "SUCCESS",
        "confMessage": "SUCCESS",
        "confId": "<confId>"
      }
      """
    And confirmation ID ("confId") is unique and properly formatted
    And HSBC logs and persists the response mapping to refNo

    Examples:
      | refNo      | transRRN     | pgMerchantId         | confId           |
      | 2394829    | 717215233641 | HSB000000000001      | 1290381293989    |
      | 889911     | 726513237727 | HSBB000000000747     | CONF2023TRACE0001|

  # Audit API Tests – Notification ID Traceability & Logging
  @audit @postcredit
  Scenario Outline: Notification ID ('confId') traceable in HSBC systems and merchant logs
    Given A completed transaction and notification with confId "<confId>" sent by merchant
    When I query HSBC internal transaction and audit logs for confId "<confId>"
    Then ConfId appears in all relevant logs (transaction, audit, API gateway)
    And audit trail includes timestamp, refNo, transRRN, confId
    And audit retrieval is possible after 24 hours

    Examples:
      | confId           |
      | CONF2023TRACE0001|
      | 1290381293989    |

  # API Tests – VPA Status Validation Success and Error Paths
  @api @vpastatus
  Scenario Outline: VPA Status Validation API responds for valid and invalid payerVPA
    Given merchant is active and API keys set
    When I submit VPA Status request with payerVPA "<payerVPA>"
    Then API responds with valStatusCode "<valStatusCode>" and valStatusDesc "<valStatusDesc>"
    And response includes pgMerchantId and payerVPA
    And if payerName available, it is present

    Examples:
      | payerVPA                 | valStatusCode | valStatusDesc        |
      | payee+test001@bank       | VE            | VPA is valid         |
      | nonexistent999@bank      | VN            | VPA not registered   |
      | bad@                     | V             | Request Validation Error |
      | vpaerror@bank            | E             | Exception at UPI     |

  # Boundary API Tests – VPA Field Length Validation
  @api @boundary
  Scenario Outline: VPA Status Validation API boundary test for payerVPA field
    Given merchant is fully onboarded, system connectivity over HTTPS
    When I submit request to VPA Status Validation endpoint with payerVPA length "<length>"
    Then If length equals 255, API returns success as per valid workflow
    And If length equals 256, API fails with Request Validation Error and no VPA lookup

    Examples:
      | length |
      | 255    |
      | 256    |

  # Functional API Tests – Collect Request API Initiation
  @api @collect
  Scenario Outline: Collect Request API (initiate transaction) flow
    Given merchant API session (HTTPS), pre-validated payerVPA
    When I POST collect request with JSON payload:
      """
      {
        "pgMerchantId": "<pgMerchantId>",
        "meOrderNo": "<meOrderNo>",
        "payerVPA": "<payerVPA>",
        "transAmount": "<transAmount>",
        "expiryValue": "<expiryValue>"
      }
      """
    Then API response contains "collStatus":"I", "collStatusDesc":"Transaction Initiated"
    And meOrderNo matches request
    And no error fields present

    Examples:
      | pgMerchantId        | meOrderNo  | payerVPA            | transAmount | expiryValue |
      | HSB000000000001     | ORD1001    | validpayer@bank     | 100.50      | 1440        |
      | HSBB000000000747    | ORD2002    | payee+test001@bank  | 9999.99     | 65000       |

  # Boundary API Tests – Collect Request expiryValue field boundary
  @api @collect @boundary
  Scenario Outline: Collect Request expiryValue boundary validation
    Given merchant API endpoint live
    When I submit collect request with expiryValue "<expiryValue>"
    Then If expiryValue = 64800, request is processed or valid error if another field fails
    And If expiryValue = 64801, request is rejected with validation error

    Examples:
      | expiryValue |
      | 64800       |
      | 64801       |

  # API Tests – Future Use Fields (addInfo1 to addInfo10) Coverage in Collect Request
  @api @collect
  Scenario Outline: Collect Request API with optional addInfo fields (filled, blank, omitted)
    Given merchant and payerVPA are valid
    When I submit collect request with:
      """
      {
        "pgMerchantId": "<pgMerchantId>",
        "payerVPA": "<payerVPA>",
        "addInfo1": "<addInfo1>",
        "addInfo10": "<addInfo10>"
      }
      """
    Then Collect is initiated and API responds normally; no error for addInfo permutations
    And echoed fields match up to 50 characters provided

    Examples:
      | pgMerchantId        | payerVPA            | addInfo1    | addInfo10      |
      | HSB000000000001     | validpayer@bank     | future_1    | future_10      |
      | HSBB000000000747    | payee+test001@bank  |             |                |
      | HSB000000000001     | validpayer@bank     |             |                |

  # API Tests – Transaction Status Enquiry, Lookup Permutations & Boundaries
  @api @status
  Scenario Outline: Transaction Status Enquiry API - success and field permutation
    Given merchant completed transaction and has reference IDs
    When I query transaction status with search parameters:
      """
      {
        "pgMerchantId": "<pgMerchantId>",
        "meRefNo": "<meRefNo>",
        "meOrderNo": "<meOrderNo>",
        "transRRN": "<transRRN>"
      }
      """
    Then API responds with "transStatus":"S", "transMessage":"Payment Successful"
    And IDs in response match query
    When I omit required fields or submit with off-boundary values
    Then request is rejected with error; no status is revealed

    Examples:
      | pgMerchantId        | meRefNo    | meOrderNo | transRRN      |
      | HSB000000000001     | REF1       | ORD1001   | 717215233641  |
      | HSB000000000001     | REF2       |           | 726513237727  |
      | HSBB000000000747    |            | ORD2002   |               |
      | HSBB000000000747    | REF3       | ORD2003   | 123456789012  |

  Scenario Outline: Boundary Test for transRRN Field Length
    Given merchant authenticates to API
    When I submit status enquiry with transRRN "<transRRN>"
    Then If transRRN is 12 digits, API returns transaction status
    And If transRRN is 11 or 13 digits, API rejects request; no transaction status provided

    Examples:
      | transRRN      |
      | 717215233641  | # 12 digits
      | 12345678901   | # 11 digits
      | 1234567890123 | # 13 digits

  # API Functional, Negative, and Boundary Tests – Refund API
  @api @refund
  Scenario Outline: Refund API workflow for success, failure, and boundary amounts
    Given merchant and original transaction exist
    When I POST refund request to /meRefund API with:
      """
      {
        "pgMerchantId": "<pgMerchantId>",
        "newMeOrderNo": "<newMeOrderNo>",
        "orgTransId": "<orgTransId>",
        "orgTransRRN": "<orgTransRRN>",
        "refundAmount": "<refundAmount>",
        "payerVPA": "<payerVPA>"
      }
      """
    Then If all fields valid and refundAmount in allowed range, API returns "refundStatus":"S", "refundMessage":"Success" and audit log is created
    And If orgTransId invalid, duplicate refund, or refundAmount outside permitted boundaries, API replies "refundStatus":"F"/"E" and refundMessage explains failure
    And If refundAmount is at min/max allowed, API responds as per boundary rules

    Examples:
      | pgMerchantId        | newMeOrderNo   | orgTransId                     | orgTransRRN   | refundAmount        | payerVPA            |
      | HSBB000000000747    | 15060585311439 | HSB59C1346D0B63...             | 726513237727  | 1.35                | testupiuser@testbank|
      | HSBB000000000747    | 15060585311440 | INVALIDTRANSID                 | 726513237728  | 500.00              | badupi@bank         |
      | HSBB000000000747    | 15060585311441 | HSB59C1346D0B63...             | 726513237729  | 0                   | testupiuser@testbank|
      | HSBB000000000747    | 15060585311442 | HSB59C1346D0B63...             | 726513237730  | 999999999999.99     | testupiuser@testbank|
      | HSBB000000000747    | 15060585311443 | HSB59C1346D0B63...             | 726513237731  | 1000000000000.00    | testupiuser@testbank|
      | HSBB000000000747    | 15060585311444 | HSB59C1346D0B63...             | 726513237732  | 10.002              | testupiuser@testbank|
      | HSBB000000000747    | 15060585311445 | HSB59C1346D0B63...             | 726513237733  | 1234567890123.45    | testupiuser@testbank|

  # API/SDK Functional Tests – Encryption Toolkits (Java, .NET, PHP) and Security Key Handling
  @api @sdk
  Scenario Outline: .NET Encryption Toolkit File Reference and Build Correctness
    Given a valid .NET development environment and UPIKit.dll present locally
    When I add UPIKit.dll to project references and write code to call UPISecurity.Encrypt with input "<input>" and key "<key>"
    Then Build succeeds with no reference or build errors
    And UPISecurity encryption methods are available in code
    And encryption routine executes as expected

    Examples:
      | input                 | key             |
      | SensitiveMsg          | TestKey1!       |
      | TestPayload           | HSBCKey123!     |

  @api @sdk
  Scenario Outline: Java Encryption Routine Correctness
    Given Java SDK and UPI Java toolkit JAR file present
    When I call UPISecurity.encrypt with "<msg>", "<key>", then decrypt result with same key
    Then encrypted output not equal to plaintext
    And decrypted result matches original message
    And decrypting with wrong key fails or throws error

    Examples:
      | msg                          | key               |
      | Test message to encrypt!     | aValidTestKey123! |
      | SensitivePayload             | HSBCKeySecret!    |

  @api @sdk
  Scenario Outline: PHP Encryption Toolkit renaming and usability
    Given UPI_Merchant_Tool_Kit_PHP.zip1 downloaded
    When I rename file to .zip and extract contents
    Then extraction produces toolkit PHP files
    And PHP interpreter can open and include toolkit files for integration

    Examples:
      | zip1filename                  | zipfilename                     |
      | UPI_Merchant_Tool_Kit_PHP.zip1| UPI_Merchant_Tool_Kit_PHP.zip   |

  @api @security
  Scenario Outline: Encryption key boundary and error handling routine
    Given encryption toolkit is correctly referenced (.NET, Java, PHP)
    When I encrypt payload "<payload>" with valid key "<key>"
    Then I decrypt with invalid key "<wrongKey>", operation fails/error or gibberish result
    When I encrypt or decrypt with missing/empty key
    Then toolkit throws error and never leaks plaintext in any error/log

    Examples:
      | payload              | key                 | wrongKey         |
      | TestSensitivePayload | ValidKeyFromBank123 | WrongKey!        |
      | EncData123           | HSBCKeySecret!      |                 |

  # Certificate & Security Tests – CSR Generation, Storage & Access
  @security @certificate
  Scenario Outline: Merchant CSR Generation via keytool command
    Given merchant server with Java keytool and keystore file "<keystore>"
    When I generate CSR file "<csrfile>" using keytool command
    Then System prompts for password and all CSR fields
    And CSR file is PEM-encoded, >0 bytes, no password/private key exposed, ready for HSBC certificate issuance

    Examples:
      | keystore               | csrfile               |
      | 2_WAY_SSL_Cert.jks     | 2_WAY_SSL_CSR.csr     |
      | merchantCertStore.jks  | merchantCSR.csr       |

  @security @certificate
  Scenario Outline: Certificate and key secure storage validation
    Given certificate file "<certfile>" and private key stored on merchant server
    When I check file permissions as admin and non-admin users
    Then Only admin users have read/write access; non-admins receive 'permission denied'
    And audit logs reflect access attempts; no sensitive file is world-readable

    Examples:
      | certfile               |
      | 2_WAY_SSL_Cert.jks     |
      | merchantSSL.key        |

  # Network Security & Resilience Tests – IP Whitelisting & Blocked Endpoint Handling
  @security @network
  Scenario Outline: IP whitelisting for callback response
    Given merchant Response API endpoint "<responseEndpoint>" with static IP "<staticIP>"
    When IP and endpoint are submitted to HSBC for whitelisting
    Then callback requests from HSBC-origin IPs are accepted and processed
    When connection attempt is made from unwhitelisted IP
    Then request is rejected, not processed; audit logs show blocked attempt

    Examples:
      | responseEndpoint                | staticIP          |
      | https://merchant.com/callback   | 203.171.209.5     |
      | https://acme.com/api/notify     | 203.171.222.7     |

  @resilience @network
  Scenario Outline: Network failure handling when callback endpoints/IPs blocked
    Given Response API endpoints are deployed and all HSBC callback IPs are initially allowed
    When I block all HSBC callback IPs "<blockedIPs>" via firewall
    And HSBC attempts callback notification
    Then connection is refused/times out, no data delivered, no leakage occurs
    And system logs reflect failure and alert admin/operator as implemented
    When block is removed, callback delivery restores as expected

    Examples:
      | blockedIPs                   |
      | 203.171.209.5,203.171.222.7  |

  # API Negative Validation – Blank Field and Format Checks Across APIs
  @api @negative
  Scenario Outline: API mandatory field blank/invalid format negative path
    Given API credentials and test endpoints live for Dynamic VPA Validation, Collect, Status, Refund APIs
    When I submit API requests with blank or malformatted mandatory fields "<fieldName>", value "<value>", endpoint "<endpoint>"
    Then API returns documented schema error (e.g., "Character Mandatory", "Mandatory" or format error)
    And no downstream processing or state change
    And audit logs reflect rejection cause

    Examples:
      | fieldName     | value           | endpoint                 |
      | subscriberId  |                 | /api/vpa/validate        |
      | refNo         |                 | /api/precredit/validate  |
      | transID       |                 | /api/precredit/validate  |
      | refundAmount  | abc             | /meRefund                |
      | payerVPA      | 12345           | /api/vpastatus           |

  # Audit Logging Coverage – Post Credit / Final Response-Notification
  @audit @postcredit
  Scenario Outline: Audit log entry creation and immutability for Post Credit / Notification
    Given merchant notification API receives HSBC post event with refNo "<refNo>", transRRN "<transRRN>", and generates confId "<confId>"
    When merchant sends API response to HSBC including confId
    Then Audit log entry is persisted with all fields: refNo, transRRN, transStatus, transMessage, confId, pgMerchantId, etc.
    And log entry is provably immutable and retrievable by refNo/transRRN
    And for failed postings, audit log reflects failure outcome

    Examples:
      | refNo   | transRRN      | confId           |
      | 2394829 | 717215233641  | 1290381293989    |
      | 2394851 | 726513237727  | CONF2023TRACE0001|
