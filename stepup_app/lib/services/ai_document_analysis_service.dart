import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';
import '../models/category.dart' as app_models;
import 'ai_config_service.dart';

/// 文档分析结果 - 分类建议
class CategorySuggestion {
  final String name;
  final String code;
  final String description;
  final String color;
  final String icon;
  final List<SubcategorySuggestion> subcategories;
  final String reasoning;

  const CategorySuggestion({
    required this.name,
    required this.code,
    required this.description,
    required this.color,
    required this.icon,
    required this.subcategories,
    required this.reasoning,
  });

  factory CategorySuggestion.fromJson(Map<String, dynamic> json) {
    final subcategoriesData = json['subcategories'] as List<dynamic>? ?? [];
    final subcategories = subcategoriesData
        .map((s) => SubcategorySuggestion.fromJson(s as Map<String, dynamic>))
        .toList();

    return CategorySuggestion(
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? '#2196F3',
      icon: json['icon'] as String? ?? 'category',
      subcategories: subcategories,
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'color': color,
      'icon': icon,
      'subcategories': subcategories.map((s) => s.toJson()).toList(),
      'reasoning': reasoning,
    };
  }
}

/// 子分类建议
class SubcategorySuggestion {
  final String name;
  final String code;
  final String description;

  const SubcategorySuggestion({
    required this.name,
    required this.code,
    required this.description,
  });

  factory SubcategorySuggestion.fromJson(Map<String, dynamic> json) {
    return SubcategorySuggestion(
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'description': description,
    };
  }
}

/// 文档分析结果
class DocumentAnalysisResult {
  final String documentTitle;
  final String documentSummary;
  final List<CategorySuggestion> suggestedCategories;
  final String analysisNotes;
  final DateTime analyzedAt;

  const DocumentAnalysisResult({
    required this.documentTitle,
    required this.documentSummary,
    required this.suggestedCategories,
    required this.analysisNotes,
    required this.analyzedAt,
  });

  factory DocumentAnalysisResult.fromJson(Map<String, dynamic> json) {
    final categoriesData = json['suggested_categories'] as List<dynamic>? ?? [];
    final categories = categoriesData
        .map((c) => CategorySuggestion.fromJson(c as Map<String, dynamic>))
        .toList();

    return DocumentAnalysisResult(
      documentTitle: json['document_title'] as String? ?? '未知文档',
      documentSummary: json['document_summary'] as String? ?? '',
      suggestedCategories: categories,
      analysisNotes: json['analysis_notes'] as String? ?? '',
      analyzedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document_title': documentTitle,
      'document_summary': documentSummary,
      'suggested_categories': suggestedCategories.map((c) => c.toJson()).toList(),
      'analysis_notes': analysisNotes,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }
}

/// AI文档分析服务
class AIDocumentAnalysisService {
  static const String _model = 'deepseek-chat';

  final String? apiKey;
  final String? baseUrl;
  final AIConfigService _configService = AIConfigService();

  AIDocumentAnalysisService({
    this.apiKey,
    this.baseUrl,
  });

  /// 从PDF文件提取文本
  Future<String> extractTextFromPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      final document = await PdfDocument.openFile(filePath);
      final textBuffer = StringBuffer();
      
      for (final page in document.pages) {
        final pageText = await page.loadText();
        final textString = pageText?.fullText ?? '';
        if (textString.isNotEmpty) {
          textBuffer.writeln(textString);
        }
      }
      
      document.dispose();
      
      final extractedText = textBuffer.toString();
      if (extractedText.isEmpty) {
        throw Exception('无法从PDF文件中提取文本内容');
      }

