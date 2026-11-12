import 'package:flutter/material.dart';

import '../../../../domain/entities/identity.dart';
import '../../../../domain/repositories/identity_repository.dart';
import '../controllers/identity_flow_controller.dart';
import '../screens/identity_photos_screen.dart';

/// Stands in front of the app for someone who owes identity photos
/// (decision by Luis, 2026-11-12: everybody already registered must send them
/// — inscribed at the office included — and a rejected one is retaken).
///
/// Missing or rejected photos stop the person HERE, before anything else, and
/// he can fix it right away from the phone; in review or approved lets him
/// through. It fails OPEN: if the server cannot be reached the app goes on —
/// every rule that matters is enforced by the server anyway, and an offline
/// check must not lock someone out of paying what he owes.
class IdentityGate extends StatefulWidget {
  const IdentityGate({
    super.key,
    required this.repository,
    required this.isDriver,
    required this.onLogout,
    required this.child,
  });

  final IdentityRepository repository;

  /// Decides the wording: an affiliate stops WORKING without them.
  final bool isDriver;
  final Future<void> Function(BuildContext context) onLogout;
  final Widget child;

  @override
  State<IdentityGate> createState() => _IdentityGateState();
}

class _IdentityGateState extends State<IdentityGate> {
  bool _checking = true;
  IdentityFlowController? _flow;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _flow?.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    IdentityView? view;
    try {
      view = await widget.repository.load();
    } catch (_) {
      view = null; // fail open
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (view != null && view.status.needsAction) {
        _flow = IdentityFlowController(repository: widget.repository, initial: view);
      }
    });
  }

  void _pass() {
    final flow = _flow;
    setState(() => _flow = null);
    flow?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final flow = _flow;
    if (flow == null) return widget.child;

    final rejected = flow.view.status == IdentityStatus.rejected;
    return IdentityPhotosScreen(
      controller: flow,
      title: rejected ? 'Tu identidad' : 'Completa tu verificación',
      highlight: rejected ? 'identidad' : 'verificación',
      subtitle: rejected
          ? 'Revisión de la oficina'
          : widget.isDriver
              ? 'Un paso más para seguir trabajando'
              : 'Un paso más para seguir usando EDV Route',
      intro: rejected ? 'La oficina pidió que tomes de nuevo una de tus fotos. Mira el motivo y tómala otra vez.' : null,
      notice: rejected ? null : _notice(flow.view.required),
      footnote: !rejected && widget.isDriver
          ? 'Si te inscribieron en la oficina, también te las pedimos aquí: la oficina las revisa y te avisamos.'
          : null,
      submitLabel: 'Enviar fotos',
      canGoBack: false,
      onLogout: () => widget.onLogout(context),
      onSubmitted: (_) => _pass(),
    );
  }

  /// Honest about the rule: while the office has not switched it on, the
  /// photos do not stop him from working yet — saying otherwise would be false.
  String _notice(bool required) {
    if (!widget.isDriver) {
      return 'Ahora pedimos tu foto y tu cédula a todos los pasajeros: le dan confianza al afiliado que te lleva. Toma un minuto.';
    }
    return required
        ? 'Ahora pedimos tu foto y tu cédula a todos los afiliados. Hasta que la oficina las apruebe no podrás activarte para trabajar.'
        : 'Ahora pedimos tu foto y tu cédula a todos los afiliados. Pronto serán obligatorias para trabajar: envíalas ya y evita quedar en pausa.';
  }
}
