import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/chat_repository.dart';
import '../../screens/training/exercise_detail_screen.dart';

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
          onPressed: () => _openChat(context),
          child: ClipOval(
            child: Image.network(
              ApiConfig.mediaUrl('assistant-logo'),
              width: 31,
              height: 31,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.chat_bubble_outline_rounded,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openChat(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final token = auth.sessionToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para usar el asistente.')),
      );
      return;
    }

    final profile = context.read<AppStateProvider>().profile;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ChatSheet(
        token: token,
        section: section.label,
        goal: profile.goal,
      ),
    );
  }
}

class _ChatSheet extends StatefulWidget {
  const _ChatSheet({required this.token, required this.section, required this.goal});

  final String token;
  final String section;
  final String goal;

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _controller = TextEditingController();
  final _repository = ChatRepository();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: message, fromUser: true));
      _sending = true;
    });

    try {
      final response = await _repository.sendMessage(
        token: widget.token,
        message: message,
        section: widget.section,
        goal: widget.goal,
      );
      if (!mounted) return;
      setState(
        () => _messages.add(
          _ChatMessage(
            text: response.message,
            fromUser: false,
            exercises: response.exercises,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(
        text: 'No pude consultar al asistente: $error',
        fromUser: false,
      )));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                ClipOval(
                  child: Image.network(
                    ApiConfig.mediaUrl('assistant-logo'),
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Asistente FITTRACK', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              Text('Contexto: ${widget.section} · Objetivo: ${widget.goal}', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
              const SizedBox(height: 12),
              Expanded(
                child: _messages.isEmpty
                    ? const Center(child: Text('Pregúntame por ejercicios, sustituciones o recomendaciones.', textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final item = _messages[index];
                          return Align(
                            alignment: item.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: item.fromUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: const BoxConstraints(maxWidth: 520),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: item.fromUser ? AppColors.primary : AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(item.text),
                              ),
                                if (item.exercises.isNotEmpty)
                                  ...item.exercises.map(
                                    (exercise) => _RecommendedExerciseCard(
                                      exercise: exercise,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (_sending) const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'Escribe tu pregunta...'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.send_rounded)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromUser,
    this.exercises = const [],
  });

  final String text;
  final bool fromUser;
  final List<Exercise> exercises;
}

class _RecommendedExerciseCard extends StatelessWidget {
  const _RecommendedExerciseCard({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 520,
      constraints: const BoxConstraints(maxWidth: 520),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExerciseDetailScreen(exercise: exercise),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 88,
                height: 88,
                child: exercise.imageUrl == null
                    ? const ColoredBox(
                        color: Color(0xFF123B2C),
                        child: Icon(
                          Icons.fitness_center_outlined,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      )
                    : Image.network(
                        exercise.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFF123B2C),
                          child: Icon(
                            Icons.fitness_center_outlined,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.muscleCategory} · ${exercise.sets} series × ${exercise.recommendedRepetitions}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    exercise.description.isNotEmpty
                        ? exercise.description
                        : exercise.technique,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toca para ver técnica completa',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
