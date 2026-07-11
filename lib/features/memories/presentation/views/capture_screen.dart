import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import '../../data/repositories/memory_repository.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import 'package:geolocator/geolocator.dart';

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
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initCam(); }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _cam?.dispose(); _recorder.dispose(); super.dispose(); }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cam == null || !_cam!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) _cam!.dispose();
    else if (state == AppLifecycleState.resumed) _initCam();
  }

  Future<void> _initCam() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) { setState(() => _camReady = false); return; }
      final back = _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => _cameras.first);
      _cam = CameraController(back, ResolutionPreset.high, enableAudio: true);
      await _cam!.initialize();
      if (mounted) setState(() => _camReady = true);
    } catch (_) { if (mounted) setState(() => _camReady = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture'), actions: [
        if (_saving) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ]),
      body: Column(children: [
        Row(children: [
          _tabBtn(0, Icons.camera_alt, 'Photo'),
          _tabBtn(1, Icons.videocam, 'Video'),
          _tabBtn(2, Icons.mic, 'Voice'),
        ]),
        const Divider(height: 1),
        Expanded(child: _buildTab()),
      ]),
    );
  }

  Widget _tabBtn(int i, IconData icon, String label) {
    final sel = _tab == i;
    return Expanded(child: InkWell(
      onTap: () => setState(() => _tab = i),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: sel ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: sel ? Theme.of(context).colorScheme.primary : Colors.grey),
          Text(label, style: TextStyle(fontSize: 12, color: sel ? Theme.of(context).colorScheme.primary : Colors.grey)),
        ]),
      ),
    ));
  }

  Widget _buildTab() {
    if (_tab == 2) return _voiceTab();
    if (!_camReady || _cam == null) return const Center(child: Text('Camera unavailable', style: TextStyle(fontSize: 16, color: Colors.grey)));
    return Stack(fit: StackFit.expand, children: [
      CameraPreview(_cam!),
      Positioned(bottom: 40, left: 0, right: 0, child: Center(
        child: GestureDetector(
          onTap: _tab == 0 ? _takePhoto : (_recording ? _stopVideo : _startVideo),
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4),
              color: _recording ? Colors.red : Colors.white.withValues(alpha: 0.3)),
            child: _tab == 1 && !_recording ? const Icon(Icons.fiber_manual_record, color: Colors.red, size: 32) : null,
          ),
        ),
      )),
    ]);
  }

  Future<void> _takePhoto() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final file = await _cam!.takePicture();
      await _saveMedia(File(file.path), 'photo');
    } catch (_) { if (mounted) setState(() => _saving = false); }
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
    } catch (_) { if (mounted) setState(() => _recording = false); }
  }

  Widget _voiceTab() {
    final recording = _recording;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: recording ? _stopVoice : _startVoice,
        child: Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: recording ? Colors.red : Theme.of(context).colorScheme.primary),
          child: Icon(recording ? Icons.stop : Icons.mic, color: Colors.white, size: 36)),
      ),
      const SizedBox(height: 12),
      Text(recording ? 'Recording...' : 'Tap to record', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
    ]));
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
    } catch (_) {} // ponytail: GPS optional, skip if denied
    final (_, error) = await repo.saveMemory(
      albumId: widget.albumId, userId: userId, type: type, mediaFile: file, lat: lat, lng: lng,
    );
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: ${error.message}')));
      } else {
        context.go('/albums/${widget.albumId}');
      }
      setState(() => _saving = false);
    }
  }
}
