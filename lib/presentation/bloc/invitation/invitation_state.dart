part of 'invitation_bloc.dart';

@immutable
sealed class InvitationState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class InvitationInitial extends InvitationState {}

final class InvitationLoading extends InvitationState {}

final class InvitationLoaded extends InvitationState {
  final List<Invitation> invitations;
  final List<FriendRequest> friendRequests;
  final Map<String, Map<String, dynamic>> listDetails; // Добавляем данные списков

  InvitationLoaded(this.invitations, this.friendRequests, [this.listDetails = const {}]);

  @override
  List<Object?> get props => [invitations, friendRequests, listDetails];
}

final class InvitationError extends InvitationState {
  final String message;

  InvitationError(this.message);

  @override
  List<Object?> get props => [message];
}

final class InvitationSuccess extends InvitationState {
  final String message;

  InvitationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}