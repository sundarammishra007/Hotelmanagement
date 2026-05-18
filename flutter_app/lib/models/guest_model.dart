enum IdProofType { aadhar, passport, driving_license, voter_id }

class GuestModel {
  final String id;
  final String name;
  final String? email;
  final String phone;
  final String? address;
  final IdProofType? idProofType;
  final String? idProofNumber;
  final String? idProofImageUrl;
  final String? nationality;
  final DateTime? createdAt;

  const GuestModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.address,
    this.idProofType,
    this.idProofNumber,
    this.idProofImageUrl,
    this.nationality,
    this.createdAt,
  });

  factory GuestModel.fromJson(Map<String, dynamic> json) {
    return GuestModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString(),
      idProofType: _parseIdProofType(json['id_proof_type']?.toString()),
      idProofNumber: json['id_proof_number']?.toString(),
      idProofImageUrl: json['id_proof_image_url']?.toString(),
      nationality: json['nationality']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static IdProofType? _parseIdProofType(String? s) {
    switch (s) {
      case 'aadhar': return IdProofType.aadhar;
      case 'passport': return IdProofType.passport;
      case 'driving_license': return IdProofType.driving_license;
      case 'voter_id': return IdProofType.voter_id;
      default: return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'id_proof_type': idProofType?.name,
        'id_proof_number': idProofNumber,
        'id_proof_image_url': idProofImageUrl,
        'nationality': nationality,
      };

  String get idProofLabel {
    switch (idProofType) {
      case IdProofType.aadhar: return 'Aadhar Card';
      case IdProofType.passport: return 'Passport';
      case IdProofType.driving_license: return 'Driving License';
      case IdProofType.voter_id: return 'Voter ID';
      default: return 'N/A';
    }
  }
}
