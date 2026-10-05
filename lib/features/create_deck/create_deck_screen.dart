import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constant/app_colors.dart';
import '../../core/constant/app_sizes.dart';
import '../../core/constant/app_strings.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/providers.dart';
import '../shared/widgets/app_button.dart';
import 'widgets/generating_loader.dart';
import 'widgets/source_picker.dart';

enum SourceMode { text, pdf, image }

class CreateDeckScreen extends ConsumerStatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  ConsumerState<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends ConsumerState<CreateDeckScreen> {
  /// The AI needs at least this much text to work with.
  static const _minSourceLength = 50;

  static const _flashcardChoices = [5, 10, 15, 20];
  static const _quizChoices = [3, 5, 10];

  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  SourceMode _mode = SourceMode.text;
  File? _pdfFile;
  File? _imageFile;

  int _flashcardCount = 10;
  int _quizCount = 5;

  bool _loading = false;
  List<String> _steps = const [];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Keeps the character count under the text box up to date.
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      setState(() {
        _pdfFile = File(files.first.path!);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 90);
    if (xfile != null) {
      setState(() => _imageFile = File(xfile.path));
    }
  }

  /// Switching to PDF opens the file picker straight away if nothing has
  /// been chosen yet, so it's one tap as before.
  Future<void> _selectMode(SourceMode mode) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _mode = mode);
    if (mode == SourceMode.pdf && _pdfFile == null) {
      await _pickPdf();
    }
  }

  Future<void> _generate() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Give your deck a title first.');
      return;
    }
    if (_mode == SourceMode.pdf && _pdfFile == null) {
      _showError('Choose a PDF first.');
      return;
    }
    if (_mode == SourceMode.image && _imageFile == null) {
      _showError('Take or choose a photo of your notes first.');
      return;
    }

    const writeStep = 'Writing flashcards and quiz';
    setState(() {
      _loading = true;
      _currentStep = 0;
      switch (_mode) {
        case SourceMode.text:
          _steps = const [writeStep];
          break;
        case SourceMode.pdf:
          _steps = const ['Reading your PDF', writeStep];
          break;
        case SourceMode.image:
          _steps = const ['Reading the text in your photo', writeStep];
          break;
      }
    });

    // Extract source text
    String sourceText = '';
    try {
      switch (_mode) {
        case SourceMode.text:
          sourceText = _textController.text.trim();
          break;
        case SourceMode.pdf:
          sourceText =
              await ref.read(pdfServiceProvider).extractText(_pdfFile!);
          break;
        case SourceMode.image:
          sourceText = await ref
              .read(ocrServiceProvider)
              .extractTextFromImage(_imageFile!);
          break;
      }
    } catch (e) {
      _stopLoading();
      _showError('Could not read your material: $e');
      return;
    }

    if (sourceText.trim().length < _minSourceLength) {
      _stopLoading();
      _showError(_mode == SourceMode.text
          ? 'Add a little more text: at least $_minSourceLength characters.'
          : 'Not enough text was found. Try a clearer file or photo.');
      return;
    }

    // Generate
    if (!mounted) return;
    setState(() => _currentStep = _steps.length - 1);

    try {
      final deck = await ref.read(deckRepositoryProvider).createDeckFromText(
            title: title,
            sourceText: sourceText,
            flashcardCount: _flashcardCount,
            quizCount: _quizCount,
          );
      ref.read(decksProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck created')),
      );
      // Open the new deck in place of this screen.
      context.pushReplacement('/deck/${deck.id}');
    } on MissingApiKeyException {
      _stopLoading();
      _showError(AppStrings.errorApiKey);
    } catch (e) {
      _stopLoading();
      _showError('The deck could not be generated: $e');
    }
  }

  void _stopLoading() {
    if (mounted) setState(() => _loading = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Leaving mid-generation would lose the deck.
      canPop: !_loading,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: const Text(AppStrings.newDeck)),
            body: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.deckTitle,
                    hintText: 'e.g. Biology, chapter 5',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSizes.lg),

                // Source
                Text(AppStrings.sourceType, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SourcePicker(mode: _mode, onModeChanged: _selectMode),
                const SizedBox(height: 12),
                _buildSourceInput(context),
                const SizedBox(height: AppSizes.lg),

                // How much to generate
                Text('How much should it make?',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _CountPicker(
                  label: 'Flashcards',
                  choices: _flashcardChoices,
                  selected: _flashcardCount,
                  onSelected: (v) => setState(() => _flashcardCount = v),
                ),
                const SizedBox(height: 8),
                _CountPicker(
                  label: 'Quiz questions',
                  choices: _quizChoices,
                  selected: _quizCount,
                  onSelected: (v) => setState(() => _quizCount = v),
                ),
              ],
            ),
            // The main action stays in reach, above the keyboard.
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: AppStrings.generate,
                      icon: Icons.auto_awesome,
                      onPressed: _loading ? null : _generate,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your notes are sent to Google Gemini to make the deck.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: GeneratingLoader(steps: _steps, currentStep: _currentStep),
            ),
        ],
      ),
    );
  }

  /// The input under the source tiles: a text box, the chosen PDF, or the
  /// chosen photo.
  Widget _buildSourceInput(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    switch (_mode) {
      case SourceMode.text:
        final length = _textController.text.trim().length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              maxLines: 9,
              minLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Paste your notes, a textbook passage, or any '
                    'study material here.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              length < _minSourceLength
                  ? '$length characters. At least $_minSourceLength needed.'
                  : '$length characters',
              style: theme.textTheme.bodySmall,
            ),
          ],
        );

      case SourceMode.pdf:
        final file = _pdfFile;
        if (file == null) {
          return OutlinedButton.icon(
            onPressed: _pickPdf,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Choose a PDF'),
          );
        }
        return _PickedFileRow(
          leading: Icon(Icons.picture_as_pdf_outlined,
              color: theme.colorScheme.primary),
          name: file.path.split('/').last,
          onReplace: _pickPdf,
          onRemove: () => setState(() => _pdfFile = null),
        );

      case SourceMode.image:
        final file = _imageFile;
        if (file == null) {
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A preview, so it's clear which photo will be read.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Container(
                height: 180,
                color: palette.tint,
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            _PickedFileRow(
              leading:
                  Icon(Icons.image_outlined, color: theme.colorScheme.primary),
              name: file.path.split('/').last,
              onReplace: () => setState(() => _imageFile = null),
              replaceLabel: 'Change',
              onRemove: () => setState(() => _imageFile = null),
            ),
          ],
        );
    }
  }
}

/// A row showing the chosen file with actions to swap or remove it.
class _PickedFileRow extends StatelessWidget {
  final Widget leading;
  final String name;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  final String replaceLabel;

  const _PickedFileRow({
    required this.leading,
    required this.name,
    required this.onReplace,
    required this.onRemove,
    this.replaceLabel = 'Replace',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: context.palette.tint,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TextButton(onPressed: onReplace, child: Text(replaceLabel)),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// A label with a row of number chips, one of which is selected.
class _CountPicker extends StatelessWidget {
  final String label;
  final List<int> choices;
  final int selected;
  final ValueChanged<int> onSelected;

  const _CountPicker({
    required this.label,
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Wrap(
          spacing: 6,
          children: [
            for (final value in choices)
              ChoiceChip(
                label: Text('$value'),
                selected: value == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}
