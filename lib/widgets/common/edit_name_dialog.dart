import 'package:flutter/material.dart';

Future<String?> showEditNameDialog(
  BuildContext context, {
  required String initialValue,
  bool autofocus = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _EditNameDialog(initialValue: initialValue, autofocus: autofocus),
  );
}

class _EditNameDialog extends StatefulWidget {
  final String initialValue;
  final bool autofocus;

  const _EditNameDialog({required this.initialValue, required this.autofocus});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.length >= 2) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edytuj profil'),
      content: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        maxLength: 50,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(labelText: 'Nazwa użytkownika'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Zapisz')),
      ],
    );
  }
}
