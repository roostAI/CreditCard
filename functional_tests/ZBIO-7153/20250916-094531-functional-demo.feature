Feature: בדיקת מערכת גבייה לכרטיסי אשראי

Background:
  Given כתובת הבסיס של ה-API היא מוגדרת מ-Environment Variable 'COLLECTION_API_BASE_URL'
  And כותרת ההרשאה מוגדרת מ-Environment Variable 'AUTHORIZATION_TOKEN'
  And סוג התוכן הוא 'application/json'

Scenario: שליחת תזכורת לתשלום כרטיס אשראי
  Given כרטיס אשראי פעיל במערכת עם מספר "1234567890123456"
  And תאריך הפירעון הוא בעוד 3 ימים
  When אני שולח בקשת POST ל-'/api/reminders/payment' עם הנתונים:
    """
    {
      "cardNumber": "1234567890123456",
      "dueDate": "2024-01-15",
      "amount": 1500.00
    }
    """
  Then סטטוס התגובה צריך להיות 200
  And התגובה צריכה להכיל "reminderSent": true
  And התגובה צריכה להכיל רק 4 ספרות אחרונות "3456"
  And התגובה לא צריכה להכיל את מספר הכרטיס המלא

Scenario: שליחת התראת יתרה באיחור
  Given כרטיס אשראי עם מספר "9876543210987654"
  And תאריך הפירעון עבר לפני 5 ימים
  And יתרה חייבת של 2500.00 שקלים
  When אני שולח בקשת POST ל-'/api/alerts/overdue' עם הנתונים:
    """
    {
      "cardNumber": "9876543210987654",
      "overdueAmount": 2500.00,
      "daysPastDue": 5
    }
    """
  Then סטטוס התגובה צריך להיות 200
  And התגובה צריכה להכיל "alertSent": true
  And התגובה צריכה להכיל "lastFourDigits": "7654"
  And התגובה צריכה להכיל "overdueAmount": 2500.00
  And התגובה לא צריכה לחשוף את מספר הכרטיס המלא

Scenario: שליחת הודעת גבייה רשמית
  Given חשבון כרטיס אשראי עם מספר "1111222233334444"
  And החשבון בפיגור של 35 ימים
  And יתרה חייבת של 5000.00 שקלים
  When אני שולח בקשת POST ל-'/api/collection/formal-notice' עם הנתונים:
    """
    {
      "cardNumber": "1111222233334444",
      "outstandingAmount": 5000.00,
      "daysPastDue": 35,
      "additionalFees": 250.00
    }
    """
  Then סטטוס התגובה צריך להיות 201
  And התגובה צריכה להכיל "formalNoticeSent": true
  And התגובה צריכה להכיל "lastFourDigits": "4444"
  And התגובה צריכה להכיל "totalAmount": 5250.00
  And התגובה צריכה להכיל "additionalFees": 250.00

Scenario: יצירת הצעת תוכנית תשלומים
  Given כרטיס אשראי עם מספר "5555666677778888"
  And יתרה באיחור של 8000.00 שקלים
  And בקשה לתוכנית תשלומים
  When אני שולח בקשת POST ל-'/api/payment-plans/create' עם הנתונים:
    """
    {
      "cardNumber": "5555666677778888",
      "totalDebt": 8000.00,
      "requestedMonths": 12,
      "monthlyPaymentCapacity": 700.00
    }
    """
  Then סטטוס התגובה צריך להיות 201
  And התגובה צריכה להכיל "paymentPlanCreated": true
  And התגובה צריכה להכיל "lastFourDigits": "8888"
  And התגובה צריכה להכיל "monthlyPayment"
  And התגובה צריכה להכיל "interestRate"
  And התגובה צריכה להכיל "paymentSchedule"

Scenario: העברה לסוכנות גבייה חיצונית
  Given חשבון כרטיס אשראי עם מספר "9999888877776666"
  And החשבון לא הגיב להודעות במשך 60 ימים
  And יתרה חייבת של 12000.00 שקלים
  When אני שולח בקשת POST ל-'/api/collection/transfer-external' עם הנתונים:
    """
    {
      "cardNumber": "9999888877776666",
      "outstandingAmount": 12000.00,
      "daysUnresponsive": 60,
      "collectionAgencyId": "AGENCY_001"
    }
    """
  Then סטטוס התגובה צריך להיות 200
  And התגובה צריכה להכיל "transferredToAgency": true
  And התגובה צריכה להכיל "lastFourDigits": "6666"
  And התגובה צריכה להכיל "agencyId": "AGENCY_001"
  And התגובה צריכה להכיל "internalNotificationsStopped": true

