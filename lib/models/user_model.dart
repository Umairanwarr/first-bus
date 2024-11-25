class UserModel {
  final String name;
  final String email;
  final String phone;
  final String userType;
  final String busNumber;
  final String busColor;
  final String universityName;
  final String profileImageUrl;
  final String? licenseImageUrl;
  final int? role;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.busNumber,
    required this.busColor,
    required this.universityName,
    required this.profileImageUrl,
    this.licenseImageUrl,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['userType'] ?? '',
      busNumber: json['busNumber'] ?? '',
      busColor: json['busColor'] ?? '',
      universityName: json['universityName'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      licenseImageUrl: json['licenseImageUrl'],
      role: json['role'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'busNumber': busNumber,
      'busColor': busColor,
      'universityName': universityName,
      'profileImageUrl': profileImageUrl,
      'licenseImageUrl': licenseImageUrl,
    };
    
    if (userType == 'Driver') {
      data['role'] = role ?? 0;
    }
    
    return data;
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? userType,
    String? busNumber,
    String? busColor,
    String? universityName,
    String? profileImageUrl,
    String? licenseImageUrl,
    int? role,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      busNumber: busNumber ?? this.busNumber,
      busColor: busColor ?? this.busColor,
      universityName: universityName ?? this.universityName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      role: role ?? this.role,
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      userType: data['userType'],
      busNumber: data['busNumber'],
      busColor: data['busColor'],
      universityName: data['universityName'],
      profileImageUrl: data['profileImageUrl'],
      licenseImageUrl: data['licenseImageUrl'],
      role: data['role'] ?? 0,
    );
  }
}
