Feature: HSBC UPI Merchant API Onboarding and Integration End-to-End Test Suite

  # Background: Set up test context for API testing (common for most tests)
  Background:
    Given the merchant has valid HSBC integration credentials
    And the API base URL is configured for UAT or production as per scenario
    And valid merchant encryption key and certificate are provisioned
    And API requests are submitted over HTTPS with SSL/TLS
    And the merchant integration kit is installed in the test environment

  # Merchant Setup and API Hosting Verification
  @api @onboarding
  Scenario Outline: Verify merchant API endpoint hosting and HSBC API consumption
    Given the merchant has deployed API server at static public IP '<merchant_ip>'
    And the merchant endpoint '/upi/onboard/test' is live and reachable
    When HSBC sends a test POST request with payload
      """
      { "testField": "HSBC onboarding message" }
      """
      to merchant endpoint
    Then the merchant endpoint responds with HTTP <merchant_status>
    And the merchant logs record request with timestamp
    When the merchant sends a POST request to HSBC onboarding sample endpoint with payload
      """
      { "merchantField": "Sample payload as per HSBC" }
      """
    Then HSBC sample endpoint returns HTTP <hsbc_status>
    And the merchant server logs record outbound request/response with timestamps
    And both APIs return no errors or connectivity failures

    Examples:
      | merchant_ip       | merchant_status | hsbc_status |
      | 203.171.209.5     | 200             | 200         |
      | 203.171.222.6     | 200             | 200         |

  # Merchant ID Generation and Assignment
  @ui @api
  Scenario Outline: Merchant onboarding and unique Merchant ID generation flow
    Given the operator logs into HSBC UPI onboarding portal
    When the operator submits merchant onboarding info and uploads compliance docs
    And the application is reviewed and approved
    Then system displays generated Merchant ID '<pgMerchantID>' and status '<status>'
    And Merchant ID appears in portal's active merchant list
    When API request is initiated using Merchant ID to endpoint '/api/merchant/validate'
    Then API accepts Merchant ID '<pgMerchantID>' and returns HTTP <api_status>
    And audit log contains entry for Merchant ID creation

    Examples:
      | pgMerchantID          | status  | api_status |
      | HSB000000001234       | ACTIVE  | 200        |

  # Encryption Key Provisioning and Validation
  @security @api
  Scenario Outline: Validate issuing, retrieval, and usage of merchant encryption key
    Given HSBC operator generates and uploads unique encryption key
    When the merchant logs in and retrieves encryption key '<EncKey>'
    Then the key format matches hex and is not shown in plaintext in UI or email
    When the merchant uses encryption key to encrypt sample payload
      """
      { "test": "sample" }
      """
    And sends encrypted payload to HSBC API endpoint
    Then HSBC API returns HTTP <response_status> and accepts payload
    And key never appears in plaintext in logs

    Examples:
      | EncKey                             | response_status |
      | A1B2C3D4E5F6A7B8C9D0A1B2C3D4E5F6   | 200            |

  # Merchant Integration Kit Installation and Operation
  @audit @api
  Scenario Outline: Merchant verifies and installs Integration Kit for encrypt/decrypt/verify
    Given the merchant downloads Integration Kit for platform '<platform>' (.NET/Java/PHP/Python)
    When the toolkit is installed and imported in application
    And the merchant executes Encrypt(), Decrypt(), and Verify sample functions with masked data and keys
    Then encrypted and decrypted values match input/output, and all required functions compile and execute without errors
    And audit log records successful toolkit installation and usage
    And no sensitive key material appears in logs

    Examples:
      | platform |
      | .NET     |
      | Java     |
      | PHP      |
      | Python   |

  # HTTPS (SSL) Validation for API Integration
  @security
  Scenario Outline: Verify merchant connects to HSBC exclusively over HTTPS with valid SSL certificate
    Given merchant SSL certificate is installed and HTTPS server is running
    When merchant attempts API connection to HSBC endpoint via HTTPS
    Then SSL handshake is completed with no errors and certificate exchange meets RSA 2048
    When merchant attempts HTTP (non-SSL) connection to HSBC endpoint
    Then connection is rejected or fails
    And no sensitive data is transmitted in plaintext

    Examples:
      | certificate_type      | protocol | expected_result   |
      | RSA2048              | HTTPS    | handshake success |
      | RSA2048              | HTTP     | rejected          |

  # Dynamic VPA Validation Success and Failure
  @api
  Scenario Outline: Dynamic VPA Validation API positive and negative scenarios
    Given merchant prepares payload with subscriberId '<subscriberId>' and source '<source>'
    When merchant submits POST request to Dynamic VPA Validation API endpoint '/api/vpa/validate'
      """
      {
        "subscriberId": "<subscriberId>",
        "source": "<source>",
        "Rmn": "<Rmn>"
      }
      """
    Then API returns status <status_code>
    And response contains 'transStatus' '<transStatus>'
    And response field 'transMessage' is '<transMessage>'
    And 'accountDetails' array is <accountDetails>

    Examples:
      | subscriberId        | source | Rmn    | status_code | transStatus | transMessage                                          | accountDetails                                                         |
      | VZNADT012310002     | SCB    |        | 200         | Success     |                                                      | [ { "subscriberId":"VZNADT012310002", "accountStatus":"Success" } ]    |
      | vznadt012310003     | SCB    |        | 200         | Failure     | Record not available for this Loan/Proposal No : vznadt012310003 | []                                                               |

  # Mandatory Fields Validation for Dynamic VPA API
  @boundary @api
  Scenario Outline: Validate enforcement of mandatory subscriberId and source fields (min/max/out-of-bounds)
    Given merchant prepares test payload for Dynamic VPA Validation
    When merchant submits request with subscriberId '<subscriberId>' and source '<source>'
    Then API responds with status '<status_code>' and error message '<error_msg>'

    Examples:
      | subscriberId          | source | status_code | error_msg                                  |
      |                      | SCB    | 400         | subscriberId missing                        |
      | VZNADT012310002      |        | 400         | source missing                              |
      |                      |        | 400         | subscriberId and source missing             |
      | a                    | SCB    | 200         |                                            |
      | VZNADT012310002      | S      | 200         |                                            |
      | <256char>            | SCB    | 400         | subscriberId too long                       |
      | VZNADT012310002      | <dummy>| 400         | source invalid                              |

  # Optional Field Handling: Rmn
  @boundary @api
  Scenario Outline: Dynamic VPA Validation API optional Rmn field handling
    Given merchant submits Dynamic VPA Validation request with 'Rmn' field '<Rmn>'
    When API processes the request
    Then response is success with no validation error
    And API response for Rmn inclusion/exclusion matches baseline response

    Examples:
      | Rmn     |
      | 1234    |
      |         |
      | <50char>|

  # Return of AccountDetails on Success
  @api
  Scenario Outline: Account details are returned on successful dynamic VPA validation
    Given merchant submits valid subscriberId '<subscriberId>' and source '<source>'
    When request is processed
    Then response includes accountDetails array with subscriberId, accountStatus 'Success' and subscriberName '<subscriberName>' (masked/synthetic)

    Examples:
      | subscriberId        | source | subscriberName              |
      | VZNADT012310002     | SCB    | PARASURAM KUMAR A           |
      | VZNADT012310002     | SCB    | MASKED_SAMPLE_NAME          |

  # Pre-Credit VPA Validation Full Parameter Coverage
  @api
  Scenario Outline: Pre-Credit VPA Validation request with all mandatory & optional fields
    Given merchant submits full request with all specified fields and valid encrypted payload
    When API processes request
    Then response includes all fields as supplied, with correct values and types
    And transStatus is 'S' and transMessage is 'Success'
    And no validation or schema errors are present

    Examples:
      | refNo           | payerId      | transAmount        | payerName     | source | addInfo1         | pgMerchantId         |
      | 1283712         | testpayer123 | 1050.25           | Test Name     | HSBC   | Additional1      | HSB000000000001      |

  # Pre-Credit VPA Validation Success and Failure Responses
  @api
  Scenario Outline: Validation of Pre-Credit VPA API success and failure scenarios
    Given merchant submits Pre-Credit VPA Validation request with refNo '<refNo>' and payerId '<payerId>'
    When request is processed
    Then response contains transStatus '<transStatus>' and transMessage '<transMessage>'
    And pgMerchantId matches request or spec
    And addInfo fields appear as sent

    Examples:
      | refNo       | payerId        | transStatus | transMessage         |
      | 12837       | 9820982020     | S           | Success             |
      | 44556688    | invaliduser123 | F           | Invalid VPA         |

  # Duplicate Transaction Detection via refNo (Pre-Credit Validation)
  @api @state-transition
  Scenario Outline: Detect and reject duplicate Pre-Credit VPA Validation request by refNo
    Given merchant submits first Pre-Credit VPA Validation with refNo '<refNo>'
    When API processes request
    Then response is transStatus '<first_status>'
    When merchant submits second Pre-Credit VPA Validation with same refNo
    Then API rejects with error or duplication indication and transStatus '<second_status>'

    Examples:
      | refNo       | first_status | second_status |
      | 11223344    | S            | F             |

  # Boundary Value Analysis of Pre-Credit API Field Lengths
  @boundary @api
  Scenario Outline: Field length boundary testing for Pre-Credit VPA Validation API
    Given merchant submits request with '<field>' at length '<length_value>' 
    When API validates request
    Then response is <status>
    And error message is '<error_msg>' if out of bounds

    Examples:
      | field      | length_value | status | error_msg                      |
      | refNo      | 6            | 200    |                               |
      | refNo      | 16           | 200    |                               |
      | refNo      | 5            | 400    | Too short                      |
      | refNo      | 17           | 400    | Too long                       |
      | payerId    | 6            | 200    |                               |
      | payerId    | 250          | 200    |                               |
      | payerId    | 251          | 400    | Too long                       |
      | addInfo1   | 50           | 200    |                               |
      | addInfo1   | 51           | 400    | Too long                       |

  # Optional addInfo1-10 Field Handling Pre-Credit API
  @boundary @api
  Scenario Outline: Handling of addInfo fields (optional, empty, max-length, boundary enforcement)
    Given merchant submits request with addInfo fields '<addInfo_field>' at length '<addInfo_length>'
    When API processes request
    Then response echoes addInfo field as sent if valid
    And rejects with error if length exceeds 50

    Examples:
      | addInfo_field | addInfo_length |
      | addInfo1      | 50             |
      | addInfo10     | 0              |
      | addInfo5      | 51             |

  # Post Credit Notification Callback API Invocation
  @api
  Scenario Outline: HSBC invokes merchant Final Response-Notification API via callback
    Given merchant exposed Final Response-Notification API at '<callback_url>' with whitelisted IP '<merchant_ip>'
    When HSBC posts to merchant endpoint after credit posting
    Then merchant logs receipt with timestamp and all documented fields
    And logs confirm only single callback for transaction ID '<transId>'
    And originating IP/cert matches HSBC record

    Examples:
      | callback_url                                  | merchant_ip        | transId        |
      | https://merchant-callback.example.com/upicallback | 203.171.209.5     | T1234567       |

  # Post Credit API Response Parameter Boundary Handling
  @boundary @api
  Scenario Outline: Validate mandatory response parameter constraints in Final Response-Notification
    Given merchant responds to HSBC callback with confStatus '<confStatus>' and confMessage '<confMessage>' and other mandatory fields
    When response is sent
    Then HSBC accepts response only if all mandatory fields are valid (length/type)
    And explicit error is returned for boundary violations

    Examples:
      | confStatus | confMessage                                |
      | S          | Success                                    |
      |            |                                            |
      | SS         |                                            |
      | S          | <100char>                                  |
      | S          | <101char>                                  |

  # Confirmation ID Presence in Response
  @api
  Scenario Outline: Confirm merchant responds with unique confId to HSBC callback
    Given merchant generates unique confId '<confId>' for transaction '<transId>'
    When response is sent to HSBC
    Then HSBC records confId linking to posted transaction
    And duplicate or missing confId is rejected

    Examples:
      | confId         | transId    |
      | CONF12345678   | T890123    |
      |                | T890123    |

  # Failure Handling in Post Credit Notification
  @api @negative
  Scenario Outline: Merchant endpoint processes failed transaction status correctly
    Given merchant receives callback with transStatus '<transStatus>' and transMessage '<transMessage>'
    When response is processed
    Then merchant logs failure details and does not process further posting

    Examples:
      | transStatus | transMessage        |
      | F           | Transaction Failed  |
      | F           | Payment Declined    |

  # Post Credit Callback addInfo1-10 (Boundary testing)
  @boundary @api
  Scenario Outline: Validate handling of future use addInfo fields in callback API responses
    Given merchant fills addInfo fields in response at boundary values as specified
    When HSBC API processes response
    Then all addInfo fields echo without error if within 0-50 chars
    And addInfo11 is ignored or triggers validation error

    Examples:
      | addInfo_field | addInfo_length |
      | addInfo1      | 0              |
      | addInfo2      | 1              |
      | addInfo3      | 50             |
      | addInfo11     | 1              |

  # Duplicate Callback Rejection via refNo (Final Response-Notification)
  @state-transition @api
  Scenario Outline: Ensure duplicate Post Credit API callbacks by refNo are rejected
    Given merchant submits first response to HSBC callback with refNo '<refNo>'
    When HSBC processes response
    Then response is accepted as normal
    When merchant submits second response with same refNo
    Then HSBC rejects with duplication error

    Examples:
      | refNo     |
      | 2394829   |

  # Valid VPA Status Return (VE)
  @api
  Scenario Outline: VPA Status Validation API returns valStatusCode 'VE' for valid VPA
    Given merchant submits VPA Status Validation for payerVPA '<payerVPA>' and pgMerchantID '<pgMerchantID>' and meRefNo '<meRefNo>'
    When request is processed
    Then API responds with valStatusCode 'VE', valStatusDesc 'VPA is valid', and payerName populated

    Examples:
      | payerVPA        | pgMerchantID           | meRefNo    |
      | aditya@hsbc     | HSBB000000000001       | 450824145  |

  # VPA Non-Existent Status (VN)
  @api @negative
  Scenario Outline: VPA Status Validation API returns 'VN' for non-existent VPA
    Given merchant submits VPA Status Validation for payerVPA '<payerVPA>' and pgMerchantID '<pgMerchantID>' and meRefNo '<meRefNo>'
    When request is processed
    Then API responds with valStatusCode 'VN' and valStatusDesc indicates VPA not available
    And payerName is not populated

    Examples:
      | payerVPA              | pgMerchantID           | meRefNo     |
      | nouser9999@nocci      | HSBB000000000001       | 450824146   |

  # VPA Validation Error and Exception Handling
  @api @negative
  Scenario Outline: VPA Status Validation API error handling for invalid fields and UPI exception
    Given merchant submits status validation with invalid meRefNo '<meRefNo>' or payerVPA '<payerVPA>'
    When request is processed
    Then response contains valStatusCode '<valStatusCode>' and descriptive valStatusDesc
    And payerName is not present

    Examples:
      | meRefNo   | payerVPA           | valStatusCode |
      | 123       | aditya@hsbc        | V             |
      | 450824147 | ##@badformat       | V             |
      | 450824148 | aditya@hsbc        | E             |

  # Boundary Value Check for meRefNo and payerVPA
  @boundary @api
  Scenario Outline: Validate meRefNo (6-30 chars) & payerVPA (≤255) length boundaries
    Given merchant submits VPA Status Validation with meRefNo '<meRefNo>' and payerVPA '<payerVPA>'
    When API processes request
    Then response is <status>
    And valStatusCode is '<valStatusCode>' for errors

    Examples:
      | meRefNo                             | payerVPA    | status | valStatusCode |
      | abcdef                              | user@bank   | 200    | VE            |
      | 123456789012345678901234567890      | user@bank   | 200    | VE            |
      | abcde                               | user@bank   | 400    | V             |
      | 1234567890123456789012345678901     | user@bank   | 400    | V             |
      | testref                             | <255char>   | 200    | VE            |
      | testref                             | <256char>   | 400    | V             |

  # Conditional Payer Name Population
  @boundary @api
  Scenario Outline: VPA Status Validation API returns payerName only for valid VPAs
    Given merchant submits VPA Status Validation API request for payerVPA '<payerVPA>'
    When API processes request
    Then payerName is returned and length matches '<payerName_length>' only if VPA is valid

    Examples:
      | payerVPA            | payerName_length |
      | user100@bank        | 100              |
      | shortname@bank      | 20               |
      | nouser@bank         | 0                |

  # Collect Request Initiation and Response Verification
  @api
  Scenario Outline: Collect Request API end-to-end test (initiation and response params)
    Given merchant website triggers collect API request with params: pgMerchantID '<pgMerchantID>', meOrderNo '<meOrderNo>', transAmount '<transAmount>', payerVPA '<payerVPA>', transRemarks '<transRemarks>', expiryValue <expiryValue>
    When API request is encrypted and submitted to HSBC endpoint
    Then response contains collStatus '<collStatus>', collStatusDesc '<collStatusDesc>', and all required fields
    And audit/logs confirm transaction initiation

    Examples:
      | pgMerchantID           | meOrderNo      | transAmount | payerVPA        | transRemarks           | expiryValue | collStatus | collStatusDesc         |
      | HSB0000000000001       | 234982349234   | 50.00       | aditya@icici    | Collect from aditya    | 1110        | I         | Transaction Initiated  |

  # Collect Request Failure Handling and Error Scenarios
  @api @negative
  Scenario Outline: Collect Request API failed status and error message handling
    Given merchant submits collect request with invalid payerVPA '<payerVPA>' or invalid transAmount '<transAmount>'
    When API processes request
    Then API response has collStatus '<collStatus>' and collStatusDesc explaining failure or exception

    Examples:
      | payerVPA          | transAmount | collStatus | collStatusDesc        |
      | bad@none          | 50.00       | F          | Failure due to invalid payerVPA |
      | aditya@icici      | -5.00       | E          | Exception at UPI               |

  # Expiry Value Boundary Testing for Collect Request
  @boundary @api
  Scenario Outline: Boundary value checks for expiryValue in Collect API
    Given merchant submits Collect Request with expiryValue '<expiryValue>'
    When API processes request
    Then response is <status> with collStatus '<collStatus>' and collStatusDesc '<collStatusDesc>'

    Examples:
      | expiryValue | status | collStatus | collStatusDesc          |
      | 1           | 200    | I          | Transaction Initiated   |
      | 64800       | 200    | I          | Transaction Initiated   |
      | 64801       | 400    | F          | expiryValue exceeds max |

  # Collect Request AddInfo1-10 Boundary Testing
  @boundary @api
  Scenario Outline: Verify addInfo fields handling in Collect API (0-50 chars)
    Given merchant submits Collect Request with addInfo fields at length '<addInfo_length>'
    When API processes request
    Then response is <status> and addInfo field echoes if valid, error if overlong

    Examples:
      | addInfo_length | status |
      | 0              | 200    |
      | 50             | 200    |
      | 51             | 400    |

  # Minimal Input Collect Request (Mandatory fields only)
  @boundary @api
  Scenario Outline: Collect Request API accepts minimal mandatory fields, optional omitted
    Given merchant submits Collect Request with only mandatory fields
    When API processes request
    Then response is collStatus 'I' (Initiated) and no errors/warnings about missing optional fields

    Examples:
      | pgMerchantID           | meOrderNo        | transAmount | payerVPA    | transRemarks   | expiryValue |
      | HSB0000000000001       | 987654321        | 50.00       | aditya@icici| Pay Now        | 1110        |

  # Transaction Status Enquiry API Success and Status Variations
  @api
  Scenario Outline: Transaction Status Enquiry API returns correct status and message per transaction
    Given merchant submits Transaction Status Enquiry request with meOrderNo '<meOrderNo>' and transRRN '<transRRN>'
    When API processes request
    Then response includes transStatus '<transStatus>' and transMessage '<transMessage>'
    And all mandatory fields are present

    Examples:
      | meOrderNo     | transRRN      | transStatus | transMessage           |
      | 12345678      | 9876543210    | S           | Payment Successful     |
      | 22345678      | 1234567890    | P           | Pending for Approval   |
      | 32345678      | 2234567890    | F           | Payment Failed         |
      | 42345678      | 3234567890    | R           | Payment Rejected       |
      | 52345678      | 4234567890    | X           | Transaction Expired    |
      | 62345678      | 5234567890    | E           | Exception at UPI      |

  # Reference Linking via meOrderNo and meRefNo (Boundary checks)
  @boundary @api
  Scenario Outline: Transaction Status Enquiry link/reference boundary validation
    Given merchant submits enquiry with reference '<reference_type>' value '<reference_value>'
    When API processes request
    Then response is <status>
    And error message returned for boundary violation if applicable

    Examples:
      | reference_type | reference_value                       | status | error_msg         |
      | meOrderNo      | 123456                                | 200    |                  |
      | meOrderNo      | 123456789012345678901234567890        | 200    |                  |
      | meOrderNo      | 12345                                 | 400    | Too short         |
      | meOrderNo      | 1234567890123456789012345678901       | 400    | Too long          |
      | meRefNo        | 654321                                | 200    |                  |
      | meRefNo        | 654321987654321098765432109876543210  | 400    | Too long          |

  # Optional addInfo1-10 Response Field Handling Status Enquiry API
  @boundary @api
  Scenario Outline: Transaction Status Enquiry API successfully handles addInfo fields (populated/omitted/overlong)
    Given merchant submits enquiry for transaction with addInfo fields '<addInfo_field>' at length '<addInfo_length>'
    When API processes request
    Then response is <status> and addInfo field echoed if valid, rejected if over max

    Examples:
      | addInfo_field | addInfo_length | status |
      | addInfo1      | 50             | 200    |
      | addInfo10     | 0              | 200    |
      | addInfo5      | 51             | 400    |

  # Enquiry Failure Case – Exception/Error Status
  @api @negative
  Scenario Outline: Transaction Status Enquiry returns 'E' and error message for UPI backend exception
    Given merchant submits enquiry for transaction with known UPI exception
    When API processes request
    Then response includes transStatus 'E' and transMessage with 'Exception at UPI'
    And no sensitive info is leaked in error

    Examples:
      | meOrderNo     | transRRN    |
      | EXC10001      | 1234567890  |

  # Successful Refund Entire Flow - Original Transaction Linkage
  @api
  Scenario Outline: Refund API processes full refund workflow with original transaction linkage
    Given merchant submits refund request with pgMerchantID '<pgMerchantID>', newMeOrderNo '<newMeOrderNo>', orgMeOrderNo '<orgMeOrderNo>', orgTransRRN '<orgTransRRN>', refundAmount '<refundAmount>', addInfo1-10
    When refund API processes request
    Then response includes refundStatus 'S', refundMessage 'Success', and links newMeOrderNo to original transaction
    And refundAmount matches input

    Examples:
      | pgMerchantID           | newMeOrderNo | orgMeOrderNo | orgTransRRN   | refundAmount      |
      | HSBB000000000747       | 2309482      | 1298371      | 287136482     | 100.00           |

  # Refund Failure/Error Handling
  @api @negative
  Scenario Outline: Refund API returns failure status and descriptive message for invalid refund attempts
    Given merchant submits refund request with invalid values
    When API processes request
    Then response includes refundStatus '<refundStatus>' and refundMessage '<refundMessage>'
    And no transaction is wrongly reversed

    Examples:
      | refundStatus | refundMessage               |
      | F            | Failure due to invalid orgMeOrderNo |
      | F            | Failure due to exceeding refundAmount |
      | E            | Exception at UPI                      |

  # Partial Refund Amount Testing (Boundary)
  @boundary @api
  Scenario Outline: Refund API refundAmount boundary value tests
    Given merchant submits refund request with refundAmount '<refundAmount>'
    When API processes request
    Then response is <status> and refundStatus '<refundStatus>' with refundMessage '<refundMessage>'

    Examples:
      | refundAmount             | status | refundStatus | refundMessage        |
      | 1.00                    | 200    | S           | Success             |
      | 1000000000000000.00     | 200    | S           | Success             |
      | 0.99                    | 400    | F           | refundAmount below minimum |
      | 10000000000000000.00    | 400    | F           | refundAmount above maximum |

  # Refund API addInfo1-10 Boundary Testing
  @boundary @api
  Scenario Outline: Refund API addInfo field boundary enforcement
    Given merchant submits refund request with addInfo fields '<addInfo_field>' at length '<addInfo_length>'
    When API processes request
    Then response is <status> and addInfo field echoed if valid, rejected if over 50 chars

    Examples:
      | addInfo_field | addInfo_length | status |
      | addInfo1      | 50             | 200    |
      | addInfo10     | 0              | 200    |
      | addInfo5      | 51             | 400    |

  # Refund API - Mandatory pgMerchantID Enforcement
  @boundary @api
  Scenario Outline: Refund API strictly validates presence and value of pgMerchantID
    Given merchant submits refund request with pgMerchantID '<pgMerchantID>'
    When API processes request
    Then response is <status> with refundStatus '<refundStatus>' and refundMessage '<refundMessage>'

    Examples:
      | pgMerchantID           | status | refundStatus | refundMessage        |
      | HSBB000000000747       | 200    | S           | Success             |
      |                       | 400    | F           | pgMerchantID missing|
      | INVALID1234567890     | 400    | F           | pgMerchantID invalid|

  # Duplicate Refund Prevention via orgMeOrderNo (State transition)
  @api @state-transition
  Scenario Outline: Validate Refund API rejects duplicate refund for same orgMeOrderNo
    Given merchant submits first refund request for orgMeOrderNo '<orgMeOrderNo>'
    When API processes request
    Then response is refundStatus 'S' and refundMessage 'Success'
    When merchant submits second refund with same orgMeOrderNo
    Then response is refundStatus 'F' and refundMessage indicates duplicate/refund already processed

    Examples:
      | orgMeOrderNo    |
      | DUPREF12345     |

  # Encryption Toolkit Installation (.NET/PHP/Java/Python)
  @audit
  Scenario Outline: Merchant installs HSBC UPI Encryption/Decryption toolkit
    Given admin extracts toolkit files for platform '<platform>'
    When files are renamed and imported in application project
    Then toolkit reference is confirmed available for encryption operations

    Examples:
      | platform |
      | .NET     |
      | Java     |
      | PHP      |
      | Python   |

  # Data Encryption and Decryption Using Toolkit
  @api @security
  Scenario Outline: Encrypt and decrypt data using merchant encryption toolkit
    Given toolkit is installed and merchant key '<key>' is available
    When invoking UPISecurity.encrypt with sample message
    Then output is encrypted and matches hex/base64 format
    When invoking UPISecurity.decrypt with encrypted message and key
    Then output exactly matches original plaintext

    Examples:
      | key                            | sample_message                  | encrypted_format |
      | ABC123456789DEFFEDCBA9876543210| {"pgMerchantID":"HSBC000000695"}| hex             |

  # Integration Verification of Toolkit Reference Addition
  @audit
  Scenario Outline: Add toolkit DLL/JAR reference to project (.NET or Java)
    Given developer adds UPIKit.dll or UPIKit.jar to project references
    When reference addition is validated
    Then code can invoke toolkit methods without import errors
    And audit log records reference addition

    Examples:
      | platform   | reference_file  |
      | .NET       | UPIKit.dll      |
      | Java       | UPIKit.jar      |

  # Invalid Key Handling in Encryption Toolkit
  @api @security @negative
  Scenario Outline: Toolkit rejects decryption attempt with incorrect key
    Given toolkit is installed and sample encrypted message is available
    When invoking UPISecurity.decrypt with invalid key
    Then decryption fails with error, no plaintext data is returned
    And error event is recorded in logs

    Examples:
      | encrypted_message   | invalid_key                  |
      | MASKED_CIPHER       | BAD1234567890XXXXXXXX        |

  # Request Message Encryption Using Merchant Key
  @security
  Scenario Outline: API request is accepted only if encrypted with merchant key
    Given merchant key 'MASKED_KEY' is available
    When merchant submits API requestMsg encrypted with key to HSBC
    Then API accepts encrypted message, rejects plaintext

    Examples:
      | requestMsg               | pgMerchantId             |
      | MASKED_ENCRYPTED_STRING  | HSBC000000000695         |
      | PLAIN_MESSAGE            | HSBC000000000695         |

  # Encrypted Request Parameter Verification (Refund API)
  @security
  Scenario Outline: API only accepts refund requests with valid encryption; rejects plaintext/wrong-key
    Given merchant prepares refund API request encrypted with merchant key '<key>'
    When request is submitted to HSBC endpoint
    Then API accepts valid encrypted requests, rejects plaintext and wrong-key encryption

    Examples:
      | key                    | requestMsg                 | scenario         |
      | MASKED_KEY             | MASKED_ENCRYPTED_STRING    | valid encryption |
      | BAD_KEY                | MASKED_ENCRYPTED_STRING    | wrong-key        |
      | MASKED_KEY             | PLAIN_MESSAGE              | plaintext        |

  # Decryption of Response Message Using Key
  @security
  Scenario Outline: Merchant decrypts HSBC API response using issued key
    Given merchant receives encrypted API response '<response>'
    When decrypting with merchant key '<key>'
    Then decrypted response contains valid transaction/refund fields
    When decrypting with invalid key '<wrong_key>'
    Then output is unreadable or error as per toolkit

    Examples:
      | response               | key                        | wrong_key                    |
      | MASKED_ENCRYPTED_STRING| ABC123456789DEFFEDCBA98765 | BAD1234567890XXXXXXXX        |

  # Plaintext Rejection Enforcement by API
  @security @api
  Scenario Outline: HSBC APIs reject any plaintext submissions, only encrypted requests are processed
    Given merchant submits API request as plaintext (unencrypted) for '<api_endpoint>'
    When API processes request
    Then API rejects with documented error response
    When encrypted request is submitted for same endpoint
    Then API processes normally with valid response

    Examples:
      | api_endpoint        |
      | /api/payment        |
      | /api/refund         |
      | /api/status         |

  # Encryption Key Rotation and Revocation
  @resilience
  Scenario Outline: Merchant rotates encryption key; only new key is usable for API requests
    Given merchant submits request encrypted with old key '<old_key>'
    When API processes request
    Then API rejects with invalid key error
    When merchant submits request with new rotated key '<new_key>'
    Then API processes successfully and response can be decrypted only with valid key

    Examples:
      | old_key         | new_key                |
      | OLDKEY123456789 | NEWKEY987654321        |

  # Merchant Certificate Setup and CSR Generation
  @security
  Scenario Outline: Merchant generates private key, CSR, submits to HSBC, imports certificate
    Given merchant generates CSR and submits to HSBC
    When HSBC returns signed certificate
    And merchant imports certificate into keystore/IIS
    Then HTTPS API requests to HSBC succeed without error

    Examples:
      | platform   | keytool_alias     | cert_file            |
      | Java       | mykey             | HSBC_Public.cer      |
      | IIS        | merchant_cert     | HSBC_Public.cer      |

  # Root CA Certificate Import
  @security
  Scenario Outline: Merchant imports Root CA and intermediate certificates, validates trust chain
    Given merchant server has keystore '<keystore_file>' ready
    When importing ROOT CA certificate file '<root_cert>' and intermediate '<inter_cert>'
    Then keystore lists both certificates, handshake with HSBC endpoint succeeds

    Examples:
      | keystore_file         | root_cert             | inter_cert             |
      | 2_WAY_SSL_Cert.jks    | ROOTCA_Public.cer     | INTERCA_Public.cer     |

  # HSBC Issued Certificate Import
  @security
  Scenario Outline: Merchant imports HSBC issued certificate to keystore (.jks or IIS)
    Given merchant receives HSBC_Public.cer from HSBC
    When importing certificate into keystore with alias '<alias>'
    Then API connections authenticate successfully with no SSL errors

    Examples:
      | alias        | cert_file            | keystore_file         |
      | mykey        | HSBC_Public.cer      | 2_WAY_SSL_Cert.jks    |

  # Certificate Consumption on IIS (Windows Platform)
  @audit @security
  Scenario Outline: Merchant imports HSBC certificate through IIS, configures HTTPS channel
    Given merchant certificate file '<cert_file>' and IIS server are ready
    When certificate is imported and bound to HTTPS site
    And API requests are invoked over HTTPS
    Then SSL handshake completes and API communication is authenticated

    Examples:
      | cert_file            |
      | HSBC_Public.cer      |

  # Certificate Expiry and Invalid Certificate Handling
  @negative @security
  Scenario Outline: Expired or invalid certificates result in handshake failure and access rejection
    Given merchant imports expired/revoked/corrupted certificate '<cert_file>'
    When API request is invoked to HSBC endpoint
    Then SSL handshake fails, API rejects connection, logs record exact event

    Examples:
      | cert_file           |
      | EXPIRED_CERT.cer    |
      | REVOKED_CERT.cer    |

  # Callback Endpoint URL Whitelisting Validation
  @audit @security
  Scenario Outline: Merchant callback endpoint and static IP whitelisting with HSBC
    Given merchant registers callback URL '<callback_url>' and static IP '<merchant_ip>' with HSBC
    When UPI transaction is initiated and callback is triggered
    Then only whitelisted IP/URL receives notification
    And logs confirm authorized event

    Examples:
      | callback_url                                 | merchant_ip        |
      | https://merchant-test-callback.example.com   | 203.171.209.162   |

  # Static IP Assignment for Callback and HSBC Whitelisting
  @api @security
  Scenario Outline: Merchant assigns static IP and callback URL, only whitelisted endpoint receives callbacks
    Given merchant deploys callback API at '<callback_url>' and assigns static IP '<merchant_ip>'
    When requesting HSBC whitelisting
    And UPI transaction completes, callback is expected
    Then callback is received only at registered IP/URL, no callback for non-whitelisted endpoints

    Examples:
      | callback_url                                  | merchant_ip         |
      | https://callback-merchant123.example.com/upicallback | 203.171.209.5     |

  # Disallowed/Unregistered Endpoint Rejection
  @negative @security
  Scenario Outline: HSBC API ignores requests and callbacks from non-whitelisted public IPs
    Given merchant initiates payment or sets callback endpoint from non-whitelisted IP '<unregistered_ip>'
    When request/callback is sent to HSBC API
    Then API ignores or rejects, no callback is delivered, logs record denied attempt

    Examples:
      | unregistered_ip      |
      | 10.10.10.10          |
      | 203.171.209.8        |

  # Multiple Callback Public IP Handling
  @boundary @api @security
  Scenario Outline: Merchant processes callbacks from all listed whitelisted IPs only
    Given merchant registers callback endpoint and whitelists IPs '<allowed_ip>'
    When receiving callback POST from HSBC
    Then callbacks from allowed IPs are processed, others rejected

    Examples:
      | allowed_ip       |
      | 203.171.209.5    |
      | 203.171.209.6    |
      | 203.171.209.7    |
      | 203.171.222.5    |
      | 203.171.222.6    |
      | 203.171.222.7    |

  # Production and UAT Callback IP Handling
  @audit
  Scenario Outline: Merchant accepts callbacks only for environment-appropriate IPs/URLs (UAT/PROD separation)
    Given merchant sets up endpoints for UAT and PROD with specific IPs and URLs
    When payments are initiated on UAT and PROD systems
    Then callbacks are received only at matching environment endpoints
    And logs show only correct environment activity

    Examples:
      | environment   | callback_ip           | callback_url                      |
      | UAT           | 203.171.209.5         | https://uat-callback.example.com  |
      | PROD          | 203.171.209.130       | https://prod-callback.example.com |

  # Mandatory Parameter Validation for Each API
  @boundary @api
  Scenario Outline: Enforcement and boundary checks for all mandatory fields in Pre-Credit VPA Validation API
    Given merchant submits request with field '<field>' at boundary value '<boundary_value>'
    When API processes request
    Then if value is valid, response is success
    Else response is error with exact rejection message per spec

    Examples:
      | field      | boundary_value        | result     |
      | refNo      | 6                     | success    |
      | refNo      | 16                    | success    |
      | refNo      | 5                     | error      |
      | refNo      | 17                    | error      |
      | payerId    | 6                     | success    |
      | transAmount| max                   | success    |
      | transAmount| min-1                 | error      |
      | addInfo1   | omitted               | success    |

  # Data Type Enforcement and Strict JSON Format Validation
  @boundary @api
  Scenario Outline: API strictly accepts only JSON-format and correct data types in requests/responses
    Given merchant constructs request '<payload_type>' for API endpoint '<api_endpoint>'
    When API processes request
    Then response is '<response_type>' and contains '<error_msg>' for invalid formats/types

    Examples:
      | payload_type      | api_endpoint        | response_type | error_msg                |
      | valid JSON        | /api/upi/collect    | JSON          |                          |
      | plain string      | /api/upi/collect    | error         | Non-JSON request         |
      | string in numeric | /api/upi/collect    | error         | Type mismatch            |
      | missing bracket   | /api/upi/collect    | error         | Malformed JSON structure |
      | valid JSON        | /api/upi/refund     | JSON          |                          |

  # Handling of Optional Parameters Null/Empty for addInfo1-10 in all APIs
  @boundary @api
  Scenario Outline: APIs accept optional addInfo fields as missing, null, empty, or max length without error
    Given merchant submits request with addInfo fields populated as '<population_type>'
    When API processes request
    Then response mirrors state of addInfo fields and returns no parsing or rejection errors

    Examples:
      | population_type           |
      | omitted                  |
      | blank strings            |
      | null values              |
      | max length strings       |
      | mixed state              |
