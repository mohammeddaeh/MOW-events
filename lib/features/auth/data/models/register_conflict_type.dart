/// نوع تعارض عند إنشاء حساب (بريد/هاتف مستخدم أو حساب قيد المراجعة).
enum RegisterConflictType {
  emailTaken,
  emailPendingReview,
  phoneTaken,
}
