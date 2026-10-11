import 'package:flutter/material.dart';

import '../../../data/repositories/local_group_repository.dart';
import '../../../domain/models/currency.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

/// Pantalla de Configuración con diseño idéntico a las imágenes de referencia.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
    this.onDataCleared,
  });

  final LocalGroupRepository repository;
  final VoidCallback? onDataCleared;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  String _themeMode = 'Usar sistema';
  bool _reduceMotion = false;
  Currency _defaultCurrency = Currency.ars;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.hasClients && _scrollController.offset > 32;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String _formatCurrency(Currency currency) {
    if (currency.code == 'ARS') return 'Pesos argentinos · ARS';
    if (currency.code == 'BRL') return 'Reales brasileños · BRL';
    if (currency.code == 'USD') return 'Dólares estadounidenses · USD';
    return '${currency.name} · ${currency.code}';
  }

  void _selectTheme() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4DBDF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Tema de la app',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11232D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final option in ['Usar sistema', 'Claro', 'Oscuro']) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        option,
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 16,
                          fontWeight: _themeMode == option
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF11232D),
                        ),
                      ),
                      trailing: _themeMode == option
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF0D7E88),
                            )
                          : null,
                      onTap: () {
                        setState(() => _themeMode = option);
                        Navigator.of(context).pop();
                      },
                    ),
                    if (option != 'Oscuro')
                      const Divider(color: Color(0xFFF0F4F6), height: 1),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectCurrency() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4DBDF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Moneda predeterminada',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11232D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Se seleccionará por defecto al crear nuevos grupos.',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 14,
                      color: Color(0xFF586974),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final curr in Currency.supported) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _formatCurrency(curr),
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 16,
                          fontWeight: _defaultCurrency == curr
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF11232D),
                        ),
                      ),
                      trailing: _defaultCurrency == curr
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF0D7E88),
                            )
                          : null,
                      onTap: () {
                        setState(() => _defaultCurrency = curr);
                        Navigator.of(context).pop();
                      },
                    ),
                    const Divider(color: Color(0xFFF0F4F6), height: 1),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DBDF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF0D7E88),
                      size: 26,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Política de privacidad',
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF11232D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gastos Compartidos es una aplicación 100% local (local-first). Todos tus grupos, personas, gastos y cuentas se guardan exclusivamente en la memoria de este dispositivo.',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    height: 1.45,
                    color: Color(0xFF586974),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• No recolectamos información personal ni financiera.\n• No utilizamos rastreadores, cookies ni analíticas invasivas.\n• No enviamos tus datos a servidores externos sin tu consentimiento explícito.',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF586974),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D7E88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmClearData() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4DBDF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDECEB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFBA3D2A),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Borrar todos los datos locales?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF11232D),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Esta acción eliminará de forma permanente todos los grupos, integrantes, gastos y liquidaciones guardados en este dispositivo. Esta acción no se puede deshacer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF586974),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD4DBDF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF586974),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('confirm-clear-data-button'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);
                          nav.pop();
                          await widget.repository.clearAllData();
                          widget.onDataCleared?.call();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Todos los datos fueron eliminados'),
                            ),
                          );
                          nav.pop(true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFBA3D2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Borrar todo',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHowItWorks() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: OnboardingScreen(
            onFinish: () async {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  void _showSupport() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4DBDF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F4F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    color: Color(0xFF0D7E88),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Contactar soporte',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF11232D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Si tenés dudas, sugerencias o encontraste algún inconveniente, podés escribirnos a:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 14,
                    color: Color(0xFF586974),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5ECEE)),
                  ),
                  child: const Text(
                    'soporte@gastoscompartidos.app',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF0D7E88),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D7E88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTermsOfUse() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DBDF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: Color(0xFF0D7E88),
                      size: 26,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Términos de uso',
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF11232D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'El uso de Gastos Compartidos es personal e intransferible. La app está pensada para facilitar la división de gastos y saldos en viajes y salidas grupales.',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    height: 1.45,
                    color: Color(0xFF586974),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Los cálculos y sugerencias de liquidación son informativos y no constituyen asesoramiento financiero ni bancario.',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF586974),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D7E88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Gastos Compartidos',
      applicationVersion: '1.0.0',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Sticky Header with back arrow & optional inline title
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBFB),
                    border: Border(
                      bottom: BorderSide(
                        color: _isScrolled
                            ? const Color(0xFFE2E8EA)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('settings-back-button'),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF11232D),
                          size: 26,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      if (_isScrolled) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'Configuración',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF11232D),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                    children: [
                      // Large Title & Subtitle (shown at the top)
                      const Text(
                        'Configuración',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: Color(0xFF11232D),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Personalizá la app y gestioná tu información.',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF586974),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 1. APARIENCIA
                      _buildSectionTitle('Apariencia'),
                      const SizedBox(height: 10),
                      _buildSettingsCard(
                        children: [
                          _SettingsTile(
                            key: const Key('settings-theme-tile'),
                            icon: Icons.nightlight_round,
                            title: 'Tema',
                            trailing: Text(
                              _themeMode,
                              style: const TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF586974),
                              ),
                            ),
                            onTap: _selectTheme,
                          ),
                          const _CardDivider(),
                          _SettingsTile(
                            key: const Key('settings-reduce-motion-tile'),
                            customIcon: const _WaveIcon(),
                            title: 'Reducir animaciones',
                            trailing: Switch(
                              key: const Key('settings-reduce-motion-switch'),
                              value: _reduceMotion,
                              thumbColor:
                                  WidgetStateProperty.all(Colors.white),
                              activeTrackColor: const Color(0xFF0D7E88),
                              inactiveTrackColor: const Color(0xFFD4DBDF),
                              trackOutlineColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              onChanged: (val) {
                                setState(() => _reduceMotion = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 2. PREFERENCIAS
                      _buildSectionTitle('Preferencias'),
                      const SizedBox(height: 10),
                      _buildSettingsCard(
                        children: [
                          _SettingsTile(
                            key: const Key('settings-currency-tile'),
                            icon: Icons.monetization_on_outlined,
                            title: 'Moneda predeterminada',
                            subtitle: _formatCurrency(_defaultCurrency),
                            onTap: _selectCurrency,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Se usará al crear grupos nuevos. Cada grupo puede tener su propia moneda.',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF586974),
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. DATOS Y PRIVACIDAD
                      _buildSectionTitle('Datos y privacidad'),
                      const SizedBox(height: 10),
                      _buildSettingsCard(
                        children: [
                          // Tinted top row
                          Container(
                            color: const Color(0xFFF0F9F9),
                            child: const _SettingsTile(
                              key: Key('settings-local-storage-info-tile'),
                              icon: Icons.shield_outlined,
                              title: 'Tus datos se guardan en este dispositivo',
                              subtitle: 'No se sincronizan ni se comparten.',
                            ),
                          ),
                          const _CardDivider(),
                          _SettingsTile(
                            key: const Key('settings-privacy-tile'),
                            icon: Icons.description_outlined,
                            title: 'Política de privacidad',
                            onTap: _showPrivacyPolicy,
                          ),
                          const _CardDivider(),
                          _SettingsTile(
                            key: const Key('settings-clear-data-tile'),
                            icon: Icons.delete_outline_rounded,
                            iconColor: const Color(0xFFBA3D2A),
                            iconBgColor: const Color(0xFFFDECEB),
                            title: 'Borrar todos los datos locales',
                            titleColor: const Color(0xFFBA3D2A),
                            onTap: _confirmClearData,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 4. AYUDA
                      _buildSectionTitle('Ayuda'),
                      const SizedBox(height: 10),
                      _buildSettingsCard(
                        children: [
                          _SettingsTile(
                            key: const Key('settings-help-tile'),
                            icon: Icons.help_outline_rounded,
                            title: 'Cómo funciona Gastos Compartidos',
                            onTap: _showHowItWorks,
                          ),
                          const _CardDivider(),
                          _SettingsTile(
                            key: const Key('settings-support-tile'),
                            icon: Icons.mail_outline_rounded,
                            title: 'Contactar soporte',
                            onTap: _showSupport,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 5. ACERCA DE
                      _buildSectionTitle('Acerca de'),
                      const SizedBox(height: 10),
                      _buildSettingsCard(
                        children: [
                          const _SettingsTile(
                            key: Key('settings-version-tile'),
                            icon: Icons.local_offer_outlined,
                            title: 'Versión de la app',
                            trailing: Text(
                              '1.0.0',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF586974),
                              ),
                            ),
                          ),
                          const _CardDivider(),
                          _SettingsTile(
                            key: const Key('settings-terms-tile'),
                            icon: Icons.description_outlined,
                            title: 'Términos de uso',
                            onTap: _showTermsOfUse,
                          ),
                          const _CardDivider(),
                          _SettingsTile(
                            key: const Key('settings-licenses-tile'),
                            icon: Icons.info_outline_rounded,
                            title: 'Licencias de código abierto',
                            onTap: _showLicenses,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Figtree',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF586974),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECEE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.8),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    super.key,
    this.icon,
    this.customIcon,
    this.iconColor,
    this.iconBgColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData? icon;
  final Widget? customIcon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveIconBgColor = iconBgColor ?? const Color(0xFFE6F4F5);
    final effectiveIconColor = iconColor ?? const Color(0xFF0D7E88);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: effectiveIconBgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: customIcon ??
                Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 22,
                ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? const Color(0xFF11232D),
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF586974),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F4F6),
    );
  }
}

class _WaveIcon extends StatelessWidget {
  const _WaveIcon();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(20, 10),
      painter: _WaveIconPainter(color: Color(0xFF0D7E88)),
    );
  }
}

class _WaveIconPainter extends CustomPainter {
  const _WaveIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(1, size.height * 0.5);
    path.cubicTo(
      size.width * 0.28,
      size.height * -0.4,
      size.width * 0.28,
      size.height * -0.4,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.cubicTo(
      size.width * 0.72,
      size.height * 1.4,
      size.width * 0.72,
      size.height * 1.4,
      size.width - 1,
      size.height * 0.5,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
