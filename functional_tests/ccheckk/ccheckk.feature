Feature: Educational Software Functional Testing

  # UI Test Scenarios
  @ui
  Scenario Outline: User Registration and Profile Management
    Given I am on the registration page
    When I enter "<email>" and "<password>" and "<age>"
    And I submit the registration form
    Then I should be registered successfully
    When I log in with "<email>" and "<password>"
    And I navigate to the profile page
    And I update my profile with "<new_name>" and "<new_age>"
    Then the profile updates should be saved

    Examples:
      | email             | password | age | new_name | new_age |
      | user1@example.com | Pass123! | 25  | User One | 26      |
      | user2@example.com | Pass456! | 30  | User Two | 31      |

  @ui
  Scenario Outline: Course Enrollment and Management
    Given I am logged in as a user
    When I navigate to the course catalog
    And I select the course "<course_name>"
    And I click 'Enroll'
    Then the course should be added to 'My Courses'
    When I navigate to 'My Courses'
    And I unenroll from "<course_name>"
    Then the course should be removed from 'My Courses'

    Examples:
      | course_name       |
      | Introduction to AI|
      | Advanced Math     |

  @ui
  Scenario Outline: Assignment Submission and Grading
    Given I am enrolled in a course with assignments
    When I navigate to course assignments
    And I select the assignment "<assignment_name>"
    And I upload the assignment file "<file_name>"
    And I submit the assignment
    Then the assignment should be submitted successfully
    When the instructor logs in and grades the assignment
    Then I should see the grade "<expected_grade>"

    Examples:
      | assignment_name | file_name      | expected_grade |
      | Assignment 1    | assignment1.doc| A              |
      | Assignment 2    | assignment2.pdf| B+             |

  @ui
  Scenario Outline: User Role and Permission Management
    Given I am logged in as an admin
    When I assign the role "<role>" to user "<username>"
    And I log in as "<username>"
    And I attempt to access "<feature>"
    Then I should "<access>" the feature

    Examples:
      | role    | username | feature          | access  |
      | student | user1    | course catalog   | access  |
      | guest   | user2    | admin dashboard  | not access |

  @ui
  Scenario Outline: Reporting and Analytics Dashboard
    Given I am logged in as a user with reporting access
    When I navigate to the analytics dashboard
    And I select the report type "<report_type>"
    And I apply filters "<filters>"
    And I generate the report
    Then the report should be generated accurately
    And I should be able to export the report data

    Examples:
      | report_type | filters        |
      | Performance | Date Range     |
      | Attendance  | Course Filter  |

  @ui
  Scenario Outline: Notification and Alert System
    Given I am logged in as a user
    When I navigate to notification settings
    And I enable notifications for "<notification_type>"
    And I submit an assignment close to the deadline
    Then I should receive a notification "<expected_notification>"

    Examples:
      | notification_type       | expected_notification       |
      | assignment deadlines    | Assignment due soon alert   |
      | new course announcements| New course available alert  |

  # API Test Scenarios
  @api
  Scenario Outline: Integration with External LMS
    Given the API base URL is '<base_url>'
    And the authorization token is set
    When I send a POST request to '/api/lms/link' with payload """
    {
      "lms_account": "<lms_account>"
    }
    """
    Then the response status should be 200
    And the response should contain 'linked'

    Examples:
      | base_url           | lms_account |
      | http://api.example | account123  |

  @api
  Scenario Outline: Data Import/Export Functionality
    Given the API base URL is '<base_url>'
    And the authorization token is set
    When I send a POST request to '/api/data/import' with payload """
    {
      "file": "<file_name>"
    }
    """
    Then the response status should be 200
    And the response should contain 'imported'
    When I send a GET request to '/api/data/export'
    Then the response status should be 200
    And the response should contain 'exported'

    Examples:
      | base_url           | file_name       |
      | http://api.example | students.csv    |

  @api
  Scenario Outline: Concurrent User Operations
    Given the API base URL is '<base_url>'
    And the authorization token is set
    When multiple users perform operations concurrently
    Then data consistency should be maintained

    Examples:
      | base_url           |
      | http://api.example |

  @api
  Scenario Outline: Grade Calculation Accuracy
    Given the API base URL is '<base_url>'
    And the authorization token is set
    When I send a GET request to '/api/grades/calculate' with payload """
    {
      "student_id": "<student_id>",
      "course_id": "<course_id>"
    }
    """
    Then the response status should be 200
    And the calculated grade should match '<expected_grade>'

    Examples:
      | base_url           | student_id | course_id | expected_grade |
      | http://api.example | 123        | 456       | A              |
