import 'dart:convert';

import 'package:http/http.dart' as http;

class CepLocation {
  final String neighborhood;
  final double? latitude;
  final double? longitude;

  const CepLocation({
    required this.neighborhood,
    required this.latitude,
    required this.longitude,
  });

  bool get hasCoordinates {
    return latitude != null &&
        longitude != null;
  }
}

class CepService {
  CepService._();

  static const String _brasilApiBaseUrl =
      'https://brasilapi.com.br/api/cep/v2';

  static const String _viaCepBaseUrl =
      'https://viacep.com.br/ws';

  static Future<CepLocation> getLocation(
    String cep,
  ) async {
    final normalizedCep = _normalizeCep(
      cep,
    );

    try {
      final brasilApiLocation =
          await _getFromBrasilApi(
        normalizedCep,
      );

      if (brasilApiLocation != null) {
        return brasilApiLocation;
      }
    } catch (_) {}

    return _getFromViaCep(
      normalizedCep,
    );
  }

  static Future<String> getNeighborhood(
    String cep,
  ) async {
    final location = await getLocation(
      cep,
    );

    return location.neighborhood;
  }

  static String _normalizeCep(
    String cep,
  ) {
    final normalizedCep = cep.replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (normalizedCep.length != 8) {
      throw FormatException(
        'CEP inválido.',
      );
    }

    return normalizedCep;
  }

  static Future<CepLocation?>
      _getFromBrasilApi(
    String cep,
  ) async {
    final uri = Uri.parse(
      '$_brasilApiBaseUrl/$cep',
    );

    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(
      utf8.decode(
        response.bodyBytes,
      ),
    );

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final neighborhood =
        decoded['neighborhood']
                ?.toString()
                .trim() ??
            '';

    if (neighborhood.isEmpty) {
      return null;
    }

    final location = decoded['location'];

    double? latitude;
    double? longitude;

    if (location is Map) {
      final coordinates =
          location['coordinates'];

      if (coordinates is Map) {
        latitude = _toDouble(
          coordinates['latitude'],
        );

        longitude = _toDouble(
          coordinates['longitude'],
        );
      }
    }

    return CepLocation(
      neighborhood: neighborhood,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static Future<CepLocation>
      _getFromViaCep(
    String cep,
  ) async {
    final uri = Uri.parse(
      '$_viaCepBaseUrl/$cep/json/',
    );

    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode != 200) {
      throw StateError(
        'Não foi possível consultar o CEP.',
      );
    }

    final decoded = jsonDecode(
      utf8.decode(
        response.bodyBytes,
      ),
    );

    if (decoded is! Map<String, dynamic>) {
      throw StateError(
        'Resposta inválida ao consultar o CEP.',
      );
    }

    if (decoded['erro'] == true) {
      throw FormatException(
        'CEP não encontrado.',
      );
    }

    final neighborhood =
        decoded['bairro']
                ?.toString()
                .trim() ??
            '';

    if (neighborhood.isEmpty) {
      throw StateError(
        'Bairro não encontrado para este CEP.',
      );
    }

    return CepLocation(
      neighborhood: neighborhood,
      latitude: null,
      longitude: null,
    );
  }

  static double? _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(
        value.trim(),
      );

      if (parsed != null &&
          parsed.isFinite) {
        return parsed;
      }
    }

    return null;
  }
}