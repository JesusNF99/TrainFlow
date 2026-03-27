import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../data/models/exercise.dart';

/// Modal bottom sheet for adding a new exercise to a routine.
/// Returns an [Exercise] object via [Navigator.pop] when the user confirms.
class AddExerciseSheet extends StatefulWidget {
  const AddExerciseSheet({super.key});

  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  ExerciseType _type = ExerciseType.time;
  int _value = 30;
  int _restTime = 15;
  bool _soundAlert = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final exercise = Exercise()
      ..name = _nameController.text.trim()
      ..type = _type
      ..value = _value
      ..restTime = _restTime
      ..soundAlert = _soundAlert;
    Navigator.of(context).pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Sheet handle ---
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text('Nuevo Ejercicio', style: AppTextStyles.titleLarge),
              const SizedBox(height: 20),

              // --- Exercise Name ---
              TextFormField(
                controller: _nameController,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onBackground,
                ),
                decoration: const InputDecoration(labelText: 'Nombre del ejercicio'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 16),

              // --- Type toggle ---
              Text('Tipo', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              _TypeToggle(
                value: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 16),

              // --- Value ---
              _NumberField(
                label: _type == ExerciseType.time ? 'Duración (seg)' : 'Repeticiones',
                initialValue: _value,
                onChanged: (v) => setState(() => _value = v),
              ),
              const SizedBox(height: 16),

              // --- Rest Time ---
              _NumberField(
                label: 'Descanso (seg)',
                initialValue: _restTime,
                onChanged: (v) => setState(() => _restTime = v),
              ),
              const SizedBox(height: 16),

              // --- Sound alert toggle ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alerta de sonido', style: AppTextStyles.bodyMedium),
                  Switch(
                    value: _soundAlert,
                    onChanged: (v) => setState(() => _soundAlert = v),
                    activeThumbColor: AppColors.cyan,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Confirm button ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _submit();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'AGREGAR',
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.value, required this.onChanged});

  final ExerciseType value;
  final ValueChanged<ExerciseType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ExerciseType.values.map((type) {
          final isSelected = type == value;
          final label = type == ExerciseType.time ? 'Tiempo' : 'Repeticiones';
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0x2600F5FF) : Colors.transparent, // 15% cyan instead of solid
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected ? Border.all(color: const Color(0x4D00F5FF)) : null,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.cyan : AppColors.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final int initialValue;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onBackground),
      decoration: InputDecoration(labelText: widget.label),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null && parsed >= 0) widget.onChanged(parsed);
      },
      validator: (v) {
        if (v == null || int.tryParse(v) == null) return 'Ingresa un número';
        return null;
      },
    );
  }
}
