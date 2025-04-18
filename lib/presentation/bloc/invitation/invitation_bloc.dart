import 'package:all_at_task/data/models/friend_request.dart';
import 'package:all_at_task/data/models/invitation.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'invitation_event.dart';
part 'invitation_state.dart';

class InvitationBloc extends Bloc<InvitationEvent, InvitationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId;

  InvitationBloc({required this.currentUserId}) : super(InvitationInitial()) {
    on<LoadInvitations>(_onLoadInvitations);
    on<SendFriendRequest>(_onSendFriendRequest);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<RejectFriendRequest>(_onRejectFriendRequest);
    on<SendInvitation>(_onSendInvitation);
    on<AcceptInvitation>(_onAcceptInvitation);
    on<RejectInvitation>(_onRejectInvitation);
    on<RemoveFriend>(_onRemoveFriend);
  }

  Future<void> _onLoadInvitations(
      LoadInvitations event,
      Emitter<InvitationState> emit,
      ) async {
    print('Handling LoadInvitations for currentUserId: $currentUserId');
    emit(InvitationLoading());
    try {
      // Загружаем входящие запросы (pending, userId2 = currentUserId)
      print('Fetching pending friend requests where userId2: $currentUserId');
      final pendingRequestsSnapshot = await _firestore
          .collection('friends')
          .where('userId2', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      print('Found ${pendingRequestsSnapshot.docs.length} pending friend requests');

      // Загружаем друзей (accepted, userId1 = currentUserId)
      print('Fetching accepted friends where userId1: $currentUserId');
      final acceptedRequestsSnapshot1 = await _firestore
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .where('userId1', isEqualTo: currentUserId)
          .get();
      print('Found ${acceptedRequestsSnapshot1.docs.length} accepted friends (userId1)');

      // Загружаем друзей (accepted, userId2 = currentUserId)
      print('Fetching accepted friends where userId2: $currentUserId');
      final acceptedRequestsSnapshot2 = await _firestore
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .where('userId2', isEqualTo: currentUserId)
          .get();
      print('Found ${acceptedRequestsSnapshot2.docs.length} accepted friends (userId2)');

      // Объединяем pending и accepted запросы
      final friendRequests = [
        ...pendingRequestsSnapshot.docs,
        ...acceptedRequestsSnapshot1.docs,
        ...acceptedRequestsSnapshot2.docs,
      ].map((doc) => FriendRequest.fromMap(doc.data())).toList();

      // Загружаем приглашения
      print('Fetching invitations where inviteeId: $currentUserId, status: pending');
      final invitationsSnapshot = await _firestore
          .collection('invitations')
          .where('inviteeId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      print('Found ${invitationsSnapshot.docs.length} invitations');

      final invitations = invitationsSnapshot.docs
          .map((doc) => Invitation.fromMap(doc.data()))
          .toList();

      print('Emitting InvitationLoaded with ${friendRequests.length} friend requests and ${invitations.length} invitations');
      emit(InvitationLoaded(invitations, friendRequests));
    } catch (e) {
      print('Error loading invitations: $e');
      emit(InvitationError('Failed to load invitations: $e'));
    }
  }

  Future<void> _onSendFriendRequest(
      SendFriendRequest event,
      Emitter<InvitationState> emit,
      ) async {
    print('Handling SendFriendRequest for userId: ${event.userId}, currentUserId: $currentUserId');
    try {
      print('Checking if user exists in public_profiles: ${event.userId}');
      final userDoc = await _firestore
          .collection('public_profiles')
          .doc(event.userId)
          .get();
      if (!userDoc.exists) {
        print('User not found in public_profiles: ${event.userId}');
        emit(InvitationError('Пользователь не найден'));
        return;
      }

      print('Checking for existing friend request');
      final existingRequest = await _firestore
          .collection('friends')
          .where('userId1', isEqualTo: currentUserId)
          .where('userId2', isEqualTo: event.userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        print('Existing friend request found');
        emit(InvitationError('Запрос дружбы уже отправлен'));
        return;
      }

      final requestId = const Uuid().v4();
      print('Creating friend request with id: $requestId');
      final friendRequest = FriendRequest(
        id: requestId,
        userId1: currentUserId,
        userId2: event.userId,
        status: 'pending',
        createdAt: Timestamp.now(),
      );

      print('Writing friend request to Firestore: friends/$requestId');
      await _firestore
          .collection('friends')
          .doc(requestId)
          .set(friendRequest.toMap());
      print('Friend request written successfully');

      emit(InvitationSuccess('Запрос дружбы отправлен'));
    } catch (e) {
      print('Error sending friend request: $e');
      emit(InvitationError('Failed to send friend request: $e'));
    }
  }

  Future<void> _onAcceptFriendRequest(
      AcceptFriendRequest event,
      Emitter<InvitationState> emit,
      ) async {
    print('Handling AcceptFriendRequest for requestId: ${event.requestId}');
    try {
      // Обновляем статус запроса на "accepted"
      await _firestore.collection('friends').doc(event.requestId).update({
        'status': 'accepted',
      });
      print('Friend request status updated to accepted: ${event.requestId}');

      // Обновляем состояние, чтобы запрос сразу отобразился в списке друзей
      final currentState = state;
      if (currentState is InvitationLoaded) {
        final updatedRequests = currentState.friendRequests.map((req) {
          if (req.id == event.requestId) {
            return FriendRequest(
              id: req.id,
              userId1: req.userId1,
              userId2: req.userId2,
              status: 'accepted',
              createdAt: req.createdAt,
            );
          }
          return req;
        }).toList();
        emit(InvitationLoaded(currentState.invitations, updatedRequests));
      }
      emit(InvitationSuccess('Запрос дружбы принят'));
    } catch (e) {
      print('Error accepting friend request: $e');
      emit(InvitationError('Failed to accept friend request: $e'));
    }
  }

  Future<void> _onRejectFriendRequest(
      RejectFriendRequest event,
      Emitter<InvitationState> emit,
      ) async {
    print('Handling RejectFriendRequest for requestId: ${event.requestId}');
    try {
      await _firestore.collection('friends').doc(event.requestId).delete();
      print('Friend request deleted: ${event.requestId}');

      final currentState = state;
      if (currentState is InvitationLoaded) {
        final updatedRequests = currentState.friendRequests
            .where((req) => req.id != event.requestId)
            .toList();
        emit(InvitationLoaded(currentState.invitations, updatedRequests));
      }
      emit(InvitationSuccess('Запрос дружбы отклонен'));
    } catch (e) {
      print('Error rejecting friend request: $e');
      emit(InvitationError('Failed to reject friend request: $e'));
    }
  }

  Future<void> _onSendInvitation(
      SendInvitation event,
      Emitter<InvitationState> emit,
      ) async {
    print('Handling SendInvitation for listId: ${event.listId}, inviteeId: ${event.inviteeId}');
    try {
      final listDoc = await _firestore
          .collection('lists')
          .doc(event.listId)
          .get();
      if (!listDoc.exists) {
        emit(InvitationError('Список не найден'));
        return;
      }

      final userDoc = await _firestore
          .collection('public_profiles')
          .doc(event.inviteeId)
          .get();
      if (!userDoc.exists) {
        emit(InvitationError('Пользователь не найден'));
        return;
      }

      final invitationId = const Uuid().v4();
      final invitation = Invitation(
        id: invitationId,
        listId: event.listId,
        inviteeId: event.inviteeId,
        inviterId: currentUserId,
        status: 'pending',
        createdAt: Timestamp.now(),
      );

      await _firestore
          .collection('invitations')
          .doc(invitationId)
          .set(invitation.toMap());
      print('Invitation written successfully: $invitationId');

      emit(InvitationSuccess('Приглашение отправлено'));
    } catch (e) {
      print('Error sending invitation: $e');
      emit(InvitationError('Failed to send invitation: $e'));
    }
  }

  Future<void> _onAcceptInvitation(
      AcceptInvitation event,
      Emitter<InvitationState> emit,
      ) async {
    print('Handling AcceptInvitation for invitationId: ${event.invitationId}');
    try {
      final invitationDoc = await _firestore
          .collection('invitations')
          .doc(event.invitationId)
          .get();
      if (!invitationDoc.exists) {
        emit(InvitationError('Приглашение не найдено'));
        return;
      }
      final invitation = Invitation.fromMap(invitationDoc.data()!);

      await _firestore.collection('invitations').doc(event.invitationId).update({
        'status': 'accepted',
      });

      await _firestore.collection('lists').doc(invitation.listId).update({
        'members.$currentUserId': 'viewer',
      });

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('lists')
          .doc(invitation.listId)
          .set({
        'listId': invitation.listId,
        'addedAt': Timestamp.now(),
      });

      final currentState = state;
      if (currentState is InvitationLoaded) {
        final updatedInvitations = currentState.invitations
            .where((inv) => inv.id != event.invitationId)
            .toList();
        emit(InvitationLoaded(updatedInvitations, currentState.friendRequests));
      }
      emit(InvitationSuccess('Приглашение принято'));
    } catch (e) {
      print('Error accepting invitation: $e');
      emit(InvitationError('Failed to accept invitation: $e'));
    }
  }

  Future<void> _onRejectInvitation(
      RejectInvitation event,
      Emitter<InvitationState> emit,
      ) async {
    print('Handling RejectInvitation for invitationId: ${event.invitationId}');
    try {
      await _firestore.collection('invitations').doc(event.invitationId).delete();
      print('Invitation deleted: ${event.invitationId}');

      final currentState = state;
      if (currentState is InvitationLoaded) {
        final updatedInvitations = currentState.invitations
            .where((inv) => inv.id != event.invitationId)
            .toList();
        emit(InvitationLoaded(updatedInvitations, currentState.friendRequests));
      }
      emit(InvitationSuccess('Приглашение отклонено'));
    } catch (e) {
      print('Error rejecting invitation: $e');
      emit(InvitationError('Failed to reject invitation: $e'));
    }
  }

  Future<void> _onRemoveFriend(
      RemoveFriend event,
      Emitter<InvitationState> emit,
      ) async {
    print('Handling RemoveFriend for requestId: ${event.requestId}');
    try {
      await _firestore.collection('friends').doc(event.requestId).delete();
      print('Friend removed successfully: ${event.requestId}');

      final currentState = state;
      if (currentState is InvitationLoaded) {
        final updatedRequests = currentState.friendRequests
            .where((req) => req.id != event.requestId)
            .toList();
        emit(InvitationLoaded(currentState.invitations, updatedRequests));
      }
      emit(InvitationSuccess('Друг удалён'));
    } catch (e) {
      print('Error removing friend: $e');
      emit(InvitationError('Не удалось удалить друга: $e'));
    }
  }
}