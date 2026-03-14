import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/circle_provider.dart';
import '../models/circle.dart';
import '../models/circle_member.dart';
import '../theme.dart';

class CirclesScreen extends ConsumerWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleState = ref.watch(circleProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppTheme.obsidian 
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Safety Circles', style: TextStyle(fontFamily: 'Oswald')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCircleDialog(context, ref),
            tooltip: 'Create Circle',
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () => _showJoinCircleDialog(context, ref),
            tooltip: 'Join Circle',
          ),
        ],
      ),
      body: circleState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : circleState.circles.isEmpty
              ? _buildEmptyState(context, ref)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: circleState.circles.length,
                  itemBuilder: (context, index) {
                    return _CircleCard(circle: circleState.circles[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.withAlpha(100)),
          const SizedBox(height: 24),
          Text(
            'No Safety Circles yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Create a circle for your family or friends'),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateCircleDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Create My First Circle'),
          ),
        ],
      ),
    );
  }

  void _showCreateCircleDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Safety Circle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Circle Name (e.g., Family)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(circleProvider.notifier).createCircle(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  void _showJoinCircleDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Safety Circle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Invite Code'),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(circleProvider.notifier).joinCircle(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('JOIN'),
          ),
        ],
      ),
    );
  }
}

class _CircleCard extends ConsumerWidget {
  final SafetyCircle circle;

  const _CircleCard({required this.circle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(
          circle.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Row(
          children: [
            Text(
              'Code: ${circle.inviteCode}',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              tooltip: 'Copy Invite Code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: circle.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied to clipboard')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share, size: 16),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              tooltip: 'Share Invite Code',
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    text: 'Join my QuakeTrack Safety Circle! Use invite code: ${circle.inviteCode}',
                    subject: 'QuakeTrack Safety Circle Invitation',
                  ),
                );
              },
            ),
          ],
        ),
        leading: const CircleAvatar(child: Icon(Icons.group)),
        trailing: IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.red),
          tooltip: 'Leave Circle',
          onPressed: () => _showLeaveConfirm(context, ref),
        ),
        children: circle.members.map((member) => _MemberTile(circleId: circle.id, member: member)).toList(),
      ),
    );
  }

  void _showLeaveConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Circle?'),
        content: Text('Are you sure you want to leave "${circle.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              ref.read(circleProvider.notifier).leaveCircle(circle.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final String circleId;
  final CircleMember member;

  const _MemberTile({required this.circleId, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: _buildStatusBadge(member.status),
      title: Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.email, style: const TextStyle(fontSize: 12)),
          if (member.lastStatusUpdate != null)
            Text(
              'Last update: ${DateFormat.jm().format(member.lastStatusUpdate!)}',
              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.status != SafetyStatus.safe)
            TextButton(
              onPressed: () {
                ref.read(circleProvider.notifier).updateSafetyStatus(circleId, SafetyStatus.safe);
              },
              child: const Text('I\'M SAFE'),
            ),
          if (member.status == SafetyStatus.safe)
            const Icon(Icons.check, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SafetyStatus status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case SafetyStatus.safe:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'SAFE';
        break;
      case SafetyStatus.unsafe:
        color = Colors.red;
        icon = Icons.warning;
        label = 'UNSAFE';
        break;
      case SafetyStatus.notReported:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = 'NOT REPORTED';
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
