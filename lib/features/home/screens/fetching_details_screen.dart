import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../download_engine/extraction_service.dart';
import '../../download_engine/models/video_format.dart';
import '../../download_engine/models/video_info.dart';

enum FetchStatus {
  loading,
  success,
  error,
}

/// Screen that animates extraction progress and displays selectable video formats upon completion.
class FetchingDetailsScreen extends ConsumerStatefulWidget {
  final String? videoUrl;

  const FetchingDetailsScreen({
    super.key,
    this.videoUrl,
  });

  @override
  ConsumerState<FetchingDetailsScreen> createState() => _FetchingDetailsScreenState();
}

class _FetchingDetailsScreenState extends ConsumerState<FetchingDetailsScreen>
    with SingleTickerProviderStateMixin {
  FetchStatus _status = FetchStatus.loading;
  AnimationController? _animationController;
  Animation<double>? _progressAnimation;

  VideoInfo? _videoInfo;
  final Set<VideoFormat> _selectedFormats = <VideoFormat>{};

  @override
  void initState() {
    super.initState();
    _initAndStartExtraction();
  }

  void _initAndStartExtraction() {
    _status = FetchStatus.loading;
    _selectedFormats.clear();

    _animationController?.dispose();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Initial animation: progress 0 to 90% over 2 seconds
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.90).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        setState(() {});
      });

    _animationController!.forward();
    _executeFetchDetails();
  }

  Future<void> _executeFetchDetails() async {
    try {
      final extractionService = ref.read(extractionServiceProvider);
      final targetUrl = widget.videoUrl ?? 'https://youtube.com/watch?v=sample';

      final extractedInfo = await extractionService.fetchDetails(targetUrl);

      if (!mounted) return;

      // Upon completion, animate remaining progress to 100% in 200ms
      final currentProgress = _progressAnimation?.value ?? 0.90;
      _animationController!.duration = const Duration(milliseconds: 200);

      _progressAnimation = Tween<double>(begin: currentProgress, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController!,
          curve: Curves.easeInOut,
        ),
      );

      await _animationController!.forward(from: currentProgress);

      if (!mounted) return;

      setState(() {
        _status = FetchStatus.success;
        _videoInfo = extractedInfo;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = FetchStatus.error;
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_status == FetchStatus.success ? 'Select Format' : 'Fetching Details'),
      ),
      body: SafeArea(
        child: switch (_status) {
          FetchStatus.loading => _buildLoadingView(),
          FetchStatus.error => _buildErrorView(),
          FetchStatus.success => _buildResultsView(),
        },
      ),
    );
  }

  /// 1. Loading view with progress percentage animation
  Widget _buildLoadingView() {
    final progressPercentage = ((_progressAnimation?.value ?? 0.0) * 100).toInt();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progressAnimation?.value,
                    strokeWidth: 6,
                  ),
                  Text(
                    '$progressPercentage%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fetching...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              widget.videoUrl ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Error view when video extraction fails
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              "Couldn't fetch video details. Please check the link and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _initAndStartExtraction,
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Results view: Thumbnail + Title + Duration + Dynamic Format List + Download Buttons
  Widget _buildResultsView() {
    final videoInfo = _videoInfo;
    if (videoInfo == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Metadata summary (Thumbnail, Title, Duration)
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 110,
                  height: 75,
                  color: Colors.grey.shade300,
                  child: videoInfo.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          videoInfo.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.video_library, size: 36, color: Colors.grey),
                        )
                      : const Icon(Icons.video_library, size: 36, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // Title and duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      videoInfo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          videoInfo.formattedDuration,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Scrollable vertical list of format options
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: videoInfo.formats.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
            itemBuilder: (context, index) {
              final format = videoInfo.formats[index];
              final isChecked = _selectedFormats.contains(format);

              return CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                value: isChecked,
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedFormats.add(format);
                    } else {
                      _selectedFormats.remove(format);
                    }
                  });
                },
                title: Text(
                  format.formattedDisplayLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: format.formattedEstimatedSize != null
                    ? Text(
                        format.formattedEstimatedSize!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      )
                    : null,
                secondary: IconButton(
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'Download ${format.label}',
                  onPressed: () {
                    // Stub for single download (to be integrated in Phase 5)
                    debugPrint('Direct single download initiated for: ${format.label}');
                  },
                ),
              );
            },
          ),
        ),

        // Bottom action bar: Download Selected
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedFormats.isEmpty
                  ? null
                  : () {
                      // Stub for batch download (to be integrated in Phase 5)
                      debugPrint(
                        'Batch download initiated for ${_selectedFormats.length} formats.',
                      );
                    },
              child: Text(
                _selectedFormats.isEmpty
                    ? 'Download Selected'
                    : 'Download Selected (${_selectedFormats.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
