import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class ContextualChatButton extends StatelessWidget {
  const ContextualChatButton({required this.section, super.key});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 18,
      bottom: 16,
      child: Semantics(
        button: true,
        label: 'Abrir asistente virtual de ${section.label}',
        child: FloatingActionButton(
          heroTag: 'contextual-chat-button',
          tooltip: 'Asistente virtual',
          onPressed: () => _showChatPreview(context),
          child: const Icon(Icons.chat_bubble_outline_rounded),
        ),
      ),
    );
  }

  void _showChatPreview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Asistente FITTRACK',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Contexto actual: ${section.label}'),
                const SizedBox(height: 8),
                const Text(
                  'La interfaz del chatbot está preparada. La conversación MOCK se implementará en la etapa 8.',
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
