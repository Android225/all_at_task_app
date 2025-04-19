part of 'invitation_bloc.dart';

abstract class InvitationState extends Equatable {
  const InvitationState();

  @override
  List<Object> get props => [];
}

class InvitationInitial extends InvitationState {}

class InvitationLoading extends InvitationState {}

class InvitationLoaded extends InvitationState {
  final List<Invitation> invitations;
  final List<FriendRequest> pendingFriendRequests; // Запросы в друзья (pending)
  final List<FriendRequest> acceptedFriends; // Друзья (accepted)
  final Map<String, Map<String, dynamic>> listDetails;

  const InvitationLoaded({
    required this.invitations,
    required this.pendingFriendRequests,
    required this.acceptedFriends,
    required this.listDetails,
  });

  @override
  List<Object> get props => [invitations, pendingFriendRequests, acceptedFriends, listDetails];
}

class InvitationSuccess extends InvitationState {
  final String message;

  const InvitationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class InvitationError extends InvitationState {
  final String message;

  const InvitationError(this.message);

  @override
  List<Object> get props => [message];
}