import 'package:random_x/random_x.dart';

class MathTutorAPIClientImpl {
  Future<Response> getUserThumbnails(List<String> userIDs) async {
    final result = <Map<String, dynamic>>[];
    for (final userID in userIDs) {
      await Future.delayed(const Duration(milliseconds: 100));
      result.add({
        'userID': userID,
        'displayName': RndX.generateName(),
        'avatar': 'https://picsum.photos/200/200'
      });
    }
    return Response(result);
  }
}

class Response {
  final data;

  Response(this.data);
}
