import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/memory_repository.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final String albumId;
  const CaptureScreen({super.key, required this.albumId});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  int _tab = 0; // 0=photo, 1=video, 2=voice

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Memory')),
      body: Column(
        children: [
          // Tab bar: photo / video / voice
          Row(
            children: [
              _tabButton(0, Icons.camera_alt, 'Photo'),
              _tabButton(1, Icons.videocam, 'Video'),
              _tabButton(2, Icons.mic, 'Voice'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: switch (_tab) {
                0 => _CapturePlaceholder(icon: Icons.camera_alt, label: 'Camera will open here'),
                1 => _CapturePlaceholder(icon: Icons.videocam, label: 'Video recorder will open here'),
                _ => _VoiceCaptureWidget(onSaved: _saveVoice),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int idx, IconData icon, String label) {
    final selected = _tab == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : Colors.grey),
            Text(label, style: TextStyle(fontSize: 12, color: selected ? Theme.of(context).colorScheme.primary : Colors.grey)),
          ]),
        ),
      ),
    );
  }

  Future<void> _saveVoice(String? filePath) async {
    if (filePath == null) return;
    final repo = ref.read(memoryRepositoryProvider);
    final userId = ref.read(authServiceProvider).currentUser?.uid;
    if (userId == null) return;
    final (_, error) = await repo.saveMemory(
      albumId: widget.albumId,
      userId: userId,
      type: 'voice',
      mediaFile: File(filePath), // ponytail: 'dart:io' File
    );
    if (mounted && error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice saved!')));
      context.go('/albums/${widget.albumId}');
    }
  }
}

class _CapturePlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CapturePlaceholder({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Camera/record packages will integrate here',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      );
}

class _VoiceCaptureWidget extends StatefulWidget {
  final void Function(String?) onSaved;
  const _VoiceCaptureWidget({required this.onSaved});

  @override
  State<_VoiceCaptureWidget> createState() => _VoiceCaptureWidgetState();
}

class _VoiceCaptureWidgetState extends State<_VoiceCaptureWidget> {
  bool _recording = false;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _recording = !_recording),
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _recording ? Colors.red : Theme.of(context).colorScheme.primary,
              ),
              child: Icon(_recording ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 12),
          Text(_recording ? 'Recording...' : 'Tap to record',
              style: TextStyle(color: Colors.grey[600])),
          if (_recording) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() => _recording = false);
                // ponytail: 'record' package integration returns a file path.
                // Stub — actual Record.start() and Record.stop() replace this.
                widget.onSaved(null);
              },
              child: const Text('Stop & Save'),
            ),
          ],
        ],
      );
}
