import 'package:get/get.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:mow_events/core/utils/local_storage/storage_keys.dart';
import 'package:mow_events/features/auth/data/models/registration_submission_snapshot.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/data/models/user_registration_data.dart';
import 'package:mow_events/features/auth/domin/entities/registration_approval_status.dart';

class RegistrationApprovalService {
  static final AppLocalStorage _storage = Get.find<AppLocalStorage>();

  static RegistrationApprovalStatus get status =>
      RegistrationApprovalStatusStorage.fromStorage(
        _storage.read<String>(StorageKeys.registrationApprovalStatus),
      );

  static String? get rejectionReason =>
      _storage.read<String>(StorageKeys.registrationRejectionReason);

  static RegistrationSubmissionSnapshot? get snapshot {
    final raw = _storage.read<Map>(StorageKeys.registrationSubmissionSnapshot);
    if (raw == null) return null;
    return RegistrationSubmissionSnapshot.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }

  static bool get isAwaitingApproval =>
      status == RegistrationApprovalStatus.pending ||
      status == RegistrationApprovalStatus.rejected;

  /// هل يجب عرض شاشة انتظار التسجيل (وليس الهوم أو حوار إلغاء التفعيل).
  static bool shouldHoldRegistrationApproval(UserModel? user) {
    if (user != null) {
      final reg = user.registrationData;

      if (reg.isPending || reg.isRejected) return true;

      // موظف مفعّل أو مُوافَق عليه — لا نعود لشاشة الانتظار بسبب تخزين قديم.
      if (user.isActive || reg.isApproved) return false;

      // إيقاف تفعيل من الإدارة — ليس انتظار موافقة على التسجيل.
      if (user.isDeactivatedAccount) return false;

      if (user.requiresRegistrationApproval) return true;
    }

    return user == null && isAwaitingApproval;
  }

  /// يمسح حالة انتظار التسجيل المحفوظة إذا لم تعد مطابقة للمستخدم الحالي.
  static Future<void> reconcileLocalStateWithUser(UserModel? user) async {
    if (!shouldHoldRegistrationApproval(user) && isAwaitingApproval) {
      await clear();
    }
  }

  static RegistrationSubmissionSnapshot snapshotFromUser(UserModel user) {
    return RegistrationSubmissionSnapshot(
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      departmentId: user.department?.id ?? 0,
      departmentName: user.department?.name ?? '',
      isManager: user.isManager,
    );
  }

  static Future<void> syncFromUser(UserModel user) async {
    final submission = snapshotFromUser(user);
    final reg = user.registrationData;
    final localStatus = status;

    if (localStatus == RegistrationApprovalStatus.rejected &&
        !reg.isRejected) {
      await _storage.write(
        StorageKeys.registrationSubmissionSnapshot,
        submission.toJson(),
      );
      return;
    }

    if (reg.isRejected) {
      final profileReason = reg.displayRejectionReason;
      final storedReason = rejectionReason?.trim();
      final effective = (profileReason != null && profileReason.isNotEmpty)
          ? profileReason
          : (storedReason ?? '');
      await markRejected(effective);
      await _storage.write(
        StorageKeys.registrationSubmissionSnapshot,
        submission.toJson(),
      );
      return;
    }

    if (reg.isPending) {
      await markPending(submission);
      return;
    }

    if (user.requiresRegistrationApproval) {
      await markPending(submission);
      return;
    }

    await clear();
  }

  /// بعد إعادة إرسال طلب التسجيل — إعادة الحالة إلى «قيد المراجعة» ومسح الرفض السابق.
  static Future<UserModel> applyPendingAfterResubmit(UserModel user) async {
    final submission = snapshotFromUser(user);
    await markPending(submission);

    final updated = user.copyWith(
      registrationData: const UserRegistrationData(registerStatus: 'pending'),
    );
    return updated;
  }

  static Future<void> markPending(
    RegistrationSubmissionSnapshot submission,
  ) async {
    await _storage.write(
      StorageKeys.registrationApprovalStatus,
      RegistrationApprovalStatus.pending.storageValue,
    );
    await _storage.remove(StorageKeys.registrationRejectionReason);
    await _storage.write(
      StorageKeys.registrationSubmissionSnapshot,
      submission.toJson(),
    );
  }

  static Future<void> markRejected(String reason) async {
    await _storage.write(
      StorageKeys.registrationApprovalStatus,
      RegistrationApprovalStatus.rejected.storageValue,
    );
    if (reason.trim().isEmpty) {
      await _storage.remove(StorageKeys.registrationRejectionReason);
    } else {
      await _storage.write(
        StorageKeys.registrationRejectionReason,
        reason.trim(),
      );
    }
  }

  static Future<void> clear() async {
    await _storage.remove(StorageKeys.registrationApprovalStatus);
    await _storage.remove(StorageKeys.registrationRejectionReason);
    await _storage.remove(StorageKeys.registrationSubmissionSnapshot);
  }
}
