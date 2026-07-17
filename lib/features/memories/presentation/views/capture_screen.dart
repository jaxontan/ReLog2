import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../app/design/design_system.dart';
import '../../data/repositories/memory_repository.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final String albumId;
  const CaptureScreen({super.key, required this.albumId});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> with WidgetsBindingObserver {
  int _tab = 0; // 0=photo, 1=video, 2=voice
  CameraController? _cam;
  List<CameraDescription> _cameras = [];
  bool _camReady = false, _recording = false, _saving = false;
  final _recorder = AudioRecorder();
  String? _voicePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cam?.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cam == null || !_cam!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cam!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCam();
    }
  }

  Future<void> _initCam() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _camReady = false);
        return;
      }
      final back = _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => _cameras.first);
      _cam = CameraController(back, ResolutionPreset.high, enableAudio: true);
      await _cam!.initialize();
      if (mounted) setState(() => _camReady = true);
    } catch (_) {
      if (mounted) setState(() => _camReady = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Capture', style: DSTypography.titleLarge.copyWith(color: Colors.white)),
        centerTitle: true,
        actions: [
          if (_saving)
            Padding(
              padding: const EdgeInsets.all(DSSpacing.md),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg, vertical: DSSpacing.sm),
            child: Row(
              children: [
                _CaptureTabBtn(index: 0, icon: Icons.camera_alt_outlined, label: 'Photo', selected: _tab == 0),
                _CaptureTabBtn(index: 1, icon: Icons.videocam_outlined, label: 'Video', selected: _tab == 1),
                _CaptureTabBtn(index: 2, icon: Icons.mic_outlined, label: 'Voice', selected: _tab == 2),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          // Content
          Expanded(child: _buildTab()),
        ],
      ),
    );
  }

  Widget _CaptureTabBtn({required int index, required IconData icon, required String label, required bool selected}) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        borderRadius: BorderRadius.circular(DSRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: DSSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.grey, size: DSIconSize.md),
              const SizedBox(height: 2),
              Text(label, style: DSTypography.labelSmall.copyWith(color: selected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab() {
    if (_tab == 2) return _voiceTab();
    if (!_camReady || _cam == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey[700]),
            const SizedBox(height: DSSpacing.md),
            Text('Camera unavailable', style: DSTypography.bodyMedium.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cam!),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _tab == 0 ? _takePhoto : (_recording ? _stopVideo : _startVideo),
              child: AnimatedContainer(
                duration: DSAnimation.fast,
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: _recording ? Colors.red : Colors.white.withValues(alpha: 0.3),
                ),
                child: _tab == 1 && !_recording
                    ? const Icon(Icons.fiber_manual_record, color: Colors.red, size: 32)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _takePhoto() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final file = await _cam!.takePicture();
      await _saveMedia(File(file.path), 'photo');
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _startVideo() async {
    setState(() { _recording = true; _saving = false; });
    await _cam!.startVideoRecording();
  }

  Future<void> _stopVideo() async {
    try {
      final file = await _cam!.stopVideoRecording();
      setState(() { _recording = false; _saving = true; });
      await _saveMedia(File(file.path), 'video');
    } catch (_) {
      if (mounted) setState(() => _recording = false);
    }
  }

  Widget _voiceTab() {
    final recording = _recording;
    final scheme = context.scheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: recording ? _stopVoice : _startVoice,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recording ? Colors.red : scheme.primary,
                boxShadow: recording ? DSElevation.level3 : DSElevation.level2,
              ),
              child: Icon(recording ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: DSSpacing.md),
          Text(
            recording ? 'Recording...' : 'Tap to record',
            style: DSTypography.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _startVoice() async {
    if (await _recorder.hasPermission()) {
      setState(() => _recording = true);
      final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      _voicePath = path;
    }
  }

  Future<void> _stopVoice() async {
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (path != null) {
      setState(() => _saving = true);
      await _saveMedia(File(path), 'voice');
    }
  }

  Future<void> _saveMedia(File file, String type) async {
    final repo = ref.read(memoryRepositoryProvider);
    final userId = ref.read(authServiceProvider).currentUser?.id;
    if (userId == null) return;
    double? lat, lng;
    try {
      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude; lng = pos.longitude;
    } catch (_) {} // GPS optional
    final (_, error) = await repo.saveMemory(
      albumId: widget.albumId, userId: userId, type: type, mediaFile: file, lat: lat, lng: lng,
    );
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${error.message}'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      } else {
        context.go('/albums/${widget.albumId}');
      }
      setState(() => _saving = false);
    }
  }
}