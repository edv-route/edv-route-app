/// Registration payload for `POST /client-auth/register`: personal data +
/// privacy consent. The backend rejects any extra field
/// (`additionalProperties: false`), so only what the form collects travels.
class ClientRegisterRequest {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? secondLastName;
  final String email;
  final String? phone;
  final String password;
  final bool acceptedPrivacy;

  const ClientRegisterRequest({
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.secondLastName,
    required this.email,
    this.phone,
    required this.password,
    required this.acceptedPrivacy,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        if (middleName != null && middleName!.isNotEmpty) 'middleName': middleName,
        'lastName': lastName,
        if (secondLastName != null && secondLastName!.isNotEmpty) 'secondLastName': secondLastName,
        'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        'password': password,
        'acceptedPrivacy': acceptedPrivacy,
      };
}
