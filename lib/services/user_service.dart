import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  UserService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String cep,
    double? latitude,
    double? longitude,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'cep': cep.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (latitude != null) {
      data['latitude'] = latitude;
    }

    if (longitude != null) {
      data['longitude'] = longitude;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .set(data);
  }

  static Future<Map<String, dynamic>?> getUserProfile(
    String uid,
  ) async {
    final document = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!document.exists) {
      return null;
    }

    return document.data();
  }

  static Stream<Map<String, dynamic>?> watchUserProfile(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
      (document) {
        if (!document.exists) {
          return null;
        }

        return document.data();
      },
    );
  }

  static Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String cep,
    double? latitude,
    double? longitude,
  }) async {
    final normalizedName = name.trim();

    final userReference =
        _firestore.collection('users').doc(uid);

    final ownRequests = await _firestore
        .collection('requests')
        .where(
          'userId',
          isEqualTo: uid,
        )
        .get();

    final helpOffers = await _firestore
        .collection('helpOffers')
        .where(
          'helperId',
          isEqualTo: uid,
        )
        .get();

    final acceptedRequests = await _firestore
        .collection('requests')
        .where(
          'acceptedHelperId',
          isEqualTo: uid,
        )
        .get();

    final batch = _firestore.batch();

    final userData = <String, dynamic>{
      'name': normalizedName,
      'cep': cep.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (latitude != null) {
      userData['latitude'] = latitude;
    }

    if (longitude != null) {
      userData['longitude'] = longitude;
    }

    batch.update(
      userReference,
      userData,
    );

    for (final document in ownRequests.docs) {
      batch.update(
        document.reference,
        {
          'userName': normalizedName,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );
    }

    for (final document in helpOffers.docs) {
      batch.update(
        document.reference,
        {
          'helperName': normalizedName,
        },
      );
    }

    for (final document in acceptedRequests.docs) {
      batch.update(
        document.reference,
        {
          'acceptedHelperName':
              normalizedName,
        },
      );
    }

    await batch.commit();
  }
}