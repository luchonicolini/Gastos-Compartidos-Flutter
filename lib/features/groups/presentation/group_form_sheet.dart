import 'package:flutter/material.dart';

class GroupFormResult {
  const GroupFormResult({required this.name});

  final String name;
}

class GroupFormSheet extends StatefulWidget {
  const GroupFormSheet({super.key, this.initialName});

  final String? initialName;

  @override
  State<GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<GroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _nameFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      _nameFocus.requestFocus();
      return;
    }
    final name = _nameController.text.trim();
    Navigator.of(context).pop(GroupFormResult(name: name));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
        child: Form(
          key: _formKey,
          child: FocusTraversalGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Editar grupo' : 'Nuevo grupo',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey<String>('close-group-form'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancelar',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey<String>('group-name-field'),
                  controller: _nameController,
                  focusNode: _nameFocus,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresá un nombre para el grupo'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del grupo',
                    hintText: 'Ej. Viaje a Brasil',
                    helperText: ' ',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const ValueKey<String>('save-group-form'),
                  onPressed: _submit,
                  child: Text(isEditing ? 'Guardar cambios' : 'Crear grupo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