Scenario: הכנת תיעוד להליכים משפטיים
  Given חשבון כרטיס אשראי עם מספר "1234123412341234"
  And החשבון בפיגור קיצוני של 90 ימים
  And יתרה חייבת של 25000.00 שקלים
  When אני שולח בקשת POST ל-'/api/legal/prepare-documentation' עם הנתונים:
    """
    {
      "cardNumber": "1234123412341234",
      "outstandingAmount": 25000.00,
      "daysPastDue": 90,
      "legalAction": "COURT_FILING"
    }
    """
  Then סטטוס התגובה צריך להיות 201
  And התגובה צריכה להכיל "legalDocumentationPrepared": true
  And התגובה צריכה להכיל "lastFourDigits": "1234"
  And התגובה צריכה להכיל "documentId"
  And התגובה צריכה להכיל "legalActionType": "COURT_FILING"
  And התגובה לא צריכה לחשוף מספר כרטיס מלא

Scenario: אבטחת מספר כרטיס אשראי - בדיקה שלילית
  Given כרטיס אשראי עם מספר "4444333322221111"
  When אני שולח בקשת GET ל-'/api/cards/4444333322221111/details'
  Then סטטוס התגובה צריך להיות 200
  And התגובה צריכה להכיל "lastFourDigits": "1111"
  And התגובה לא צריכה להכיל "4444333322221111"
  And התגובה לא צריכה להכיל "cardNumber"
  And התגובה לא צריכה לחשוף מספר כרטיס מלא בשום שדה

Scenario: ביצועי שליחת הודעות המוניות
  Given 1000 כרטיסי אשראי פעילים במערכת
  And כל הכרטיסים עם תאריך פירעון זהה בעוד 3 ימים
  When אני שולח בקשת POST ל-'/api/reminders/bulk-send' עם הנתונים:
    """
    {
      "dueDate": "2024-01-15",
      "batchSize": 1000
    }
    """
  Then סטטוס התגובה צריך להיות 202
  And התגובה צריכה להכיל "batchProcessingStarted": true
  And התגובה צריכה להכיל "estimatedCompletionTime"
  When אני שולח בקשת GET ל-'/api/reminders/batch-status' אחרי 30 דקות
  Then סטטוס התגובה צריך להיות 200
  And התגובה צריכה להכיל "successRate" גדול מ-99
  And התגובה צריכה להכיל "completedWithin30Minutes": true

Scenario: אבטחת נתונים בתהליך הגבייה
  Given מערכת גבייה פעילה
  When אני שולח בקשת GET ל-'/api/security/encryption-status'
  Then סטטוס התגובה צריך להיות 200
  And התגובה צריכה להכיל "databaseEncryption": "ENABLED"
  And התגובה צריכה להכיל "communicationEncryption": "TLS_1.3"
  And התגובה צריכה להכיל "accessControlEnabled": true
  When אני שולח בקשת GET ל-'/api/security/audit-log'
  Then סטטוס התגובה צריך להיות 200
  And התגובה צריכה להכיל רשומות ביקורת לכל פעולות הגבייה
  And התגובה לא צריכה לחשוף מספרי כרטיסי אשראי מלאים

Scenario: זמינות המערכת בתהליכי גבייה אינטנסיביים
  Given מערכת גבייה פעילה
  When אני שולח 100 בקשות POST במקביל ל-'/api/collection/process' עם נתונים שונים
  Then כל התגובות צריכות להתקבל תוך 3 שניות
  And לפחות 99% מהבקשות צריכות להחזיר סטטוס 200
  When אני שולח בקשת GET ל-'/api/system/health'
  Then סטטוס התגובה צריך להיות 200
  And התגובה צריכה להכיל "systemAvailability" גדול מ-99.9
  And התגובה צריכה להכיל "averageResponseTime" קטן מ-3000

Scenario: בדיקת שגיאה - כרטיס לא קיים
  Given מספר כרטיס לא קיים "0000000000000000"
  When אני שולח בקשת POST ל-'/api/reminders/payment' עם הנתונים:
    """
    {
      "cardNumber": "0000000000000000",
      "dueDate": "2024-01-15",
      "amount": 1500.00
    }
    """
  Then סטטוס התגובה צריך להיות 404
  And התגובה צריכה להכיל "error": "CARD_NOT_FOUND"
  And התגובה צריכה להכיל "message": "כרטיס האשראי לא נמצא במערכת"

Scenario: בדיקת שגיאה - נתונים חסרים
  When אני שולח בקשת POST ל-'/api/reminders/payment' עם נתונים חסרים:
    """
    {
      "cardNumber": "1234567890123456"
    }
    """
  Then סטטוס התגובה צריך להיות 400
  And התגובה צריכה להכיל "error": "MISSING_REQUIRED_FIELDS"
  And התגובה צריכה להכיל "missingFields": ["dueDate", "amount"]
