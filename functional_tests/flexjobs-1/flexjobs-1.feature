Feature: Seeker Onboarding, Preference Management, Resume Handling, Listing Personalization, Registration, Data Deletion and Compliance

  # UI Test Scenarios: Questionnaire, Preference Management, Resume Upload, Listings, Registration, Data Removal

  @ui
  Scenario Outline: Submit partially completed questionnaire and confirm answered/unanswered fields are tracked (TC-SEEKPREF-02)
    Given I am a new seeker on the platform homepage in incognito mode
    When I start the preference questionnaire
    And I complete the following fields:
      | working arrangement | motivator | annual salary | job titles | education | category | years experience | workplace benefit |
      | <arrangement>       | <motivator> | <salary>    | <jobs>    | <education> | <category> | <years> | <benefit> |
    And I submit the questionnaire
    Then I should see a notification of partial completion (if applicable)
    And my seeker profile should reflect only the provided values (<arrangement>, <motivator>)
    And any omitted fields should be marked or visible as 'unanswered'
    And personalized job results should reflect only provided preferences

    Examples:
      | arrangement | motivator   | salary | jobs | education | category | years | benefit |
      | Hybrid      | Flexibility |        |      |           |          |       |         |
      | Fully Remote|             |        |      |           |          |       |         |
      | Hybrid      | Flexibility | 90000  |      |           |          |       |         |

  @ui
  Scenario Outline: Edit an individual preference after questionnaire without repeating all fields (TC-SEEKPREF-03)
    Given I am an anonymous seeker and have completed all preference questionnaire fields
    And I have submitted my preferences
    When I go to the profile preferences section
    And I select "Edit" for '<preference>' preference
    And I change the value from '<old_value>' to '<new_value>'
    And I save the updated preferences
    Then only '<preference>' is updated, all other preferences remain unchanged
    And personalized job results update to reflect '<new_value>'

    Examples:
      | preference   | old_value          | new_value            |
      | job titles   | Software Engineer  | Data Analyst         |
      | motivator    | Career Progression | Flexibility          |
      | location     | Germany            | Belgium              |

  @ui
  Scenario Outline: Job title selection enforces maximum allowed, accepts N-1/N, rejects N+1 (TC-SEEKPREF-04)
    Given I am completing the seeker onboarding questionnaire
    When I select the following job titles: <job_titles>
    And I attempt to submit the questionnaire
    Then the platform should <expected_result>
    And only the valid number of job titles (<stored_titles>) should be recorded

    Examples:
      | job_titles                                  | expected_result                             | stored_titles                                |
      | QA Tester, DevOps Engineer                  | accept submission                           | QA Tester, DevOps Engineer                   |
      | QA Tester, DevOps Engineer, Scrum Master    | accept submission                           | QA Tester, DevOps Engineer, Scrum Master     |
      | QA Tester, DevOps Engineer, Scrum Master, Backend Developer | show error "Maximum job titles exceeded" | QA Tester, DevOps Engineer, Scrum Master     |

  @ui
  Scenario Outline: Location field only accepts valid standard country/region values (TC-SEEKPREF-05)
    Given the onboarding questionnaire and location picker is available
    When I enter '<location_input>' as the location
    And I attempt to submit preferences
    Then the platform should <expected_behaviour>
    And invalid values must not be stored

    Examples:
      | location_input     | expected_behaviour              |
      | Germany           | accept location                 |
      | Atlantis          | show error "Location not found" |
      | 12345             | show error "Invalid location"   |
      | Unite States      | show error "Location not found" |
      | United States     | accept location                 |

  @ui
  Scenario Outline: Working arrangement allows only the valid stated options (TC-SEEKPREF-06)
    Given I am presented with the working arrangement selection
    When I select '<option>' as working arrangement
    And I submit preferences
    Then the platform should <expected_result>
    And only a valid value is stored

    Examples:
      | option         | expected_result                    |
      | Fully Remote   | accept selection                   |
      | Hybrid         | accept selection                   |
      | No Preference  | accept selection                   |
      | Office-based   | show error "Invalid option"        |

  @ui
  Scenario Outline: Resume state is declared and correctly reflected in profile (TC-RESUME-01)
    Given I have completed the preference questionnaire
    When I reach the resume status step and select '<resume_state>'
    And I save the resume state preference
    Then the status '<resume_state>' is recorded under my profile
    And guidance/upload prompts reflect the chosen status

    Examples:
      | resume_state      |
      | Up to date        |
      | Needs work        |
      | Not written yet   |

  @ui
  Scenario Outline: Supported resume formats and size limit are accepted and stored (TC-RESUME-02)
    Given I am at the resume upload step after onboarding
    When I upload a resume file '<file_name>' in '<format>' format with size <size>
    Then the platform should accept and confirm the upload
    And the resume is stored against my profile for matching/application

    Examples:
      | file_name              | format | size  |
      | test-seeker-001.pdf    | PDF    | 400KB |
      | test-seeker-001.docx   | DOCX   | 900KB |

  @ui
  Scenario Outline: Resume upload above size limit is rejected (TC-RESUME-03)
    Given I am at the resume upload interface after questionnaire
    When I select and upload '<file_name>' in '<format>' format with size <size>
    Then the platform should reject upload
    And I should see error message '<error_message>'
    And my profile should not store this resume

    Examples:
      | file_name                   | format | size  | error_message                                    |
      | test-seeker-001-large.pdf   | PDF    | 1.5MB | Document exceeds maximum size limit (1MB)         |

  @ui
  Scenario Outline: Resume upload in unsupported format is rejected (TC-RESUME-04)
    Given I have completed the preference questionnaire and am at resume upload
    When I upload '<file_name>' in '<format>' format
    Then the platform should reject the upload
    And I should see error message "Unsupported format"
    And no file is stored unless in supported format

    Examples:
      | file_name                | format |
      | test-seeker-001.txt      | TXT    |
      | test-seeker-001.rtf      | RTF    |
      | test-seeker-001.pptx     | PPTX   |

  @ui
  Scenario: Supported resume format is accepted after invalid attempts (TC-RESUME-04)
    Given I am at resume upload interface after previous errors
    When I upload 'test-seeker-001.pdf' in PDF format
    Then the platform should accept upload
    And resume is stored against profile

  @ui
  Scenario Outline: Resume is confirmed as received before being associated with seeker profile (TC-RESUME-05)
    Given I am an anonymous seeker beginning onboarding and upload a valid resume
    When I click 'Upload' for '<file_name>' in '<format>' format and <size>
    Then I should see a confirmation message "Resume received" before resume appears in profile
    And resume association occurs only after confirmation
    And resume persists on page refresh after confirmation

    Examples:
      | file_name            | format | size |
      | test_resume.docx     | DOCX   | 2MB  |

  @ui
  Scenario Outline: Personalized job listings are generated based on captured preferences (TC-MATCH-01)
    Given I am a first-time visitor completing onboarding questionnaire with preferences:
      | working arrangement | motivator          | location | job titles              |
      | <arrangement>       | <motivator>        | <location> | <job_titles>         |
    When I submit the questionnaire
    Then I should see personalized job listings matching these preferences
    And no registration or payment is required to view them

    Examples:
      | arrangement     | motivator         | location | job_titles           |
      | Fully Remote    | Career Progression| Canada   | Frontend Developer   |
      | Hybrid          | Flexibility       | UK       | Product Manager      |

  @ui
  Scenario Outline: Preference change triggers refreshed job listings (TC-MATCH-02)
    Given I have completed onboarding and am viewing personalized results for
      | location | job title       |
      | <location> | <job_title>  |
    When I edit a preference '<changed_pref>' from '<old_value>' to '<new_value>'
    And I save the preference change
    Then job listings are promptly refreshed and reflect only the new criteria

    Examples:
      | location | job_title     | changed_pref | old_value        | new_value     |
      | Germany  | Backend Engineer | location    | Germany         | Belgium      |
      | UK       | Product Manager  | job_title   | Product Manager | QA Tester    |

  @ui
  Scenario Outline: Seekers can widen, narrow, or clear preferences and see effects in results (TC-MATCH-03)
    Given I am viewing personalized results after onboarding
    When I <action> the '<preference>' filter to <change_type> with value '<value>'
    Then job listings should update to reflect this change immediately

    Examples:
      | action   | preference   | change_type   | value          |
      | add      | location     | widen         | UK             |
      | remove   | job title    | clear         |                |
      | add      | category     | narrow        | IT             |
      | add      | workplace benefit | narrow   | Flexible schedule |

  @ui
  Scenario Outline: System warns and highlights constraint when few listings are found (TC-MATCH-04)
    Given I submit highly-specific preferences in onboarding:
      | job title            | location   | salary     | category                 |
      | <job_title>          | <location> | <salary>   | <category>               |
    When I view job results for these preferences
    Then I should see a warning "Few listings found"
    And the UI identifies '<constraint>' as the most limiting filter

    Examples:
      | job_title           | location     | salary   | category                | constraint        |
      | Obscure Niche Role  | Vanuatu      | 250000   | Quantum Cheese Analysis | job title        |
      | QA Tester           | Antarctica   | 100000   | IT                      | location         |

  @ui
  Scenario: Anonymous browsing, questionnaire, results, and listing details require no registration/payment (TC-REGACC-01)
    Given I am a new visitor in incognito mode with no account
    When I browse listings and complete the onboarding questionnaire
    And I submit preferences and view personalized results
    And I repeat the journey multiple times in the session
    And I try to view listing details
    Then at no stage should login, registration, or payment be required to access these features

  @ui
  Scenario Outline: Registration is only requested on apply/save/listing alert actions (TC-REGACC-02)
    Given I am an anonymous visitor viewing personalized listings after onboarding
    When I <action> a job listing
    Then I should see a registration prompt
    And if I only browse/search and read details, no registration prompt is shown

    Examples:
      | action       |
      | save         |
      | apply        |
      | set up alerts|

  @ui
  Scenario Outline: Preferences and resume from anonymous session persist after signup (TC-REGACC-03)
    Given I am an anonymous seeker who completed onboarding and uploaded a resume
    When I trigger registration by <action> and create an account with '<email>'
    And I log in and navigate to profile
    Then all previously captured preferences and resume are present in the account profile
    And job search reflects initial preferences

    Examples:
      | action | email                     |
      | apply  | test+carryover@example.com|

  @ui
  Scenario Outline: Preferences and uploaded documents are held throughout anonymous session and under account after signup (TC-DATA-01)
    Given I am a visitor who completed onboarding and uploaded a resume
    When I navigate away and back within the same session
    Then all preferences and resume upload remain intact
    When I register with '<email>' and log in
    Then preferences and resume file are present under new profile

    Examples:
      | email                        |
      | test+persist@example.com     |

  @ui
  Scenario Outline: Seeker can remove resume and clear preferences with full data deletion (TC-DATA-02)
    Given I am logged in as '<email>' with preferences and an uploaded resume
    When I use UI controls to remove my resume
    Then the resume is deleted and no longer shown in profile
    When I clear all preferences
    Then all preference fields are blanked
    When I log out and log in again
    Then no deleted data is present
    And there is no option to restore deleted items

    Examples:
      | email                        |
      | test+removal@example.com     |

  @ui
  Scenario Outline: E2E onboarding: questionnaire, upload resume, view results, edit, apply, register, confirm data carryover (TC-E2E-01)
    Given I access the home page as a new anonymous seeker
    When I fill all onboarding fields:
      | working arrangement | motivation         | salary | location | job titles        | category | experience | education | benefit           |
      | <arrangement>       | <motivation>       | <salary> | <location> | <job_titles>   | <category> | <experience> | <education> | <benefit>  |
    And I upload '<file_name>' in <format> (<size>)
    And I submit questionnaire and see personalized results
    When I edit preferences: change salary to '<salary2>', add '<arrangement2>' to working arrangement; submit changes
    Then results update and constraint indicators appear if listings decrease
    When I apply for a job and register with '<reg_email>' and password
    Then uploaded resume and all onboarding preferences are shown in account profile
    And job matches reflect preferences before and after registration
    When I edit a preference post-registration
    Then job listings update accordingly
    And all data persists across log out and login

    Examples:
      | arrangement  | motivation          | salary | location | job_titles       | category | experience | education | benefit         | file_name              | format | size  | salary2 | arrangement2 | reg_email                |
      | Remote       | Career progression  | 90000  | USA      | Product Manager  | IT       | 7         | Bachelor  | Flexible schedule| test-resume-onboard.pdf | PDF    | 2MB   | 100000  | Hybrid       | test+e2e01@example.com   |

  @ui
  Scenario Outline: E2E onboarding with partial fields, valid/invalid resumes, deleting data, and registration (TC-E2E-02)
    Given I am an anonymous seeker on platform home
    When I do onboarding and answer:
      | location | job titles |
      | <location> | <job_titles> |
    And I attempt resume upload with '<invalid_resume>' (<invalid_reason>)
    Then I should see error message '<error_msg_invalid>'
    When I upload '<valid_resume>' (supported format, <valid_size>)
    Then resume appears in session/profile
    When I remove the uploaded resume
    Then UI and API show resume as deleted
    When I clear all preferences using UI controls
    Then only provided fields are recorded, others marked 'not answered'
    And no resume is used in job matching
    When I register with '<reg_email>' after acting on a listing
    Then no cleared preferences or deleted resumes appear in account profile
    And deleted data is not accessible in backend

    Examples:
      | location | job_titles | invalid_resume         | invalid_reason    | error_msg_invalid                        | valid_resume         | valid_size | reg_email                      |
      | UK       | Developer  | resume-unsupported.txt | Unsupported format| Unsupported format                       | resume-valid.pdf     | 800KB      | test+partialdelete@example.com |
      | UK       | Developer  | resume-oversize.pdf    | Oversize file     | Document exceeds maximum size limit (1MB)| resume-valid.pdf     | 800KB      | test+partialdelete@example.com |

  # API Test Scenarios: Audit, Data Storage/Deletion, Compliance

  @api
  Scenario Outline: All personal data and documents handled according to data protection obligations (TC-DATA-03)
    Given the platform is deployed with compliance mode and audit logging enabled
    And audit records are accessible
    When a new seeker provides personal details and uploads '<resume_file>' containing fictitious PII
    And requests deletion of resume and clears all preferences
    Then audit logs record storage and deletion events with masking
    And no PII or personal document remains in backend storage after deletion
    When seeker registers with '<account_email>'
    Then new profile does not retain prior deleted data
    When seeker uploads new resume and preferences and deletes them again post-registration
    Then audit logs confirm storage and deletion and masking of PII
    And all API and backend queries for deleted data return 'not found'

    Examples:
      | resume_file            | account_email           |
      | resume-pii-test.pdf    | test+pii2@example.com   |
      | resume-pii2-test.pdf   | test+pii3@example.com   |
