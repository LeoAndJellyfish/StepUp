import 'package:flutter_test/flutter_test.dart';
import 'package:stepup_app/services/data_export_service.dart';

void main() {
  group('DataExportService', () {
    late DataExportService dataExportService;

    setUp(() {
      // 初始化服务
      dataExportService = DataExportService();
    });

    test('导出服务实例化测试', () {
      expect(dataExportService, isNotNull);
      expect(dataExportService, isA<DataExportService>());
    });

    test('导出数据功能测试', () async {
      // 简单测试导出方法是否存在
      expect(dataExportService.exportAllData, isNotNull);
      expect(dataExportService.exportAllData, isA<Function>());
    });

    test('导入数据功能测试', () async {
      // 简单测试导入方法是否存在
      expect(dataExportService.importData, isNotNull);
      expect(dataExportService.importData, isA<Function>());
    });
  });
}