part of 'invitation_bloc.dart';

@immutable
sealed class InvitationEvent {}

final class LoadInvitations extends InvitationEvent {}

final class SendFriendRequest extends InvitationEvent {
  final String userId;
  SendFriendRequest(this.userId);
}

final class AcceptFriendRequest extends InvitationEvent {
  final String requestId;
  AcceptFriendRequest(this.requestId);
}

final class RejectFriendRequest extends InvitationEvent {
  final String requestId;
  RejectFriendRequest(this.requestId);
}

final class AcceptInvitation extends InvitationEvent {
  final String invitationId;
  AcceptInvitation(this.invitationId);
}

final class RejectInvitation extends InvitationEvent {
  final String invitationId;
  RejectInvitation(this.invitationId);
}