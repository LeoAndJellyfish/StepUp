import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepup_app/models/file_attachment.dart';

void main() {
  group('JSON Serialization Tests', () {
    test('Map with integer keys should be converted to string keys for JSON serialization', () {
      // 创建一个带有整数键的Map
      final Map<int, List<dynamic>> testMap = {
        1: [1, 2, 3],
        2: ['a', 'b', 'c'],
      };
      
      // 将整数键转换为字符串键
      final Map<String, List<dynamic>> sanitizedMap = testMap.map(
        (key, value) => MapEntry(key.toString(), value)
      );
      
      // 测试JSON序列化
      final jsonString = jsonEncode(sanitizedMap);
      expect(jsonString, isNotNull);
      expect(jsonString.contains('"1":[1,2,3]'), isTrue);
      expect(jsonString.contains('"2":["a","b","c"]'), isTrue);
    });
    
    test('FileAttachment should be properly serialized to JSON', () {
      // 创建一个FileAttachment对象
      final attachment = FileAttachment(
        id: 1,
        assessmentItemId: 2,
        fileName: 'test.jpg',
        filePath: '/path/to/test.jpg',
        fileType: 'image',
        fileSize: 1024,
        mimeType: 'image/jpeg',
        uploadedAt: DateTime.now(),
      );
      
      // 转换为Map
      final map = attachment.toMap();
      
      // 处理DateTime值
      final processedMap = map.map((key, value) {
        if (value is DateTime) {
          return MapEntry(key, value.toIso8601String());
        }
        return MapEntry(key, value);
      });
      
      // 测试JSON序列化
      final jsonString = jsonEncode(processedMap);
      expect(jsonString, isNotNull);
      expect(jsonString.contains('"file_name":"test.jpg"'), isTrue);
      expect(jsonString.contains('"assessment_item_id":2'), isTrue);
    });
    
    test('Complex nested structure should be properly serialized', () {
      // 创建复杂的嵌套结构
      final Map<int, List<Map<String, dynamic>>> complexMap = {
        1: [
          {
            'id': 1,
            'name': 'Test',
            'date': DateTime.now(),
          }
        ]
      };
      
      // 处理嵌套结构
      final sanitizedMap = <String, List<Map<String, dynamic>>>{};
      complexMap.forEach((key, value) {
        sanitizedMap[key.toString()] = value.map((item) {
          return item.map((k, v) {
            if (v is DateTime) {
              return MapEntry(k, v.toIso8601String());
            }
            return MapEntry(k, v);
          });
        }).toList();
      });
      
      // 测试JSON序列化
      final jsonString = jsonEncode(sanitizedMap);
      expect(jsonString, isNotNull);
      expect(jsonString.contains('"1":['), isTrue);
      expect(jsonString.contains('"name":"Test"'), isTrue);
      // 确保日期被正确序列化
      expect(jsonString.contains('"date":"'), isTrue);
    });
  });
}