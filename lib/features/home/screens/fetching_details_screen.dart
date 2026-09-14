import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/circular_percentage_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../download_engine/extraction_service.dart';
import '../../download_engine/models/queue_item.dart';
import '../../download_engine/models/video_info.dart';
import '../../download_engine/queue_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initAndStartExtraction();
  }

  void _initAndStartExtraction() {
    _status = FetchStatus.loading;

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_status == FetchStatus.success
            ? l10n.selectFormatTitle
            : l10n.fetchingDetailsTitle),
      ),
      body: SafeArea(
        child: switch (_status) {
          FetchStatus.loading => _buildLoadingView(l10n),
          FetchStatus.error => _buildErrorView(l10n),
          FetchStatus.success => _buildResultsView(l10n),
        },
      ),
    );
  }

  /// 1. Loading view with progress percentage animation
  Widget _buildLoadingView(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentageIndicator(
              progress: _progressAnimation?.value ?? 0.0,
              size: 110,
              strokeWidth: 8,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.fetchingLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
  Widget _buildErrorView(AppLocalizations l10n) {
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
            Text(
              l10n.fetchErrorDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retryButton),
              onPressed: _initAndStartExtraction,
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Results view: Thumbnail + Title + Duration + Dynamic Format List + Download Buttons
  Widget _buildResultsView(AppLocalizations l10n) {
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
              // Thumbnail with rounded corners and subtle shadow
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.0),
                  child: Container(
                    width: 110,
                    height: 75,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          child: Builder(
            builder: (context) {
              final queue = ref.watch(downloadQueueProvider);
              final queuedFormatsForThisVideo = queue
                  .where((item) =>
                      item.videoInfo.title == videoInfo.title &&
                      item.status == QueueItemStatus.queued)
                  .toList();

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: videoInfo.formats.length,
                      itemBuilder: (context, index) {
                        final format = videoInfo.formats[index];
                        final isChecked = queuedFormatsForThisVideo
                            .any((item) => item.selectedFormat == format);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            elevation: isChecked ? 3 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isChecked
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outlineVariant,
                                width: isChecked ? 1.5 : 1.0,
                              ),
                            ),
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              controlAffinity: ListTileControlAffinity.leading,
                              value: isChecked,
                              onChanged: (bool? checked) {
                                if (checked == true) {
                                  ref
                                      .read(downloadQueueProvider.notifier)
                                      .addQueueItem(videoInfo, format);
                                } else {
                                  ref
                                      .read(downloadQueueProvider.notifier)
                                      .removeQueueItem(videoInfo, format);
                                }
                              },
                              title: Text(
                                format.formattedDisplayLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: format.formattedEstimatedSize != null
                                  ? Text(
                                      format.formattedEstimatedSize!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    )
                                  : null,
                              secondary: IconButton(
                                icon: const Icon(Icons.download_rounded),
                                tooltip: l10n.downloadFormatTooltip(format.label),
                                onPressed: () {
                                  ref
                                      .read(downloadQueueProvider.notifier)
                                      .startSingleDownload(videoInfo, format);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n
                                          .downloadingFormatSnackbar(format.label)),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
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
                        onPressed: queuedFormatsForThisVideo.isEmpty
                            ? null
                            : () {
                                final count = queuedFormatsForThisVideo.length;
                                ref
                                    .read(downloadQueueProvider.notifier)
                                    .startQueuedDownloads();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n
                                        .startedDownloadingFormatsSnackbar(count)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                        child: Text(
                          queuedFormatsForThisVideo.isEmpty
                              ? l10n.downloadSelectedButton
                              : l10n.downloadSelectedWithCountButton(
                                  queuedFormatsForThisVideo.length),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
