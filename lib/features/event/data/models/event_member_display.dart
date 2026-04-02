/// نموذج لعرض مشارك في تفاصيل الحدث (الاسم الأول، الثاني، صورة، قسم، مدير/أدمن)
/// يتوافق مع استجابة API: id, first_name, last_name, full_name, email, image, department, is_manager, is_admin
class EventMemberDisplay {
  final int id;
  final String firstName;
  final String lastName;
  final String? image;
  final String? departmentName;
  final bool isManager;
  final bool isAdmin;

  const EventMemberDisplay({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.image,
    this.departmentName,
    this.isManager = false,
    this.isAdmin = false,
  });

  /// الاسم الكامل للعرض (full_name أو first + last)
  String get name {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty && last.isEmpty) return '—';
    return '$first $last'.trim();
  }

  static bool _isTrue(dynamic v) =>
      v == true || v == 1 || v?.toString() == '1' || (v?.toString().toLowerCase() == 'true');

  factory EventMemberDisplay.fromJson(Map<String, dynamic> json) {
    final first = (json['first_name']?.toString() ?? '').trim();
    final last = (json['last_name']?.toString() ?? '').trim();
    final dep = json['department'];
    String deptName = '';
    if (dep is Map) {
      deptName = (dep['name']?.toString() ?? '').trim();
      if (deptName.isEmpty) deptName = (dep['department_name']?.toString() ?? '').trim();
    } else if (dep != null) {
      deptName = dep.toString().trim();
    }
    if (deptName.isEmpty && json['department_name'] != null) {
      deptName = json['department_name'].toString().trim();
    }
    // مدير: من الجذر (is_manager / is_manager_department) أو من department.is_manager_department — مثل UserModel و Department
    final isManagerRoot = _isTrue(json['is_manager']) || _isTrue(json['is_manager_department']);
    bool isManagerDept = false;
    if (dep is Map) {
      isManagerDept = _isTrue(dep['is_manager_department']);
    }
    final isManager = isManagerRoot || isManagerDept;
    final isAdmin = _isTrue(json['is_admin']);

    return EventMemberDisplay(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      firstName: first,
      lastName: last,
      image: json['image']?.toString(),
      departmentName: deptName.isEmpty ? null : deptName,
      isManager: isManager,
      isAdmin: isAdmin,
    );
  }

  EventMemberDisplay copyWith({
    String? firstName,
    String? lastName,
    String? image,
    String? departmentName,
    bool? isManager,
    bool? isAdmin,
  }) =>
      EventMemberDisplay(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        image: image ?? this.image,
        departmentName: departmentName ?? this.departmentName,
        isManager: isManager ?? this.isManager,
        isAdmin: isAdmin ?? this.isAdmin,
      );
}
