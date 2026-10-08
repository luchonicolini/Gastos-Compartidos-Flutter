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
  late final TextEditingController _nameController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Ingresá un nombre para el grupo');
      return;
    }

    Navigator.of(context).pop(GroupFormResult(name: name));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEditing ? 'Editar grupo' : 'Nuevo grupo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Nombre del grupo',
              hintText: 'Ej. Viaje a Brasil',
              errorText: _errorText,
              prefixIcon: const Icon(Icons.group_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: Text(isEditing ? 'Guardar cambios' : 'Crear grupo'),
          ),
        ],
      ),
    );
  }
}

