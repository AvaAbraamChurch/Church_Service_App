abstract class MessageState {}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageSent extends MessageState {}

class MessageError extends MessageState {
  final String error;

  MessageError(this.error);
}

class MessagesLoaded extends MessageState {
  final List messages;

  MessagesLoaded(this.messages);
}

class MessageUpdated extends MessageState {}

class MessageDeleted extends MessageState {}

class ConversationLoaded extends MessageState {
  final List conversation;

  ConversationLoaded(this.conversation);
}

class ConversationError extends MessageState {
  final String error;

  ConversationError(this.error);
}

class MessageSeenUpdated extends MessageState {}

class LastMessageLoaded extends MessageState {
  final dynamic lastMessage;

  LastMessageLoaded(this.lastMessage);
}

class LastMessageError extends MessageState {
  final String error;

  LastMessageError(this.error);
}

class RecentConversationsLoaded extends MessageState {
  final List recentConversations;

  RecentConversationsLoaded(this.recentConversations);
}

class RecentConversationsError extends MessageState {
  final String error;

  RecentConversationsError(this.error);
}

class MessageDeletedInConversation extends MessageState {}

class MessageDeletionError extends MessageState {
  final String error;

  MessageDeletionError(this.error);
}