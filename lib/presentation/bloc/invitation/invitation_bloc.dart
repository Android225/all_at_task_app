import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:all_at_task/data/models/friend_request.dart';
import 'package:all_at_task/data/models/invitation.dart';

part 'invitation_event.dart';
part 'invitation_state.dart';

class InvitationBloc extends Bloc<InvitationEvent, InvitationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  InvitationBloc() : super(InvitationInitial()) {
    on<LoadInvitations>(_onLoadInvitations);
    on<SendFriendRequest>(_onSendFriendRequest);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<RejectFriendRequest>(_onRejectFriendRequest);
    on<AcceptInvitation>(_onAcceptInvitation);
    on<RejectInvitation>(_onRejectInvitation);
  }

  Future<void> _onLoadInvitations(LoadInvitations event, Emitter<InvitationState> emit) async {
    emit(InvitationLoading());
    try {
      final userId = _auth.currentUser!.uid;
      final invitationsSnapshot = await _firestore
          .collection('invitations')
          .where('inviteeId', isEqualTo: userId)
          .get();
      final friendRequestsSnapshot = await _firestore
          .collection('friends')
          .where('userId2', isEqualTo: userId)
          .get();
      final invitations = invitationsSnapshot.docs.map((doc) => Invitation.fromMap(doc.data())).toList();
      final friendRequests = friendRequestsSnapshot.docs.map((doc) => FriendRequest.fromMap(doc.data())).toList();
      emit(InvitationLoaded(invitations, friendRequests));
    } catch (e) {
      emit(InvitationError('Не удалось загрузить приглашения: попробуйте позже'));
    }
  }

  Future<void> _onSendFriendRequest(SendFriendRequest event, Emitter<InvitationState> emit) async {
    try {
      final requestId = const Uuid().v4();
      final request = FriendRequest(
        id: requestId,
        userId1: _auth.currentUser!.uid,
        userId2: event.userId,
        status: 'pending',
        createdAt: Timestamp.now(),
      );
      await _firestore.collection('friends').doc(requestId).set(request.toMap());
      add(LoadInvitations());
    } catch (e) {
      emit(InvitationError('Не удалось отправить запрос: попробуйте позже'));
    }
  }

  Future<void> _onAcceptFriendRequest(AcceptFriendRequest event, Emitter<InvitationState> emit) async {
    try {
      await _firestore.collection('friends').doc(event.requestId).update({
        'status': 'accepted',
      });
      add(LoadInvitations());
    } catch (e) {
      emit(InvitationError('Не удалось принять запрос: попробуйте позже'));
    }
  }

  Future<void> _onRejectFriendRequest(RejectFriendRequest event, Emitter<InvitationState> emit) async {
    try {
      await _firestore.collection('friends').doc(event.requestId).update({
        'status': 'rejected',
      });
      add(LoadInvitations());
    } catch (e) {
      emit(InvitationError('Не удалось отклонить запрос: попробуйте позже'));
    }
  }

  Future<void> _onAcceptInvitation(AcceptInvitation event, Emitter<InvitationState> emit) async {
    try {
      final invitationSnapshot = await _firestore.collection('invitations').doc(event.invitationId).get();
      final invitation = Invitation.fromMap(invitationSnapshot.data()!);
      await _firestore.collection('invitations').doc(event.invitationId).update({
        'status': 'accepted',
      });
      await _firestore.collection('lists').doc(invitation.listId).update({
        'members.${_auth.currentUser!.uid}': 'viewer',
      });
      add(LoadInvitations());
    } catch (e) {
      emit(InvitationError('Не удалось принять приглашение: попробуйте позже'));
    }
  }

  Future<void> _onRejectInvitation(RejectInvitation event, Emitter<InvitationState> emit) async {
    try {
      await _firestore.collection('invitations').doc(event.invitationId).update({
        'status': 'rejected',
      });
      add(LoadInvitations());
    } catch (e) {
      emit(InvitationError('Не удалось отклонить приглашение: попробуйте позже'));
    }
  }
}