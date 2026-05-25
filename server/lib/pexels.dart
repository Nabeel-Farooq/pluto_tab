import 'dart:math';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:pexels/pexels.dart' as pexels;
import 'package:server/utils.dart';
import 'package:shared/shared.dart';

import 'base/env.dart';

Future<pexels.Photo?> randomPexelsImage({
  required PexelsSource source,
}) async {
  final String? pexelsApiKey = env['PEXLES_API_KEY'];

  if (pexelsApiKey == null || pexelsApiKey.trim().isEmpty) {
    throw StateError('PEXLES_API_KEY is missing.');
  }

  final client = pexels.PexelsClient(
    apiKey: pexelsApiKey,
    client: InterceptedClient.build(
      interceptors: [
        LoggerInterceptor(),
      ],
    ),
  );

  try {
    switch (source) {
      case PexelsSearchSource source:
        final randomPage = _randomPage();

        final result = await client.searchPhotos(
          query: source.query.trim(),
          page: randomPage,
          perPage: 1,
          orientation: 'landscape',
        );

        return result.photos.firstOrNull;

      case PexelsRandomSource():
        final randomPage = _randomPage();

        final result = await client.getCuratedPhotos(
          page: randomPage,
          perPage: 1,
        );

        return result.photos.firstOrNull;
    }
  } catch (error, stacktrace) {
    print('Error fetching Pexels image: $error');
    print(stacktrace);

    return null;
  } finally {
    client.close();
  }
}

int _randomPage() {
  return Random().nextInt(100) + 1;
}
