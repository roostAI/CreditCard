Feature: User and Course Management System

  # UI Test Scenarios
  @ui
  Scenario Outline: User Registration and Profile Management
    Given I am on the registration page
    When I enter valid user details with email "<email>", age "<age>", and contact number "<contact>"
    And I submit the registration form
    Then I should receive a confirmation email
    And I should be able to log in with the new credentials
    When I update my profile information with "<profile_info>"
    Then the profile updates should be saved

    Examples:
      | email             | age | contact     | profile_info         |
      | user1@example.com | 18  | 1234567890  | {"name": "User One"} |
      | user2@example.com | 25  | 0987654321  | {"name": "User Two"} |

  @ui
  Scenario Outline: Course Enrollment and Management
    Given I am logged in with a valid profile
    When I navigate to the course catalog
    And I select a course "<course_name>"
    And I enroll in the course
    Then I should see the course in my enrolled courses
    When I withdraw from the course
    Then the course should no longer appear in my enrolled courses

    Examples:
      | course_name       |
      | "Introduction to Testing" |
      | "Advanced API Design"     |

  @ui
  Scenario Outline: Assignment Submission and Grading
    Given I am enrolled in a course with assignments
    When I navigate to the course assignments
    And I select an assignment "<assignment_name>"
    And I submit the assignment
    Then the assignment should be submitted successfully
    When the instructor grades the assignment
    Then I should see the grade "<grade>"

    Examples:
      | assignment_name   | grade |
      | "Assignment 1"    | 85    |
      | "Assignment 2"    | 90    |

  @ui
  Scenario Outline: User Role and Permission Management
    Given I am logged in as an admin
    When I assign the role "<role>" to a user
    Then the user should have access to "<features>"

    Examples:
      | role      | features                    |
      | "student" | "view courses"              |
      | "admin"   | "manage users, view reports"|

  @ui
  Scenario Outline: Reporting and Analytics Dashboard
    Given I am logged in as an admin
    When I navigate to the analytics dashboard
    And I generate a report on "<report_type>"
    Then the report should display "<expected_data>"

    Examples:
      | report_type        | expected_data                  |
      | "course enrollments" | "total enrollments: 100"     |
      | "user activity"      | "active users: 50"           |

  @ui
  Scenario Outline: Notification and Alert System
    Given I am logged in as a student
    When I navigate to the course dashboard
    And I check for notifications related to "<notification_type>"
    Then I should see notifications for "<expected_notifications>"

    Examples:
      | notification_type | expected_notifications          |
      | "upcoming assignments" | "Assignment 1 due soon"    |
      | "course updates"       | "New material added"       |

  @ui
  Scenario Outline: UI Interactions Across All Screens
    Given I am logged in
    When I navigate through all available screens
    And I interact with UI elements like "<element>"
    Then all elements should be functional and accessible

    Examples:
      | element    |
      | "buttons"  |
      | "dropdowns"|

  @ui
  Scenario Outline: Data Validation for Student Information
    Given I am logged in as a student
    When I navigate to the profile management page
    And I edit student information fields with "<field_data>"
    And I submit changes
    Then the data should be validated and stored accurately
    When I attempt to input invalid data "<invalid_data>"
    Then I should see validation messages "<error_message>"

    Examples:
      | field_data                  | invalid_data | error_message        |
      | {"name": "Valid Name"}      | ""           | "Name is required"   |
      | {"contact": "1234567890"}   | "abc"        | "Invalid contact"    |

  @ui
  Scenario Outline: Cross-Platform UI Consistency
    Given I access the application on a "<device>"
    When I navigate through various screens
    Then the UI elements should be consistent and functional

    Examples:
      | device   |
      | "desktop"|
      | "tablet" |
      | "mobile" |

  # API Test Scenarios
  @api
  Scenario Outline: Integration with External Payment Gateway
    Given the API base URL is "https://api.paymentgateway.com"
    And the authorization token is set
    When I send a POST request to "/payments" with payload """
    {
      "userId": "<user_id>",
      "courseId": "<course_id>",
      "amount": "<amount>"
    }
    """
    Then the response status should be 200
    And the response should contain "transactionId"

    Examples:
      | user_id | course_id | amount |
      | 1       | 101       | 100.00 |
      | 2       | 102       | 200.00 |

  @api
  Scenario Outline: External System Integration for Learning Management
    Given the API base URL is "https://api.lms.com"
    And the authorization token is set
    When I send a GET request to "/courses/sync"
    Then the response status should be 200
    And the response should contain "syncedCourses"

    Examples:
      | syncedCourses |
      | "Course A"    |
      | "Course B"    |

  @api
  Scenario Outline: Data Integrity During Course Withdrawal
    Given the API base URL is "https://api.coursemanagement.com"
    And the authorization token is set
    When I send a DELETE request to "/enrollments/<enrollment_id>"
    Then the response status should be 200
    And the response should confirm "withdrawalSuccess"

    Examples:
      | enrollment_id |
      | 1001          |
      | 1002          |

  @api
  Scenario Outline: Grade Calculation Accuracy
    Given the API base URL is "https://api.grading.com"
    And the authorization token is set
    When I send a POST request to "/grades/calculate" with payload """
    {
      "studentId": "<student_id>",
      "assignmentScores": "<scores>"
    }
    """
    Then the response status should be 200
    And the response should contain "finalGrade"

    Examples:
      | student_id | scores          |
      | 1          | [85, 90, 80]    |
      | 2          | [70, 75, 80]    |
