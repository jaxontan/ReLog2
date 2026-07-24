/// In-app legal document viewer
library legal.presentation.views.legal_document_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../app/design/design_system.dart';

/// Legal document types
enum LegalDocumentType {
  privacyPolicy,
  userAgreement,
}

/// Screen to display legal documents (Privacy Policy, User Agreement)
class LegalDocumentScreen extends ConsumerStatefulWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({super.key, required this.type});

  static const String privacyPolicyRoute = '/legal/privacy';
  static const String userAgreementRoute = '/legal/terms';

  @override
  ConsumerState<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends ConsumerState<LegalDocumentScreen> {
  bool _loading = true;
  String _markdown = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final assetPath = widget.type == LegalDocumentType.privacyPolicy
          ? 'assets/legal/privacy_policy.md'
          : 'assets/legal/user_agreement.md';

      final content = await rootBundle.loadString(assetPath);
      if (mounted) {
        setState(() {
          _markdown = content;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load document: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final title = widget.type == LegalDocumentType.privacyPolicy
        ? 'Privacy Policy'
        : 'User Agreement';

    return DSPage(
      appBar: AppBar(
        title: Text(title, style: DSTypography.titleLarge.copyWith(color: scheme.onSurface)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _ErrorState(message: _error)
              : Markdown(
                  data: _markdown,
                  styleSheet: MarkdownStyleSheet(
                    h1: DSTypography.headlineMedium.copyWith(color: scheme.onSurface, fontWeight: FontWeight.bold),
                    h2: DSTypography.titleLarge.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
                    h3: DSTypography.titleMedium.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
                    p: DSTypography.bodyMedium.copyWith(color: scheme.onSurface),
                    strong: DSTypography.bodyMedium.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
                    em: DSTypography.bodyMedium.copyWith(color: scheme.onSurface, fontStyle: FontStyle.italic),
                    code: DSTypography.bodySmall.copyWith(color: scheme.primary, fontFamily: 'monospace'),
                    codeblockDecoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(DSRadius.md),
                    ),
                    codeblockPadding: const EdgeInsets.all(DSSpacing.md),
                    blockquote: DSTypography.bodyMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    blockquotePadding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.md,
                      vertical: DSSpacing.xs,
                    ),
                    listBullet: DSTypography.bodyMedium.copyWith(color: scheme.onSurface),
                    listIndent: DSSpacing.xl,
                    horizontalRuleDecoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: scheme.outlineVariant, width: 1),
                      ),
                    ),
                    tableHead: DSTypography.labelMedium.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    tableBody: DSTypography.bodySmall.copyWith(color: scheme.onSurface),
                    tableBorder: TableBorder.all(
                      color: scheme.outlineVariant,
                      width: 0.5,
                    ),
                    tableCellsPadding: const EdgeInsets.all(DSSpacing.sm),
                  ),
                  selectable: true,
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      // Could open external links if needed
                    }
                  },
                ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: DSSpacing.md),
            Text('Error loading document', style: DSTypography.titleMedium.copyWith(color: scheme.onSurface)),
            const SizedBox(height: DSSpacing.sm),
            Text(message, style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Navigation extension for BuildContext
extension LegalNavigation on BuildContext {
  void openPrivacyPolicy() {
    Navigator.of(this).push(
      MaterialPageRoute(
        builder: (_) => const LegalDocumentScreen(type: LegalDocumentType.privacyPolicy),
      ),
    );
  }

  void openUserAgreement() {
    Navigator.of(this).push(
      MaterialPageRoute(
        builder: (_) => const LegalDocumentScreen(type: LegalDocumentType.userAgreement),
      ),
    );
  }
}