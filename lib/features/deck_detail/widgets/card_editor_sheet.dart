import 'package:flutter/material.dart';

import '../../../data/models/flashcard.dart';
import '../../shared/widgets/app_button.dart';

/// Opens a sheet to write a new flashcard, or edit [card] when given.
///
/// Returns the question and answer, or null if the sheet was dismissed.
Future<({String question, String answer})?> showCardEditorSheet(
  BuildContext context, {
  Flashcard? card,
}) {
  return showModalBottomSheet<({String question, String answer})>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CardEditorSheet(card: card),
  );
}

class _CardEditorSheet extends StatefulWidget {
  final Flashcard? card;
  const _CardEditorSheet({this.card});

  @override
  State<_CardEditorSheet> createState() => _CardEditorSheetState();
}

class _CardEditorSheetState extends State<_CardEditorSheet> {
  late final TextEditingController _question;
  late final TextEditingController _answer;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _question = TextEditingController(text: widget.card?.question ?? '');
    _answer = TextEditingController(text: widget.card?.answer ?? '');
  }

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      (question: _question.text.trim(), answer: _answer.text.trim()),
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'This can\'t be empty' : null;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.card != null;

    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Edit card' : 'New card',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _question,
              autofocus: !isEditing,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Question'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _answer,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Answer',
                alignLabelWithHint: true,
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: isEditing ? 'Save card' : 'Add card',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
