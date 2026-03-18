Feature: בדיקות מערכת גביה – התראות, הודעות, הרשאות ותיעוד עם הצגת 4 ספרות אחרונות בלבד

  # רקע כללי – קביעת API base url והרשאות משתמש
  Background:
    Given מערכת הבנק מחוברת לכתובת הבסיס: "https://api.bank.local"
    And כל הפלטפורמות (אימייל, SMS, UI, סוכנות גביה) זמינות ופעילות
    And מוגדרת הרשאת גישה מתאימה (מחזיק כרטיס/מנהל/גבּאי/סוכנות/משפטי)
    And כלל המערכות עומדות בתקן PCI DSS ומנגנון audit מופעל

  # API Tests – שליחת הודעות גביה/תזכורת/גביה/agency/legal עם הצגה רק של 4 ספרות אחרונות
  @api
  Scenario Outline: שליחת התראה/הודעה/מסמך ללקוח – רק 4 ספרות מוצגות, אין חשיפת PII❌
    Given למשתמש עם חשבון במצב "<workflowStage>" וסטטוס "<accountStatus>" במערכת
    And מספר הכרטיס הרשום במערכת הוא "<cardNumber>" (בדיקות edge – קצר, תקין, חריג)
    And יתרה: <balance> ₪, חובות נלווים: <additionalCharges> ₪
    When נשלחת בקשת API מסוג <method> ל-endpoint "<endpoint>" עם נתוני ההודעה:
      """
      {
        "userId": "<userId>",
        "last4": "<last4>",
        "amount": <balance>,
        "additionalCharges": <additionalCharges>,
        "notificationType": "<notificationType>",
        "channel": "<channel>"
      }
      """
    Then הסטטוס של התגובה צריך להיות <expectedStatus>
    And התוכן בכל ערוץ יכיל רק את הספרות: "<last4>"
    And תגובת ה-API אינה מכילה מספר כרטיס מלא או PII רגיש
    And כל הפעולה/הודעה תירשם ב-audit trail על פי שלב "<workflowStage>"
    And במערכת ניתן לבצע rollback או שחזור בתרחיש כשל של תהליך/הודעה
    And במקרה של reversal או תשלום – תישלח הודעה חדשה ותעודכן ההיסטוריה

    Examples:
      | workflowStage           | accountStatus    | cardNumber           | last4 | balance | additionalCharges | method | endpoint                          | userId        | notificationType                 | channel        | expectedStatus |
      | Reminder                | Active           | 123456******7890     | 7890  | 542.34  | 0                 | POST   | /api/notifications/reminder        | usr-111       | תזכורת מועד פירעון              | SMS            | 200           |
      | Overdue                 | Overdue          | 887763******9451     | 9451  | 1120.00 | 0                 | POST   | /api/notifications/overdue         | usr-222       | התראת יתרה שלא נפרעה            | EMAIL          | 200           |
      | Collection              | In collection    | 554488******1122     | 1122  | 3070.02 | 175.8             | POST   | /api/notifications/collection      | usr-333       | הודעת גביה רשמית                 | APP            | 201           |
      | Payment Plan Proposal   | Collection       | 442211******9865     | 9865  | 5280.00 | 88.45             | POST   | /api/notifications/payment-plan    | usr-444       | הצעת מסלול תשלום                 | EMAIL          | 201           |
      | Agency                  | Escalated        | 990088******1234     | 1234  | 15600   | 533.88            | POST   | /api/agency/transfer               | usr-333       | העברה לסוכנות גביה וסמך משפטי    | AGC_API        | 200           |
      | Legal Action            | Legal            | 478532******4444     | 4444  | 100000  | 9900.0            | POST   | /api/legal/documents               | usr-777       | מסמך משפטי בגביה                 | API_DOC        | 200           |
      | Reminder                | Active           | 12INVALID            | 12    | 560.5   | 0                 | POST   | /api/notifications/reminder        | usr-999       | תזכורת מועד פירעון               | SMS            | 400           |
      | Collection              | Collection       |                      |       | -200.0  | 0                 | POST   | /api/notifications/collection      | usr-000       | הודעת גביה רשמית                 | EMAIL          | 400           |

  # UI Tests – בדיקות מסכים, הרשאות ותצוגת 4 ספרות בלבד
  @ui
  Scenario Outline: בדיקת הצגת הודעות, מסמכים, והיסטוריה בממשק – רק 4 ספרות, הרשאות מתעדכנות
    Given אני מחובר כ-<userRole> במערכת הגביה במסך "<uiScreen>"
    When אני ניגש למסך "<notificationScreen>" או למסמך "<documentName>"
    And בוחר הודעה מסוג "<notificationType>" עבור מזהה לקוח <userId>
    Then במסך/מסמך מופיעות רק ה-4 ספרות האחרונות "<last4>" של הכרטיס
    And אין אף הופעה של מספר כרטיס מלא או PII נוסף
    And לוג audit מציג את הפעולה "<auditActionName>" והשינוי התיעודתי
    And אם אני מנסה גישה חריגה – מוצגת שגיאת הרשאה והנסיון נרשם ביומן
    And אם יש reversal (כמו תשלום) – תוצג הודעה תקפה בלבד ותעודכן היסטוריית התשלומים

    Examples:
      | userRole         | uiScreen       | notificationScreen      | documentName       | notificationType                   | userId  | last4 | auditActionName              |
      | מחזיק כרטיס     | הודעות         | לוח התראות              | מסמך גביה_1234.pdf | תזכורת מועד פירעון                | u-1     | 1234  | יצירת/פתיחת התראה           |
      | גבּאי            | גביה           | גביה פעילה              | הזמנה לתשלום_9865.pdf | הודעת גביה רשמית               | u-4     | 9865  | שליחת הודעת גביה            |
      | מנהל מערכת      | היסטוריית תשלומים| מסך יתרה               | מסמך מסלול_4444.pdf   | הצעת מסלול תשלום               | u-7     | 4444  | עדכון יתרה/סטטוס            |
      | סוכנות גביה      | סיכום          | מעקב סוכנות             | מסמך agency_1234.pdf   | העברה לסוכנות גביה וסמך משפטי  | u-3     | 1234  | אישור handoff לפעולה סוכנות |
      | עו"ד            | משפטי          | תיק משפטי               | מסמך משפטי_4444.pdf    | מסמך משפטי בגביה               | u-7     | 4444  | חתימה דיגיטלית              |

  # API & UI – בדיקות גבולות, שלילה, חריגים, rollback
  @api @ui
  Scenario Outline: בדיקת ערכי יתרה קצה, חריגות ותיקון – תיעוד, מדיניות רגולטורית
    Given חשבון במצב גביה עם יתרה <balance> ₪, סטטוס "<stage>", ספרות אחרונות "<last4>"
    When מוזנת בקשת גביה לערוץ <sendTo> (API/ UI) עם יתרה כפי שנמסר
    Then אם הערך "<balance>" מינימום/אפס – לא תשלח הודעה; ביומן מתועד דחייה תקנית
    And אם הערך חריג (מעל מקסימום/שלילי) – מוצגת התראת חריגה רק עם <last4>
    And אם נוצרה חריגה – תעודכן בלוג השגיאות ו-block/הפסקה תועדו באאודיט
    And כל הודעה (UI, אימייל, SMS) עומדת ברגולציה ורק 4 ספרות מוצגות
    And תהליך rollback לתיקון יתרה יעדכן audit trail וימנע חשיפת מספר מלא

    Examples:
      | balance | stage         | last4 | sendTo    |
      | 0       | Reminder      | 7890  | UI        |
      | 990000  | Collection    | 1122  | API       |
      | -10     | Agency        | 1234  | UI        |

  # API – בדיקת תהליך reversal ועדכון התראות/סטטוס בכל מחזור
  @api
  Scenario Outline: reversal מחזורי והפקת הודעות/סטטוס חדשות ועדכון audit
    Given חשבון עם סטטוס "<stage>" וגישה ל-API עדכון תשלום/הודעה
    And המשתמש הוא "<userRole>" עם הרשאות רלוונטיות
    When מבוצע תשלום מסוג <paymentType> (חלקי/מלא) דרך "<channel>"
    Then נרשם reversal ביומן, התראות קודמות מוסרות/מעודכנות, ונשלחת הודעה חדשה (רק 4 ספרות "<last4>")
    And audit trail מתעד כל שלב, התשלומים הקודמים ופעולות rollback במידה וישנן
    And כלל הערוצים/הודעות – אין חשיפת מספר מלא

    Examples:
      | stage       | userRole        | paymentType | channel | last4 |
      | Collection  | מחזיק כרטיס    | מלא        | UI      | 9865  |
      | Agency      | מנהל           | חלקי       | API     | 1234  |
      | Legal       | עו"ד           | reversal   | API     | 4444  |

  # API & UI – כשל בשליחת הודעות, ניסיון תיקון, תיעוד מלא ומניעת חשיפת PII
  @api @ui
  Scenario Outline: בדיקת כשל בשליחת SMS/אימייל, טיפול בשחזור/שליחה מחדש ותצוגה ב-UI
    Given משתמש במצב "<stage>" עם ערוץ הודעה "<channel>" שנכשל
    And ספרות אחרונות מוצגות הן "<last4>" בלבד
    When תהליך שליחה נכשל (שגיאת <errorType>)
    Then במערכת מתועדת טבלת שגיאות (audit log) ומוצגת הודעת שגיאה ב-UI/ממשק מנהל
    And לאחר ניסיון תיקון/שחזור – ההודעה נשלחת (retry) עם רק "<last4>"
    And אין חשיפה של מספר מלא/PII בשום אופן

    Examples:
      | stage      | channel   | last4 | errorType       |
      | Collection | SMS       | 1122  | timeout         |
      | Agency     | EMAIL     | 1234  | address_invalid |
      | Payment    | APP       | 9865  | channel_block   |

  # בדיקות הרשאות משתמשים בכל שלב/מסך/תהליך – מתן גישה, חסימה, rollback, תיעוד
  @ui
  Scenario Outline: הרשאות משתמש ומבנה הרשאות – מי יכול לראות, לאשר, להסלים/לשחזר פעולה
    Given משתמש בתפקיד "<role>" נכנס למסך "<screen>"
    When הוא מנסה לבצע "<action>" עבור תהליך גביה/הודעה לפי שלב "<stage>"
    Then רק אם ההרשאה תקפה תתאפשר פעולה; אחרת מתקבלת שגיאת הרשאה ופעולה מתועדת ב-audit
    And בתצוגה רק 4 ספרות כרטיס – "<last4>" – ואין חשיפת מידע נוסף
    And תיעוד rollback במערכת audit זמין

    Examples:
      | role            | screen        | action               | stage           | last4 |
      | גבּאי           | גביה          | שליחת גביה           | Collection      | 1122  |
      | מנהל מערכת      | הרשאות        | שחזור הרשאה          | Agency          | 1234  |
      | עו"ד            | חוזים משפטיים | חתימה דיגיטלית       | Legal Action    | 4444  |
      | מחזיק כרטיס     | הודעות        | צפייה בתשלומים       | Reminder        | 7890  |
      | סוכנות גביה     | לוח סוכנות    | קבלת תיק מלקוח       | Agency          | 1234  |
      | מחזיק כרטיס     | הודעות        | פעולה לא מורשית      | Collection      | 9865  |

  # API – עדכון (refresh/overwrite) פרטי כרטיס במהלך מחזור גביה
  @api
  Scenario Outline: עדכון/החלפת כרטיס – תיעוד שינוי, הצגת רק 4 ספרות מעודכנות בכל הודעה וללא חשיפת ישן
    Given חשבון עם סטטוס "<stage>" ו-cardId "<oldCardLast4>" 
    When מבוצע עדכון פרטי כרטיס ל- "<newCardLast4>" 
    Then בכל בקשת הודעה/היסטוריה / תיעוד יוצגו רק 4 ספרות אחרונות "<newCardLast4>"
    And השינוי/החלפה מתועדת ביומן audit
    And לא תוצג לעולם ספרה ממספר הכרטיס הישן או מידע רגיש אחר

    Examples:
      | stage         | oldCardLast4 | newCardLast4 |
      | Collection    | 1122         | 5678         |
      | Payment Plan  | 9865         | 1111         |

  # אוטומציה של סריקת תוכן הודעות במסמכים/ערוצים שונים ווידוא 4 ספרות בלבד
  @api @ui
  Scenario Outline: סריקה אוטומטית וידנית – זיהוי חריגות בחשיפה, Block ושחזור
    Given מערכת עם הודעות ו/או מסמכים משויכים ללקוח "<userId>" בערוץ "<channel>"
    When מופעלת סריקת תוכן אוטומטית וסקר ידני לכל ההודעות/מסמכים מסוג "<notificationType>"
    Then כל הודעה/מסמך/מסך/ SMS/אימייל יכיל רק "<last4>" ולא מספר כרטיס מלא
    And אם נמצאה הופעה חריגה – מופעל Block, מתקבל התראה/שגיאה מתועדת בלוג, התהליך משוחזר, וכל הודעות מתוקנות נבדקות מחדש

    Examples:
      | userId | channel         | notificationType                   | last4 |
      | u-1    | אימייל          | תזכורת מועד פירעון                 | 7890  |
      | u-4    | SMS             | התראת יתרה שלא נפרעה               | 9451  |
      | u-7    | PDF             | הצעת מסלול תשלום                   | 4444  |
      | u-3    | API_DOC         | העברה לסוכנות גביה וסמך משפטי      | 1234  |
      | u-8    | APP             | הודעת גביה רשמית                    | 9865  |

  # תרחישי Edge – פיגורים תכופים ומעברי סטטוס מהירים/rollback
  @api @ui
  Scenario Outline: ריבוי פיגורים ומעברי סטטוס מהירים – Escalation, rollback ותיעוד
    Given למשתמש "<userId>" מוגדרת סדרת מועדי פירעון קרובים ומותר פיגור תכוף
    When המערכת רושמת רצף של "<missedPayments>" פיגורים במהירות (בדיקת Escalation מהיר)
    Then בכל מעבר סטטוס/הודעה מוצגות רק 4 ספרות אחרונות "<last4>"
    And כל לוג audit מעודכן לכל תהליך ומעבר, כולל rollback שנעשה
    And בכל ערוץ/הודעה/מסמך – אין חשיפת מספר מלא

    Examples:
      | userId | missedPayments | last4 |
      | u-1    | 3             | 7890  |
      | u-3    | 5             | 1234  |

