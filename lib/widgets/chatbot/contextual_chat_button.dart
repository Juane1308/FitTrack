import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/chat_repository.dart';

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
          child: const Icon(Icons.chat_bubble_outline_rounded),
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
      setState(() => _messages.add(_ChatMessage(text: response, fromUser: false)));
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
                const Icon(Icons.auto_awesome, color: AppColors.primary),
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
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 520),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: item.fromUser ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(item.text),
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
  const _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}
