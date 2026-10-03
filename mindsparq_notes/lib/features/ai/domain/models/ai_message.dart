class AiMessage {
  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final String? actionType;
  final String? proposedReplacement;
  final bool isLoading;

  const AiMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.actionType,
    this.proposedReplacement,
    this.isLoading = false,
  });

  AiMessage copyWith({
    String? id,
    bool? isUser,
    String? text,
    DateTime? timestamp,
    String? actionType,
    String? proposedReplacement,
    bool? isLoading,
  }) {
    return AiMessage(
      id: id ?? this.id,
      isUser: isUser ?? this.isUser,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      actionType: actionType ?? this.actionType,
      proposedReplacement: proposedReplacement ?? this.proposedReplacement,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
