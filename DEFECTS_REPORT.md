# تقرير العيوب والمشاكل في مشروع Learnmate AI

بعد فحص المشروع، تم تحديد المشاكل التالية التي يجب معالجتها قبل الرفع على متجر Google Play:

## 1. الهوية والمعرفات (Identity & Identifiers)
*   **اسم الحزمة (Package Name):** المشروع لا يزال يستخدم الاسم الافتراضي `com.example.learnmate_ai`. هذا الاسم غير مقبول على متجر Google Play ويجب تغييره إلى معرف فريد (مثل `com.learnmate.app`).
*   **اسم التطبيق (App Label):** يظهر الاسم في نظام أندرويد كـ `learnmate_ai` بينما يفضل أن يكون `Learnmate AI`.
*   **أيقونة التطبيق (App Icon):** التطبيق يستخدم أيقونة Flutter الافتراضية.

## 2. الأمن والإعدادات (Security & Configuration)
*   **مفاتيح API (API Keys):** توجد مفاتيح API في ملف `lib/core/api_constants.dart` كقوالب نصية (`YOUR_..._HERE`). يجب نقل هذه المفاتيح لتُمرر عبر بيئة التشغيل (Environment Variables) لضمان الأمان.
*   **إعدادات التوقيع (Signing Configuration):** ملف `android/app/build.gradle.kts` مهيأ لاستخدام مفاتيح التصحيح (debug keys) حتى في وضع الإصدار (release). يجب إعداد توقيع رسمي.

## 3. الصلاحيات والموارد (Permissions & Resources)
*   **الصلاحيات (Permissions):** يحتاج التطبيق للتأكد من وجود صلاحيات الوصول للإنترنت، التخزين (عند استخدام `image_picker` أو `file_picker`) وغيرها بشكل صريح وصحيح في `AndroidManifest.xml`.
*   **إصدار التطبيق (Version):** إصدار التطبيق لا يزال `1.0.0+1`.

## 4. الكود والجودة (Code Quality)
*   يوجد ملفات تجريبية في الجذر مثل `test_fal.dart` يجب مراجعتها أو حذفها.
*   الحاجة للتأكد من تفعيل R8/ProGuard لتقليل حجم التطبيق وحماية الكود.
