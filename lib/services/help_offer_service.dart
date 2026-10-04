import 'package:cloud_firestore/cloud_firestore.dart';

class HelpOfferService {
  HelpOfferService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _offers =>
      _firestore.collection('helpOffers');

  static CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('requests');

  static String _offerId({
    required String requestId,
    required String helperId,
  }) {
    return '${requestId}_$helperId';
  }

  static Query<Map<String, dynamic>> _helperOfferQuery({
    required String requestId,
    required String helperId,
  }) {
    return _offers
        .where(
          'requestId',
          isEqualTo: requestId,
        )
        .where(
          'helperId',
          isEqualTo: helperId,
        )
        .limit(1);
  }

  static Future<void> offerHelp({
    required String requestId,
    required String helperId,
    required String helperName,
  }) async {
    final requestDocument = await _requests.doc(requestId).get();

    if (!requestDocument.exists) {
      throw StateError('Pedido não encontrado.');
    }

    final requestData = requestDocument.data();

    if (requestData == null) {
      throw StateError('Pedido inválido.');
    }

    final requestOwnerId = requestData['userId'];

    if (requestOwnerId is! String || requestOwnerId.isEmpty) {
      throw StateError('Responsável pelo pedido não encontrado.');
    }

    if (requestOwnerId == helperId) {
      throw StateError(
        'Você não pode se oferecer para o próprio pedido.',
      );
    }

    final documentId = _offerId(
      requestId: requestId,
      helperId: helperId,
    );

    await _offers.doc(documentId).set({
      'requestId': requestId,
      'requestOwnerId': requestOwnerId,
      'helperId': helperId,
      'helperName': helperName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> hasOfferedHelp({
    required String requestId,
    required String helperId,
  }) async {
    final snapshot = await _helperOfferQuery(
      requestId: requestId,
      helperId: helperId,
    ).get();

    return snapshot.docs.isNotEmpty;
  }

  static Stream<bool> watchHasOfferedHelp({
    required String requestId,
    required String helperId,
  }) {
    return _helperOfferQuery(
      requestId: requestId,
      helperId: helperId,
    ).snapshots().map(
          (snapshot) => snapshot.docs.isNotEmpty,
        );
  }

  static Future<void> removeOffer({
    required String requestId,
    required String helperId,
  }) async {
    final documentId = _offerId(
      requestId: requestId,
      helperId: helperId,
    );

    await _offers.doc(documentId).delete();
  }

  static Stream<List<Map<String, dynamic>>> watchOffersForRequest({
    required String requestId,
    required String requestOwnerId,
  }) {
    return _offers
        .where(
          'requestId',
          isEqualTo: requestId,
        )
        .where(
          'requestOwnerId',
          isEqualTo: requestOwnerId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => {
                  'id': document.id,
                  ...document.data(),
                },
              )
              .toList(),
        );
  }
}