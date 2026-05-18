class StaffModel {
  final String id;
  final String userId;
  final String employeeId;
  final String? phone;
  final String? address;
  final DateTime? joiningDate;
  final String? department;
  final String shift;
  // From user join
  final String? userName;
  final String? userEmail;
  final String? userRole;

  const StaffModel({
    required this.id,
    required this.userId,
    required this.employeeId,
    this.phone,
    this.address,
    this.joiningDate,
    this.department,
    this.shift = 'morning',
    this.userName,
    this.userEmail,
    this.userRole,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      joiningDate: json['joining_date'] != null
          ? DateTime.tryParse(json['joining_date'].toString())
          : null,
      department: json['department']?.toString(),
      shift: json['shift']?.toString() ?? 'morning',
      userName: json['name']?.toString(),
      userEmail: json['email']?.toString(),
      userRole: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'employee_id': employeeId,
        'phone': phone,
        'address': address,
        'joining_date': joiningDate?.toIso8601String(),
        'department': department,
        'shift': shift,
      };

  String get roleLabel {
    switch (userRole) {
      case 'admin': return 'Admin';
      case 'manager': return 'Manager';
      case 'receptionist': return 'Receptionist';
      case 'housekeeping': return 'Housekeeping';
      default: return userRole ?? '';
    }
  }

  String get shiftLabel {
    switch (shift) {
      case 'morning': return 'Morning';
      case 'evening': return 'Evening';
      case 'night': return 'Night';
      default: return shift;
    }
  }
}
