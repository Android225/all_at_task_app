part of 'invitation_bloc.dart';

@immutable
sealed class InvitationState {}

final class InvitationInitial extends InvitationState {}

final class InvitationLoading extends InvitationState {}

final class InvitationLoaded extends InvitationState {
  final List<Invitation> invitations;
  final List<FriendRequest> friendRequests;

  InvitationLoaded(this.invitations, this.friendRequests);
}

final class InvitationError extends InvitationState {
  final String message;

  InvitationError(this.message);
}