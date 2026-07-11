import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

// ponytail: Cloudflare R2 via S3v4 signing (stdlib crypto). Credentials via --dart-define.
// Build: flutter build ... --dart-define=R2_KEY=... --dart-define=R2_SECRET=... --dart-define=R2_ENDPOINT=https://...
class R2Storage {
  static final _accessKey = const String.fromEnvironment('R2_KEY');
  static final _secretKey = const String.fromEnvironment('R2_SECRET');
  static final _endpoint = const String.fromEnvironment('R2_ENDPOINT');
  static const _bucket = 'album-media';
  static const _region = 'auto';

  Future<void> upload(String path, File file) async {
    final bytes = await file.readAsBytes();
    final uri = Uri.parse('$_endpoint/$_bucket/$path');
    final date = DateTime.now().toUtc();
    final dateStr = _dateStr(date);
    final datetimeStr = _datetimeStr(date);

    final client = HttpClient();
    final req = await client.putUrl(uri);
    req.headers.contentType = ContentType('application', 'octet-stream');
    req.headers.set('host', uri.host);
    req.headers.set('x-amz-date', datetimeStr);
    req.headers.set('x-amz-content-sha256', sha256.convert(bytes).toString());

    final signedHeaders = 'content-type;host;x-amz-content-sha256;x-amz-date';
    final payloadHash = sha256.convert(bytes).toString();
    final canonicalRequest = 'PUT\n/$_bucket/$path\n\ncontent-type:application/octet-stream\nhost:${uri.host}\nx-amz-content-sha256:$payloadHash\nx-amz-date:$datetimeStr\n\n$signedHeaders\n$payloadHash';
    final scope = '$dateStr/$_region/s3/aws4_request';
    final stringToSign = 'AWS4-HMAC-SHA256\n$datetimeStr\n$scope\n${sha256.convert(utf8.encode(canonicalRequest)).toString()}';

    final signingKey = _hmacSha256(
      _hmacSha256(_hmacSha256(_hmacSha256(utf8.encode('aws4$_secretKey'), dateStr), _region), 's3'), 'aws4_request');
    final signature = _hmacSha256Hex(signingKey, stringToSign);
    req.headers.set('Authorization', 'AWS4-HMAC-SHA256 Credential=$_accessKey/$scope,SignedHeaders=$signedHeaders,Signature=$signature');

    req.contentLength = bytes.length;
    req.add(bytes);
    final resp = await req.close();
    if (resp.statusCode != 200) {
      final body = await resp.transform(utf8.decoder).join();
      throw Exception('R2 upload failed: ${resp.statusCode} $body');
    }
  }

  String publicUrl(String path) => '$_endpoint/$_bucket/$path';

  static List<int> _hmacSha256(List<int> key, String msg) => Hmac(sha256, key).convert(utf8.encode(msg)).bytes;
  static String _hmacSha256Hex(List<int> key, String msg) => Hmac(sha256, key).convert(utf8.encode(msg)).toString();
  static String _dateStr(DateTime d) => '${d.year}${d.month.toString().padLeft(2,'0')}${d.day.toString().padLeft(2,'0')}';
  static String _datetimeStr(DateTime d) => '${_dateStr(d)}T${d.hour.toString().padLeft(2,'0')}${d.minute.toString().padLeft(2,'0')}${d.second.toString().padLeft(2,'0')}Z';
}
