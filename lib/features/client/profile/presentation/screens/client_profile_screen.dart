import 'package:flutter/material.dart';

import '../../../../../core/config/app_build.dart';
import '../../../../../core/di.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../shared/actions/logout_action.dart';
import '../../../../../shared/widgets/gradient_header.dart';
import '../../../../../shared/widgets/media_picker.dart';
import '../../../../../theme/app_colors.dart';
import './client_edit_profile_screen.dart';

/// Passenger profile tab: identity + photo in the header, his data in a card,
/// and the account actions (change password, logout). Mirrors the approved
/// mock-up; the fields are the same the affiliate shows because they come from
/// the SAME `users` table.
class ClientProfileScreen extends StatefulWidget {
  final Client client;

  /// The shell owns the client; this reports edits (data, photo) back.
  final ValueChanged<Client> onClientChanged;

  const ClientProfileScreen({
    super.key,
    required this.client,
    required this.onClientChanged,
  });

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _repository = Dependencies.instance.clientAuthRepository;
  bool _photoBusy = false;

  Future<void> _openEdit({bool changePassword = false}) async {
    final updated = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (_) => ClientEditProfileScreen(
          client: widget.client,
          openPasswordSection: changePassword,
        ),
      ),
    );
    if (updated != null && mounted) widget.onClientChanged(updated);
  }

  /// Picks a photo and replaces the profile one. The backend answers with the
  /// fresh signed URL, so the header repaints without reloading the session.
  Future<void> _changePhoto() async {
    final image = await pickPhoto(context);
    if (image == null || !mounted) return;
    setState(() => _photoBusy = true);
    try {
      final url = await _repository.uploadProfilePhoto(image);
      if (mounted) widget.onClientChanged(widget.client.copyWith(photoUrl: url));
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('No se pudo actualizar tu foto. Intenta de nuevo.');
    }
    if (mounted) setState(() => _photoBusy = false);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    return Column(
      children: [
        _header(client),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _sectionLabel('Tus datos'),
              const SizedBox(height: 8),
              _dataCard(client),
              const SizedBox(height: 20),
              _sectionLabel('Tu cuenta'),
              const SizedBox(height: 8),
              _accountCard(),
              const SizedBox(height: 24),
              // Which build is installed: a bug reported without it costs a
              // round trip figuring out whether the fix was even in his hands.
              if (AppBuild.label.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'EDV Route ${AppBuild.label}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(Client client) {
    return GradientHeader(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Image(image: AssetImage('assets/images/edv_logo_gold.png'), height: 28),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openEdit(),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                  label: const Text(
                    'Editar',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: Colors.white24,
                    shape: const StadiumBorder(),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _avatar(client),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (client.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Cliente desde ${formatMonthYear(client.createdAt!)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(Client client) {
    final avatar = CircleAvatar(
      radius: 30,
      backgroundColor: AppColors.gold,
      foregroundImage: client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
      child: Text(
        _initials(client),
        style: const TextStyle(
          color: AppColors.primary950,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
    return GestureDetector(
      onTap: _photoBusy ? null : _changePhoto,
      child: Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.gold400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: _photoBusy
                  ? const SizedBox(
                      height: 11,
                      width: 11,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary900),
                    )
                  : const Icon(Icons.photo_camera, size: 11, color: AppColors.primary900),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(Client client) {
    final parts = client.fullName.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted),
      );

  Widget _dataCard(Client client) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Column(
        children: [
          _dataRow(Icons.person_outline, 'Nombre completo', client.fullName),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _dataRow(Icons.mail_outline, 'Correo', client.email ?? '—'),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _dataRow(Icons.phone_outlined, 'Teléfono', _displayPhone(client.phone)),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _dataRow(Icons.place_outlined, 'Dirección', client.address ?? '—'),
        ],
      ),
    );
  }

  /// `+584121234567` → `+58 412 123 4567`. Anything with another shape is
  /// shown as stored rather than mangled.
  String _displayPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '—';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 12 || !digits.startsWith('58')) return phone;
    return '+58 ${digits.substring(2, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}';
  }

  Widget _dataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Column(
        children: [
          _actionRow(
            icon: Icons.lock_outline,
            label: 'Cambiar mi clave',
            onTap: () => _openEdit(changePassword: true),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _actionRow(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            destructive: true,
            onTap: () => performClientLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? AppColors.primary : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 18, color: destructive ? AppColors.primary : AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: destructive ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (!destructive)
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
