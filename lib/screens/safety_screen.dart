import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../generated/app_localizations.dart';
import '../providers/location_provider.dart';

class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  String _getEmergencyNumber(String? countryCode) {
    if (countryCode == null) return '911';
    
    final map = {
      'TR': '112',
      'ES': '112',
      'ZA': '112',
      'US': '911',
      'CA': '911',
      'JP': '119',
      'GB': '999',
      'AU': '000',
      'MX': '911',
      'CL': '131',
      'PE': '105',
      'CO': '123',
      'AR': '911',
      'NZ': '111',
    };
    
    return map[countryCode] ?? '911';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locationState = ref.watch(locationProvider);
    final emergencyNumber = _getEmergencyNumber(locationState.countryCode);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(context, l10n.duringQuake, Icons.emergency),
        _buildSafetyCard(
          context,
          l10n.dropCoverHold,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep(context, '1', l10n.dropDesc),
              _buildStep(context, '2', l10n.coverDesc),
              _buildStep(context, '3', l10n.holdDesc),
            ],
          ),
          Colors.orange,
        ),
        const SizedBox(height: 24),
        
        _buildSectionHeader(context, l10n.afterQuake, Icons.check_circle_outline),
        _buildSafetyCard(
          context,
          'Immediate Steps',
          Column(
            children: [
              _buildCheckItem(context, l10n.checkInjuries),
              _buildCheckItem(context, l10n.checkGas),
              _buildCheckItem(context, l10n.bePreparedAftershocks),
            ],
          ),
          Colors.blue,
        ),
        const SizedBox(height: 24),

        _buildSectionHeader(context, l10n.emergencyKit, Icons.backpack_outlined),
        _buildSafetyCard(
          context,
          'Essential Supplies',
          Column(
            children: [
              _buildCheckItem(context, l10n.kitWater),
              _buildCheckItem(context, l10n.kitFood),
              _buildCheckItem(context, l10n.kitFlashlight),
              _buildCheckItem(context, l10n.kitFirstAid),
            ],
          ),
          Colors.green,
        ),
        const SizedBox(height: 24),

        _buildSectionHeader(context, l10n.emergencyContacts, Icons.contact_phone_outlined),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.phone, color: Colors.white),
            ),
            title: Text('${l10n.callEmergency}: $emergencyNumber'),
            subtitle: Text('Local Emergency Number (${locationState.countryCode ?? 'Default'})'),
            onTap: () => launchUrl(Uri.parse('tel:$emergencyNumber')),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard(BuildContext context, String title, Widget content, Color accentColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              number,
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_box_outlined, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
