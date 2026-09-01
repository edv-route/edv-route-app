/// Registration payload for `POST /client-auth/register`: the SAME fields the
/// affiliate registration asks for (decision by Luis, 2026-08-31) — only
/// middle name, second last name and address are optional. The backend rejects
/// any extra field (`additionalProperties: false`).
class ClientRegisterRequest {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? secondLastName;
  final String birthDate;
  final String nationalId;
  final String phone;
  final String email;
  final String? address;
  final String password;
  final bool acceptedPrivacy;

  const ClientRegisterRequest({
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.secondLastName,
    required this.birthDate,
    required this.nationalId,
    required this.phone,
    required this.email,
    this.address,
    required this.password,
    required this.acceptedPrivacy,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        if (middleName != null && middleName!.isNotEmpty) 'middleName': middleName,
        'lastName': lastName,
        if (secondLastName != null && secondLastName!.isNotEmpty) 'secondLastName': secondLastName,
        'birthDate': birthDate,
        'nationalId': nationalId,
        'phone': phone,
        'email': email,
        if (address != null && address!.isNotEmpty) 'address': address,
        'password': password,
        'acceptedPrivacy': acceptedPrivacy,
      };
}
