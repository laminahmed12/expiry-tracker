# ADREEMK Licensing Backend

هذا الجزء خاص بنظام الترخيص.

## Cloudflare
1. أنشئ D1 باسم adreemk-licensing.
2. نفّذ backend/schema.sql في Console.
3. أنشئ Worker باسم adreemk-licensing.
4. ضع backend/src/worker.js في Worker.
5. أضف D1 Binding باسم DB.
6. أضف Secret باسم ADMIN_API_KEY.
7. عدّل database_id في wrangler.toml عند استخدام Wrangler.

## ملاحظة أمنية
ADMIN_API_KEY لا يوضع داخل تطبيق Flutter. يستخدم فقط من لوحة الإدارة/الخادم.
