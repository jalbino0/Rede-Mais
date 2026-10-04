import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/help_request.dart';
import 'distance_service.dart';

class RequestService {
  RequestService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>
      get _requests =>
          _firestore.collection('requests');

  static Future<HelpRequest> createRequest({
    required String userId,
    required String userName,
    required String title,
    required String description,
    required String category,
    required String neighborhood,
    required double latitude,
    required double longitude,
    required bool isUrgent,
  }) async {
    final document = _requests.doc();

    await document.set({
      'userId': userId,
      'userName': userName.trim(),
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'neighborhood': neighborhood.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'isUrgent': isUrgent,
      'status': 'Ativo',
      'acceptedHelperId': null,
      'acceptedHelperName': null,
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    return HelpRequest(
      id: document.id,
      userId: userId,
      title: title.trim(),
      description: description.trim(),
      category: category,
      userName: userName.trim(),
      neighborhood: neighborhood.trim(),
      latitude: latitude,
      longitude: longitude,
      time: 'Agora',
      isUrgent: isUrgent,
      status: 'Ativo',
    );
  }

  static Future<void> updateRequest(
    HelpRequest request,
  ) async {
    await _requests
        .doc(request.id)
        .update({
      'title': request.title.trim(),
      'description':
          request.description.trim(),
      'category': request.category,
      'neighborhood':
          request.neighborhood.trim(),
      'latitude': request.latitude,
      'longitude': request.longitude,
      'isUrgent': request.isUrgent,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  static Future<void> acceptHelper({
    required String requestId,
    required String helperId,
    required String helperName,
  }) async {
    await _requests
        .doc(requestId)
        .update({
      'status': 'Em andamento',
      'acceptedHelperId': helperId,
      'acceptedHelperName':
          helperName.trim(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  static Future<void> completeRequest({
    required String requestId,
  }) async {
    await _requests
        .doc(requestId)
        .update({
      'status': 'Finalizado',
      'updatedAt':
          FieldValue.serverTimestamp(),
      'completedAt':
          FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteRequest(
    String requestId,
  ) async {
    await _requests
        .doc(requestId)
        .delete();
  }

  static Stream<List<HelpRequest>>
      watchUserRequests(
    String userId,
  ) {
    return _requests
        .where(
          'userId',
          isEqualTo: userId,
        )
        .snapshots()
        .map(
      (snapshot) {
        final documents = [
          ...snapshot.docs,
        ];

        documents.sort(
          (a, b) => _createdAt(b)
              .compareTo(
            _createdAt(a),
          ),
        );

        return documents
            .map(_requestFromDocument)
            .toList();
      },
    );
  }

  static Stream<List<HelpRequest>>
      watchCommunityRequests({
    String? excludeUserId,
    double? userLatitude,
    double? userLongitude,
    double radiusKm =
        DistanceService.defaultRadiusKm,
  }) {
    return _requests.snapshots().map(
      (snapshot) {
        final hasUserLocation =
            userLatitude != null &&
                userLongitude != null;

        final documents =
            snapshot.docs.where(
          (document) {
            final data =
                document.data();

            final userId =
                data['userId']
                        as String? ??
                    '';

            final status =
                data['status']
                        as String? ??
                    'Ativo';

            if (excludeUserId != null &&
                userId == excludeUserId) {
              return false;
            }

            if (status != 'Ativo') {
              return false;
            }

            if (!hasUserLocation) {
              return true;
            }

            final requestLatitude =
                (data['latitude'] as num?)
                    ?.toDouble();

            final requestLongitude =
                (data['longitude'] as num?)
                    ?.toDouble();

            if (requestLatitude == null ||
                requestLongitude == null) {
              return false;
            }

            return DistanceService
                .isWithinRadius(
              userLatitude:
                  userLatitude,
              userLongitude:
                  userLongitude,
              requestLatitude:
                  requestLatitude,
              requestLongitude:
                  requestLongitude,
              radiusKm: radiusKm,
            );
          },
        ).toList();

        documents.sort(
          (a, b) => _createdAt(b)
              .compareTo(
            _createdAt(a),
          ),
        );

        return documents
            .map(_requestFromDocument)
            .toList();
      },
    );
  }

  static Stream<List<HelpRequest>>
      watchAcceptedRequests(
    String helperId,
  ) {
    return _requests.snapshots().map(
      (snapshot) {
        final documents =
            snapshot.docs.where(
          (document) {
            final data =
                document.data();

            final acceptedHelperId =
                data['acceptedHelperId']
                    as String?;

            final status =
                data['status']
                        as String? ??
                    'Ativo';

            if (acceptedHelperId !=
                helperId) {
              return false;
            }

            return status ==
                    'Em andamento' ||
                status == 'Finalizado';
          },
        ).toList();

        documents.sort(
          (a, b) => _createdAt(b)
              .compareTo(
            _createdAt(a),
          ),
        );

        return documents
            .map(_requestFromDocument)
            .toList();
      },
    );
  }

  static HelpRequest
      _requestFromDocument(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final data = document.data();

    final createdAt =
        data['createdAt'];

    DateTime? createdAtDate;

    if (createdAt is Timestamp) {
      createdAtDate =
          createdAt.toDate();
    }

    final acceptedHelperId =
        data['acceptedHelperId']
            ?.toString();

    final acceptedHelperName =
        data['acceptedHelperName']
            ?.toString();

    return HelpRequest(
      id: document.id,
      userId:
          data['userId'] as String? ??
              '',
      title:
          data['title'] as String? ??
              '',
      description:
          data['description']
                  as String? ??
              '',
      category:
          data['category']
                  as String? ??
              'Outros',
      userName:
          data['userName']
                  as String? ??
              'Usuário',
      neighborhood:
          data['neighborhood']
                  as String? ??
              '',
      latitude:
          (data['latitude'] as num?)
                  ?.toDouble() ??
              0,
      longitude:
          (data['longitude'] as num?)
                  ?.toDouble() ??
              0,
      time:
          _formatTime(createdAtDate),
      isUrgent:
          data['isUrgent']
                  as bool? ??
              false,
      status:
          data['status']
                  as String? ??
              'Ativo',
      acceptedHelperId:
          acceptedHelperId
                      ?.isNotEmpty ==
                  true
              ? acceptedHelperId
              : null,
      acceptedHelperName:
          acceptedHelperName
                      ?.isNotEmpty ==
                  true
              ? acceptedHelperName
              : null,
    );
  }

  static DateTime _createdAt(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final createdAt =
        document.data()['createdAt'];

    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  static String _formatTime(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Agora';
    }

    final difference =
        DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
      return 'Agora';
    }

    if (difference.inMinutes < 60) {
      return 'Há ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return 'Há ${difference.inHours} h';
    }

    final days = difference.inDays;

    if (days == 1) {
      return 'Há 1 dia';
    }

    return 'Há $days dias';
  }
}