import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_seismograph_provider.dart';

class CommunitySeismographStatus extends ConsumerWidget {
  const CommunitySeismographStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communitySeismographProvider);
    if (!state.isEnabled) return const SizedBox.shrink();

    final Color statusColor = state.isRecording 
        ? Colors.green 
        : state.isSettling 
            ? Colors.blue 
            : Colors.orange;

    final String statusTitle = state.isRecording 
        ? 'Seismograph Active' 
        : state.isSettling 
            ? 'Seismograph Settling...' 
            : 'Seismograph Paused';

    final String statusSubtitle = state.isRecording
        ? 'Your phone is contributing to the seismic network.'
        : state.isSettling
            ? 'Waiting for device to stabilize after connection.'
            : 'Connect to a charger to start contributing.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isRecording ? Icons.sensors : state.isSettling ? Icons.hourglass_empty : Icons.sensors_off,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor.withAlpha(200), // Slightly darker for text
                  ),
                ),
                Text(
                  statusSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white70 
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (state.isRecording)
            const _PulseIndicator(color: Colors.green),
          if (state.isSettling)
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  final Color color;
  const _PulseIndicator({required this.color});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
