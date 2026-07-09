enum RegistrationApprovalStatus { none, pending, rejected }

extension RegistrationApprovalStatusStorage on RegistrationApprovalStatus {
  String get storageValue {
    switch (this) {
      case RegistrationApprovalStatus.none:
        return 'none';
      case RegistrationApprovalStatus.pending:
        return 'pending';
      case RegistrationApprovalStatus.rejected:
        return 'rejected';
    }
  }

  static RegistrationApprovalStatus fromStorage(String? value) {
    switch (value) {
      case 'pending':
        return RegistrationApprovalStatus.pending;
      case 'rejected':
        return RegistrationApprovalStatus.rejected;
      default:
        return RegistrationApprovalStatus.none;
    }
  }
}