      return extractedText;
    } catch (e) {
      throw Exception('PDF文本提取失败: $e');
    }
  }

  /// 分析综测评定文档
  ///
  /// [filePath] - PDF文件路径
  /// [existingCategories] - 现有分类列表（用于参考和避免重复）
  Future<DocumentAnalysisResult> analyzeDocument({
    required String filePath,
    List<app_models.Category>? existingCategories,
  }) async {
    // 提取PDF文本
    final documentText = await extractTextFromPdf(filePath);

    // 截取文本（避免超出API限制）
    final maxTextLength = 64000;
    
    // Debug: 输出提取的文本长度
    debugPrint('========== PDF文本提取结果 ==========');
    debugPrint('提取文本总长度: ${documentText.length} 字符');
    debugPrint('最大允许长度: $maxTextLength 字符');
    
    final truncatedText = documentText.length > maxTextLength
        ? '${documentText.substring(0, maxTextLength)}\n...(文档内容已截断，原文共${documentText.length}字符)'
        : documentText;
    
    if (documentText.length > maxTextLength) {
      debugPrint('警告: 文档内容已截断，仅使用前 $maxTextLength 字符进行分析');
    }
    debugPrint('======================================');

    // 构建提示词
    final prompt = _buildAnalysisPrompt(
      documentText: truncatedText,
      existingCategories: existingCategories ?? [],
    );

    // 调用AI API
    final response = await _callDeepSeekAPI(prompt);

    // 解析结果
    return _parseAnalysisResponse(response);
  }

  /// 构建分析提示词
  String _buildAnalysisPrompt({
    required String documentText,
    required List<app_models.Category> existingCategories,
  }) {
    final existingCategoriesJson = existingCategories.map((c) => {
      'name': c.name,
      'code': c.code,
      'description': c.description,
    }).toList();

    return '''你是一个大学生综合测评系统的智能分析助手。请分析用户上传的综测评定红头文件，并根据文件内容生成分类建议。

## 现有分类体系（仅供参考，避免重复）
${existingCategories.isNotEmpty ? const JsonEncoder.withIndent('  ').convert(existingCategoriesJson) : '暂无现有分类'}

## 文档内容
$documentText

## 分析要求

请仔细阅读文档内容，提取以下信息：

1. **文档标题**：识别文档的正式名称
2. **文档摘要**：简要概括文档的主要内容和评定规则
3. **分类建议**：根据文档内容，建议的分类体系

### 分类建议格式要求

每个分类应包含：
- name: 分类名称（如"德育"、"智育"等）
- code: 分类代码（如"D"、"Z"等，使用中文拼音首字母）
- description: 分类描述
- color: 颜色代码（十六进制，如"#E91E63"）
- icon: 图标名称（使用Material Icons名称，如"favorite"、"school"等）
- subcategories: 子分类列表
- reasoning: 建议该分类的理由

每个子分类应包含：
- name: 子分类名称
- code: 子分类代码（如"D01"、"D02"等）
- description: 子分类描述

### 颜色建议
- 德育类: #E91E63 (粉色)
- 智育类: #2196F3 (蓝色)
- 体育类: #4CAF50 (绿色)
- 学术科研类: #9C27B0 (紫色)
- 组织管理类: #FF5722 (橙色)
- 劳动实践类: #FF9800 (琥珀色)
- 美育类: #607D8B (蓝灰色)
- 其他: #9E9E9E (灰色)

## 请返回以下 JSON 格式的结果

```json
{
  "document_title": "文档标题",
  "document_summary": "文档摘要，简要概括文档的主要内容和评定规则",
  "suggested_categories": [
    {
      "name": "分类名称",
      "code": "分类代码",
      "description": "分类描述",
      "color": "#颜色代码",
      "icon": "图标名称",
      "subcategories": [
        {
          "name": "子分类名称",
          "code": "子分类代码",
          "description": "子分类描述"
        }
      ],
      "reasoning": "建议该分类的理由"
    }
  ],
  "analysis_notes": "其他分析说明或注意事项"
}
```

注意：
1. 只返回 JSON，不要返回其他内容
2. 确保所有字段都有值
3. 分类和子分类应基于文档内容提取，不要凭空捏造
4. 如果文档中提到的分类与现有分类相似，可以在reasoning中说明
5. 代码应简洁明了，便于识别和管理''';
  }

  /// 调用 DeepSeek API
  Future<String> _callDeepSeekAPI(String prompt) async {
    final configApiKey = apiKey ?? await _configService.getApiKey();
    final configBaseUrl = baseUrl ?? await _configService.getBaseUrl();

    if (configApiKey == null || configApiKey.isEmpty) {
      throw Exception('未配置 DeepSeek API Key，请在设置中配置');
    }

    final url = Uri.parse('$configBaseUrl/v1/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $configApiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '你是一个专业的大学生综合测评文档分析助手，擅长从红头文件中提取分类信息并生成结构化的分类建议。',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'max_tokens': 4000,
        }),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('DeepSeek API 请求超时，请检查网络连接或稍后重试');
        },
      );

      if (response.statusCode != 200) {
        throw HttpException(
          'DeepSeek API 调用失败: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;

      if (choices.isEmpty) {
        throw Exception('DeepSeek API 返回结果为空');
      }

      final message = choices[0]['message'] as Map<String, dynamic>;
      return message['content'] as String;
    } on SocketException catch (e) {
      throw Exception('网络连接失败: $e');
    } on TimeoutException catch (e) {
      throw Exception('请求超时: $e');
    } on FormatException catch (e) {
      throw Exception('响应数据格式错误: $e');
    } catch (e) {
      throw Exception('调用 DeepSeek API 时发生错误: $e');
    }
  }

  /// 解析分析响应
  DocumentAnalysisResult _parseAnalysisResponse(String response) {
    try {
      String jsonStr = response;

      final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(response);
      if (codeBlockMatch != null) {
        jsonStr = codeBlockMatch.group(1)!.trim();
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final result = DocumentAnalysisResult.fromJson(json);
      
      // Debug: 输出解析结果
      debugPrint('========== AI文档分析结果 ==========');
      debugPrint('文档标题: ${result.documentTitle}');
      debugPrint('文档摘要: ${result.documentSummary}');
      debugPrint('建议分类数量: ${result.suggestedCategories.length}');
      for (int i = 0; i < result.suggestedCategories.length; i++) {
        final cat = result.suggestedCategories[i];
        debugPrint('分类${i + 1}: ${cat.name} (${cat.code})');
        debugPrint('  描述: ${cat.description}');
        debugPrint('  子分类数量: ${cat.subcategories.length}');
        for (final sub in cat.subcategories) {
          debugPrint('    - ${sub.code}: ${sub.name}');
        }
        debugPrint('  理由: ${cat.reasoning}');
      }
      debugPrint('分析说明: ${result.analysisNotes}');
      debugPrint('====================================');
      
      return result;
    } catch (e) {
      throw FormatException('解析 AI 响应失败: $e\n原始响应: $response');
    }
  }
}
