Feature: Seeker Onboarding, Preference Capture, Resume Handling, Job Matching & Data Retention

  # UI Tests: Onboarding, Preference Capture, Resume Handling, Job Matching, Access, Data Management
  @ui
  Scenario Outline: Capture all required preference fields via onboarding questionnaire
    Given I open a fresh browser session with all cache and cookies cleared
    And I navigate to the platform home page as a new user
    When I begin the onboarding questionnaire and enter:
      | working arrangement | motivator          | activity           | annual salary | location         | job title        | category  | experience | education         | benefit           |
      | <workingArrangement> | <motivator>        | <activity>         | <salary>      | <location>       | <jobTitle>       | <category>| <yearsExp>| <education>       | <benefit>         |
    And I progress through each field, verifying its presence and ability to enter data
    And I submit the questionnaire
    Then I should see a confirmation screen indicating successful capture of preferences
    And all entered fields should be persisted to the seeker's anonymous profile/session

    Examples:
      | workingArrangement | motivator          | activity           | salary | location         | jobTitle        | category    | yearsExp | education         | benefit           |
      | fully remote       | career progression | actively searching | 45000  | United Kingdom   | Product Manager | Product     | 5       | Bachelor’s Degree | remote allowance  |
      | hybrid            | flexibility        |                    |        | Canada           |                 |             |         |                  |                   |
      | no preference     | income             | casually browsing  | 60000  | United States    | Designer;Front-end Developer | Engineering | 2 | Master’s Degree | health insurance  |

  @ui
  Scenario Outline: Distinctly record answered and unanswered preference fields
    Given I start a new browser session with no prior user state
    And I navigate to the home page and begin the onboarding questionnaire
    When I fill out only the following fields:
      | working arrangement | motivator    | location   |
      | <workingArrangement> | <motivator> | <location> |
    And I leave the remaining fields blank or skipped
    And I submit the questionnaire
    Then I should see a completion confirmation
    And the preference state should show answered fields: <answeredFields>
    And the preference state should show unanswered fields: <unansweredFields>

    Examples:
      | workingArrangement | motivator    | location   | answeredFields                    | unansweredFields                                                                                  |
      | hybrid            | flexibility  | Canada     | working arrangement,motivator,location | activity,salary,job title,category,experience,education,workplace benefit                        |

  @ui
  Scenario Outline: Seeker can revisit and change any individual preference without retaking the entire questionnaire
    Given I have completed the onboarding questionnaire as a new anonymous user with preferences:
      | salary   | location    | job title      |
      | <salary> | <location>  | <jobTitle>     |
    When I proceed to the dashboard
    And I click the 'Edit my preferences' button
    And I edit the <fieldToEdit> to "<newValue>" and save the change
    Then the profile summary should reflect "<newValue>" for <fieldToEdit>
    And all other preference fields remain unchanged
    And no full questionnaire is triggered

    Examples:
      | salary | location   | jobTitle         | fieldToEdit     | newValue   |
      | 45000  | UK         | Product Manager  | salary          | 50000      |
      | 80000  | Canada     | Marketing Lead   | location        | France     |

  @ui
  Scenario Outline: Seeker can indicate resume state during onboarding
    Given I am on the onboarding resume state capture screen as a new user
    When I select "<resumeState>" as the resume state
    Then the selection "<resumeState>" is shown and persists for later steps

    Examples:
      | resumeState     |
      | up to date      |
      | needs work      |
      | not written yet |

  @ui
  Scenario Outline: Upload resumes in supported formats under size limit
    Given I am at the onboarding resume-upload screen with test files available
    When I upload "<filename>" with file size "<sizeMB>" MB and format "<format>"
    Then the upload is successful
    And the resume appears as uploaded and persists to the seeker's profile/session

    Examples:
      | filename             | sizeMB | format  |
      | test_resume.pdf      | 2      | pdf     |
      | test_resume.docx     | 1      | docx    |
      | test_resume.txt      | 0.5    | txt     |

  @ui
  Scenario Outline: Reject unsupported resume formats with clear reason
    Given I am at the onboarding resume-upload screen
    When I try to upload "<filename>" with format "<format>" and size "<sizeMB>" MB
    Then the system rejects the upload and displays the error "<errorMessage>"
    And the file is not attached to the seeker profile/session

    Examples:
      | filename            | format | sizeMB | errorMessage              |
      | test_resume.jpg     | jpg    | 2      | Unsupported file format   |
      | test_resume.exe     | exe    | 4      | Unsupported file format   |

  @ui
  Scenario Outline: Validate boundary values for resume file size
    Given I am at the onboarding resume-upload screen
    When I upload "<filename>" with format "<format>" and size "<sizeMB>" MB
    Then the system shows "<uploadStatus>" and "<errorMessage>"

    Examples:
      | filename           | format | sizeMB | uploadStatus | errorMessage                                       |
      | resume_4_9mb.pdf   | pdf    | 4.9    | accepted     |                                                    |
      | resume_5mb.pdf     | pdf    | 5      | accepted     |                                                    |
      | resume_5_1mb.pdf   | pdf    | 5.1    | rejected     | File size exceeds limit                            |

  @ui
  Scenario Outline: Personalized job listings shown after preference onboarding
    Given I have completed onboarding with preferences:
      | category   | working arrangement | location | salary  |
      | <category> | <workingArrangement>| <location>| <salary>|
    When I submit preferences and arrive on the results page
    Then listings should match preferences: <expectedMatch>
    When I change preference <changedField> to "<changedValue>"
    Then listings update to reflect "<changedValue>" in <changedField>

    Examples:
      | category    | workingArrangement | location    | salary | expectedMatch                                  | changedField  | changedValue    |
      | Engineering | remote             | Canada      | 80000  | Engineering, remote, Canada, salary:80000       | category      | Design         |
      | Design      | hybrid             | France      | 65000  | Design, hybrid, France, salary:65000            | location      | All            |

  @ui
  Scenario Outline: Persist preferences across searches in current and future sessions after login
    Given I have completed onboarding anonymously with preferences:
      | category   | working arrangement | location | salary  |
      | <category> | <workingArrangement>| <location>| <salary>|
    When I perform job searches in this session
    Then results should reflect <expectedMatch>
    When I start a new session or log in after registering with email "<email>"
    And I perform job searches again
    Then previous preferences determine the results

    Examples:
      | category    | workingArrangement | location    | salary | expectedMatch                  | email                        |
      | Engineering | remote             | Canada      | 80000  | Engineering, remote, Canada    | test+persist01@example.com   |

  @ui
  Scenario Outline: Seeker can widen, narrow, or clear preferences from search results
    Given I am on the personalized job listings page after onboarding
    When I modify filter "<filterType>" from "<originalValue>" to "<newValue>"
    Then job results update live to reflect "<newValue>" for "<filterType>"
    And no full questionnaire is restarted

    Examples:
      | filterType           | originalValue         | newValue             |
      | working arrangement  | Remote only           | Remote or Hybrid     |
      | salary               | $100,000              | $120,000             |
      | location             | United States         | All                  |

  @ui
  Scenario Outline: UI indicates constraints when few results are returned
    Given I complete the onboarding questionnaire with restrictive preferences:
      | jobTitle      | location    | salary      |
      | <jobTitle>    | <location>  | <salary>    |
    When the results page loads with few or zero listings
    Then I should see a UI alert that indicates scarcity of results
    And the UI highlights "<constraint>" as the narrowing filter

    Examples:
      | jobTitle    | location | salary   | constraint         |
      | Astronaut   | Iceland  | 250000   | Job Title: Astronaut, Salary: $250,000 |
      | Brain Surgeon | Maldives | 200000 | Job Title: Brain Surgeon, Location: Maldives |

  @ui
  Scenario: Anonymous seeker can browse listings, complete questionnaire, and view results without account or payment
    Given I am not logged in and the platform is accessible
    When I browse job listings
    And I complete the onboarding questionnaire with valid test data
    And I submit the questionnaire
    Then I see personalized job matches
    And at no point am I prompted for registration or payment

  @ui
  Scenario Outline: Registration requested only when seeker acts on a listing
    Given I am browsing as an anonymous user
    And I have completed onboarding and view personalized job listings
    When I take the action "<jobAction>" on a job listing
    Then the system prompts for account registration
    And no prior registration or payment prompts were shown

    Examples:
      | jobAction     |
      | apply         |
      | save job      |
      | set alert     |

  @ui
  Scenario: Preferences captured during anonymous use carry over to account after registration
    Given I completed onboarding as an anonymous user with preferences
    And view personalized job matches
    When I apply to a job and complete registration with new credentials
    Then my account profile shows all earlier preferences
    And recommended jobs reflect these preferences

  @ui
  Scenario: Uploaded resumes persist and attach to new account after registration
    Given I upload a resume during anonymous onboarding
    When I register a new account after acting on a listing
    Then my profile has my previously uploaded resume available
    And resume metadata (filename, status) is preserved

  @ui
  Scenario: Preferences and resume data persist for duration of anonymous visit and carry into account
    Given I complete onboarding and upload a resume as an anonymous user
    When I refresh or navigate to different sections
    Then preferences and resume data remain present
    When I register for an account and log in
    Then all preferences and resume data persist into the new account

  @ui
  Scenario Outline: Seeker can remove resume and clear preferences, both as guest and registered user
    Given I have uploaded a resume "<filename>" and completed preferences as <userType>
    When I use the UI to delete the resume and clear preferences
    And I refresh or revisit the profile/results area
    Then the resume and preference data are absent

    Examples:
      | filename             | userType     |
      | test_resume_remove.pdf | anonymous    |
      | test_resume_remove.pdf | registered   |

  # Boundary & Negative UI Tests: Job Title, Resume Format/Size Validation
  @ui
  Scenario Outline: Job title entry respects maximum allowed
    Given I am at the onboarding questionnaire job title section
    When I enter the following job titles: <jobTitles>
    Then system <status> entry
    And "<errorMessage>" is displayed if applicable

    Examples:
      | jobTitles                                                   | status    | errorMessage                  |
      | Data Analyst, Marketing Manager, Product Owner, UX Designer | accepts   |                              |
      | Data Analyst, Marketing Manager, Product Owner, UX Designer, HR Manager | accepts   |                              |
      | Data Analyst, Marketing Manager, Product Owner, UX Designer, HR Manager, Freelancer | blocks    | Maximum 5 job titles allowed |

  @ui
  Scenario Outline: Resume upload accepts/rejects files based on format and size boundaries
    Given I am at the onboarding resume-upload interface
    When I upload "<filename>" with format "<format>" and size "<sizeMB>" MB
    Then system <uploadStatus> file
    And "<errorMessage>" is shown if applicable

    Examples:
      | filename            | format | sizeMB | uploadStatus | errorMessage              |
      | resume_valid.pdf    | pdf    | 4.9    | accepts      |                          |
      | resume_invalid.exe  | exe    | 1      | rejects      | Unsupported format        |
      | resume_max.docx     | docx   | 5      | accepts      |                          |
      | resume_over.docx    | docx   | 5.001  | rejects      | File size exceeds limit   |
      | resume_corrupt.pdf  | pdf    | 4      | rejects      | Corrupt file             |

  # API/Security Test: Data Deletion and Protection
  @api @security
  Scenario Outline: System compliance with data protection obligations - resume and PII removal
    Given the API base URL is "<baseUrl>"
    And the authorization token is set if required
    When I upload a resume file "<filename>" and provide PII via onboarding (names, job role, location)
    And I invoke API endpoint "<deleteEndpoint>" to remove resume and clear preferences
    Then the response status is <statusCode>
    And the DB, cache, logs, and UI show no remaining resume or PII for that user
    And deleted PII and resume cannot be recovered
    And all data is handled per applicable data protection obligations (e.g., GDPR)

    Examples:
      | baseUrl               | filename                | deleteEndpoint    | statusCode |
      | https://api.flexjobs/ | resume_privacy_check.docx | /api/seeker/delete | 200        |

