class AiMessage {
  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final String? actionType;
  final String? proposedReplacement;
  final bool isLoading;
  final String? attachedFilePath;
  final String? attachedFileName;

  const AiMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.actionType,
    this.proposedReplacement,
    this.isLoading = false,
    this.attachedFilePath,
    this.attachedFileName,
  });

  AiMessage copyWith({
    String? id,
    bool? isUser,
    String? text,
    DateTime? timestamp,
    String? actionType,
    String? proposedReplacement,
    bool? isLoading,
    String? attachedFilePath,
    String? attachedFileName,
  }) {
    return AiMessage(
      id: id ?? this.id,
      isUser: isUser ?? this.isUser,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      actionType: actionType ?? this.actionType,
      proposedReplacement: proposedReplacement ?? this.proposedReplacement,
      isLoading: isLoading ?? this.isLoading,
      attachedFilePath: attachedFilePath ?? this.attachedFilePath,
      attachedFileName: attachedFileName ?? this.attachedFileName,
    );
  }
}
