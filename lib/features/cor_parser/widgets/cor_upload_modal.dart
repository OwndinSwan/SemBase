import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_toast.dart';
import '../../sync_diff/services/sync_diff_service.dart';
import '../../sync_diff/widgets/sync_diff_dialog.dart';
import '../models/parsed_cor.dart';
import '../services/cor_isolate.dart';
import '../services/cor_matcher.dart';
import '../services/gemini_cor_parser_service.dart';
import 'ai_scan_progress_view.dart';

class CorUploadModal extends ConsumerStatefulWidget {
  const CorUploadModal({super.key});

  @override
  ConsumerState<CorUploadModal> createState() => _CorUploadModalState();
}

class _CorUploadModalState extends ConsumerState<CorUploadModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pasteController = TextEditingController();
  bool _isProcessing = false;
  bool _isAiExtraction = false;
  String _statusMessage = '';
  String? _errorMessage;
  String? _lastRawText;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBarPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: bottomInset + (navBarPadding > 0 ? navBarPadding + 16 : 28),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Import Schedule / COR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMutedDark),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload your official Certificate of Registration (PDF) or paste your weekly schedule text.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryDark),
              ),
              const SizedBox(height: 12),

              // In-Modal Error Notification Box (Ensures notifications are NEVER clipped by bottom sheet)
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRose.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentRose.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.accentRose, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'SemBase AI Notice',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentRose,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: AppTheme.textMutedDark),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _errorMessage = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryDark, height: 1.3),
                      ),
                      if (_lastRawText != null && _lastRawText!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _executeGeminiAiExtraction(_lastRawText!),
                            icon: const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.accentAmber),
                            label: const Text('Retry with AI', style: TextStyle(fontSize: 11.5, color: AppTheme.accentAmber, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Offline Capability Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.offline_bolt_rounded, color: AppTheme.primaryGreenLight, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚡ Fast Offline Engine: 90%+ optimized for Cavite State University (CvSU) COR PDFs. SemBase AI fallback available for other formats.',
                        style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryDark.withOpacity(0.9), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // If AI Extraction is active, show the futuristic AI Neural Scanner view!
              if (_isProcessing && _isAiExtraction)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: AiScanProgressView(),
                )
              else ...[
                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondaryDark,
                    tabs: const [
                      Tab(icon: Icon(Icons.picture_as_pdf, size: 18), text: 'Upload PDF / COR'),
                      Tab(icon: Icon(Icons.paste, size: 18), text: 'Paste Schedule Text'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Views
                SizedBox(
                  height: 310,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPdfUploadTab(),
                      _buildPasteTextTab(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfUploadTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: _isProcessing ? null : () => _pickAndParsePdf(forceAi: false),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.bgDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                if (_isProcessing && !_isAiExtraction) ...[
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage.isNotEmpty ? _statusMessage : 'Reading & parsing COR PDF offline...',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreenLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Icon(Icons.cloud_upload_outlined, size: 44, color: AppTheme.primaryGreen),
                  const SizedBox(height: 10),
                  const Text(
                    'Select PDF Certificate of Registration',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Supports official university COR & registration cards (PDF)',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryDark),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentAmber,
                  AppTheme.accentAmber.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentAmber.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _pickAndParsePdf(forceAi: true),
              icon: (_isProcessing && _isAiExtraction)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.auto_awesome, size: 17, color: Colors.black),
              label: Text(
                (_isProcessing && _isAiExtraction)
                    ? 'Extracting schedule with SemBase AI...'
                    : 'Extract with SemBase AI',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasteTextTab() {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _pasteController,
            maxLines: null,
            expands: true,
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimaryDark),
            decoration: InputDecoration(
              hintText: 'Paste COR text or weekly schedule (e.g. MONDAY • 7:00 AM-9:00 AM — Subject (Room))...',
              hintStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
              filled: true,
              fillColor: AppTheme.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderDark),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loadSampleDaySchedule,
                icon: const Icon(Icons.format_list_bulleted, size: 14),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentCyan,
                  side: const BorderSide(color: AppTheme.accentCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                label: const Text('Day Sched Sample', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loadSampleCvSuCor,
                icon: const Icon(Icons.article_outlined, size: 14),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondaryDark,
                  side: const BorderSide(color: AppTheme.borderDark),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                label: const Text('Tabular COR Sample', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _parsePastedText(forceAi: false),
                icon: (_isProcessing && !_isAiExtraction)
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.bolt, size: 16),
                label: Text(
                  (_isProcessing && !_isAiExtraction) ? 'Parsing...' : 'Parse Offline',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 6,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _parsePastedText(forceAi: true),
                icon: (_isProcessing && _isAiExtraction)
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.auto_awesome, size: 16, color: Colors.black),
                label: Text(
                  (_isProcessing && _isAiExtraction) ? 'Extracting...' : 'SemBase AI',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAndParsePdf({bool forceAi = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isProcessing = true;
          _isAiExtraction = false;
          _errorMessage = null;
          _statusMessage = 'Extracting PDF text...';
        });

        Uint8List? bytes = result.files.first.bytes;
        if (bytes == null && result.files.first.path != null) {
          final file = File(result.files.first.path!);
          bytes = await file.readAsBytes();
        }

        if (bytes != null) {
          // Extract text from PDF
          String extractedText = '';
          try {
            final PdfDocument document = PdfDocument(inputBytes: bytes);
            final PdfTextExtractor extractor = PdfTextExtractor(document);
            extractedText = extractor.extractText();
            document.dispose();
          } catch (e) {
            debugPrint('PDF Text extraction error: $e');
          }

          if (forceAi) {
            await _executeGeminiAiExtraction(extractedText);
            return;
          }

          // 1. Attempt Fast Offline Regex Parser
          final parsed = await CorIsolateService.parseRawText(extractedText);

          if (parsed.courses.isNotEmpty) {
            await _processParsedCor(parsed, rawText: extractedText);
          } else {
            // Local offline parser could not detect courses -> prompt for Gemini AI
            if (mounted) {
              setState(() => _isProcessing = false);
              _promptCloudAiFallback(extractedText);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppToast.showError(context, 'PDF Parsing error: $e');
      }
    }
  }

  Future<void> _parsePastedText({bool forceAi = false}) async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      AppToast.showWarning(context, 'Please paste schedule text first or click a sample button');
      return;
    }

    if (forceAi) {
      await _executeGeminiAiExtraction(text);
      return;
    }

    setState(() {
      _isProcessing = true;
      _isAiExtraction = false;
      _errorMessage = null;
      _statusMessage = 'Tokenizing schedule with offline parser...';
    });

    try {
      // 1. Attempt Fast Offline Parser
      final parsed = await CorIsolateService.parseRawText(text);

      if (parsed.courses.isNotEmpty) {
        await _processParsedCor(parsed, rawText: text);
      } else {
        // Unknown format -> prompt user for Cloud AI
        if (mounted) {
          setState(() => _isProcessing = false);
          _promptCloudAiFallback(text);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppToast.showError(context, 'Parsing error: $e');
      }
    }
  }

  void _promptCloudAiFallback(String rawText) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.accentAmber, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Unknown Format Detected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The offline parser is 90%+ optimized for standard Cavite State University (CvSU) CORs and could not detect course tables in this document.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryDark, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Would you like SemBase AI to extract and structure your schedule? (Internet connection required)',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryDark)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _executeGeminiAiExtraction(rawText);
            },
            icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.black),
            label: const Text('Extract with SemBase AI', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAmber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeGeminiAiExtraction(String rawText) async {
    setState(() {
      _isProcessing = true;
      _isAiExtraction = true;
      _errorMessage = null;
      _lastRawText = rawText;
      _statusMessage = 'Extracting schedule with SemBase AI...';
    });

    try {
      final aiParsed = await GeminiCorParserService.extractWithGemini(rawText);
      if (aiParsed.courses.isNotEmpty) {
        await _processParsedCor(aiParsed, rawText: rawText, isAiParsed: true);
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isAiExtraction = false;
            _errorMessage = 'SemBase AI was unable to detect course timetable slots from this document text.';
          });
        }
      }
    } catch (e) {
      AppLogService.error(
        AppLogService.catSync,
        'SemBase AI Schedule Extraction failed: $e',
      );
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isAiExtraction = false;
          _errorMessage = GeminiCorParserService.sanitizeUserErrorMessage(e);
        });
      }
    }
  }

  Future<void> _processParsedCor(ParsedCorData parsed, {String? rawText, bool isAiParsed = false}) async {
    final db = ref.read(databaseProvider);
    final diffService = SyncDiffService(db);
    final diffSummary = await diffService.computeDiff(parsed);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isAiExtraction = false;
      });
      Navigator.of(context).pop();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SyncDiffDialog(
          diffSummary: diffSummary,
          rawText: rawText,
          isAiParsed: isAiParsed,
          onApplied: () {
            // Refreshed automatically by Riverpod streams
          },
        ),
      );
    }
  }

  void _loadSampleDaySchedule() {
    _pasteController.text = '''
MONDAY

• 7:00 AM-9:00 AM — Fundamentals in Lodging Operations (403B)
• 10:00 AM-1:00 PM — Fundamentals in Lodging Operations (607B)

TUESDAY

• 7:00 AM-10:00 AM — Philippine Regional Cuisines with Food Styling and Design (Kitchen Lab)
• 10:00 AM-11:00 AM — Philippine Regional Cuisines with Food Styling and Design (306B)

WEDNESDAY

• 7:00 AM-10:00 AM — Hotel Front Office Operations Management (415B)
• 11:00 AM-1:00 PM — PE/PATHFIT 3

THURSDAY

• 1:00 PM-4:00 PM — Quality Service Operations Management (414B)
• 4:00 PM-7:00 PM — Foreign Language 1 (408B)

SATURDAY

• 2:30 PM-5:30 PM — Art Appreciation (415B)
''';
  }

  void _loadSampleCvSuCor() {
    _pasteController.text = '''
CAVITE STATE UNIVERSITY
CERTIFICATE OF REGISTRATION
Student No: 2023-10492
Name: DELA CRUZ, JUAN MIGUEL
Course & Section: BSIT-2A
School Year: 2026-2027
Semester: 1st Semester

ITEC 50 Web Systems and Technologies 2.0 1.0 3.0
M/TH 10:00-12:00 CL1/RM.8 LEC/LAB

DCIT 24 Network and Communications 2.0 1.0 3.0
T/F 09:00-11:30 ICT-202 LEC

GNED 04 Pagbasa at Pagsulat sa Iba't Ibang Disiplina 3.0 0.0 3.0
W/S 13:00-14:30 RM 104 LEC

COSC 105 Software Engineering 1 3.0 0.0 3.0
M/TH 13:00-15:00 LAB-3 LEC

TOTAL UNITS: 12.0
''';
  }
}
