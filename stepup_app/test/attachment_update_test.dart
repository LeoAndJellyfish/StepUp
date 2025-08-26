import 'package:flutter_test/flutter_test.dart';
import 'package:stepup_app/models/file_attachment.dart';

void main() {
  group('FileAttachment Update Logic Tests', () {
    test('FileAttachment equality check', () {
      final attachment1 = FileAttachment(
        id: 1,
        assessmentItemId: 1,
        fileName: 'test.jpg',
        filePath: '/path/to/test.jpg',
        fileType: 'image',
        fileSize: 1024,
        uploadedAt: DateTime.now(),
      );

      final attachment2 = FileAttachment(
        id: 1,
        assessmentItemId: 1,
        fileName: 'test.jpg',
        filePath: '/path/to/test.jpg',
        fileType: 'image',
        fileSize: 1024,
        uploadedAt: DateTime.now(),
      );

      expect(attachment1, equals(attachment2));
    });

    test('FileAttachment inequality check', () {
      final attachment1 = FileAttachment(
        id: 1,
        assessmentItemId: 1,
        fileName: 'test.jpg',
        filePath: '/path/to/test.jpg',
        fileType: 'image',
        fileSize: 1024,
        uploadedAt: DateTime.now(),
      );

      final attachment2 = FileAttachment(
        id: 2,
        assessmentItemId: 1,
        fileName: 'test.jpg',
        filePath: '/path/to/test.jpg',
        fileType: 'image',
        fileSize: 1024,
        uploadedAt: DateTime.now(),
      );

      expect(attachment1, isNot(equals(attachment2)));
    });
  });
}