import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/level.dart';
import 'ai_config_service.dart';

/// AI 分类结果
class AIClassificationResult {
  final int? categoryId;
  final int? subcategoryId;
  final int? levelId;
  final double? suggestedDuration;
  final bool? isAwarded;
  final String? awardLevel;
  final bool? isCollective;
  final bool? isLeader;
  final int? participantCount;
  final String reasoning;
  final double confidence;

  const AIClassificationResult({
    this.categoryId,
    this.subcategoryId,
    this.levelId,
    this.suggestedDuration,
    this.isAwarded,
    this.awardLevel,
    this.isCollective,
    this.isLeader,
    this.participantCount,
    required this.reasoning,
    required this.confidence,
  });

  factory AIClassificationResult.fromJson(Map<String, dynamic> json) {
    return AIClassificationResult(
      categoryId: json['category_id'] as int?,
      subcategoryId: json['subcategory_id'] as int?,
      levelId: json['level_id'] as int?,
      suggestedDuration: json['suggested_duration'] != null
          ? (json['suggested_duration'] as num).toDouble()
          : null,
      isAwarded: json['is_awarded'] as bool?,
      awardLevel: json['award_level'] as String?,
      isCollective: json['is_collective'] as bool?,
      isLeader: json['is_leader'] as bool?,
      participantCount: json['participant_count'] as int?,
      reasoning: json['reasoning'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// DeepSeek AI 分类服务
class AIClassificationService {
  static const String _model = 'deepseek-chat';

  final String? apiKey;
  final String? baseUrl;
  final AIConfigService _configService = AIConfigService();

  AIClassificationService({
    this.apiKey,
    this.baseUrl,
  });

  /// 智能分类条目
  ///
  /// [title] - 活动名称
  /// [description] - 活动描述
  /// [categories] - 可用的分类列表
  /// [subcategories] - 可用的子分类列表
  /// [levels] - 可用的等级列表
  Future<AIClassificationResult> classifyItem({
    required String title,
    required String description,
    required List<Category> categories,
    required List<Subcategory> subcategories,
    required List<Level> levels,
  }) async {
    final prompt = _buildClassificationPrompt(
      title: title,
      description: description,
      categories: categories,
      subcategories: subcategories,
      levels: levels,
    );

    final response = await _callDeepSeekAPI(prompt);
    return _parseAIResponse(response);
  }

  /// 构建分类提示词
  String _buildClassificationPrompt({
    required String title,
    required String description,
    required List<Category> categories,
    required List<Subcategory> subcategories,
    required List<Level> levels,
  }) {
    final categoriesJson = categories.map((c) => {
      'id': c.id,
      'name': c.name,
      'code': c.code,
      'description': c.description,
    }).toList();

    final subcategoriesJson = subcategories.map((s) => {
      'id': s.id,
      'category_id': s.categoryId,
      'name': s.name,
      'code': s.code,
      'description': s.description,
    }).toList();

    final levelsJson = levels.map((l) => {
      'id': l.id,
      'name': l.name,
      'code': l.code,
      'description': l.description,
    }).toList();

    return '''你是一个大学生综合测评系统的智能分类助手。请根据用户输入的活动信息，自动识别并推荐最合适的分类。

## 可用的分类体系

### 分类（Categories）
${const JsonEncoder.withIndent('  ').convert(categoriesJson)}

### 子分类（Subcategories）
${const JsonEncoder.withIndent('  ').convert(subcategoriesJson)}

### 等级（Levels）
${const JsonEncoder.withIndent('  ').convert(levelsJson)}

## 用户输入的活动信息

活动名称：$title
活动描述：$description

## 请分析并返回以下 JSON 格式的结果

```json
{
  "category_id": <分类ID，从可用分类中选择最匹配的一个>,
  "subcategory_id": <子分类ID，如适用则选择，否则为null>,
  "level_id": <等级ID，如适用则选择，否则为null>,
  "suggested_duration": <建议的时长（小时），如可从描述中推断则填写，否则为null>,
  "is_awarded": <是否获奖，true/false/null>,
  "award_level": <获奖等级，如"一等奖"、"金奖"等，否则为null>,
  "is_collective": <是否代表集体，true/false/null>,
  "is_leader": <是否为负责人，true/false/null>,
  "participant_count": <参与人数，如可推断则填写，否则为null>,
  "reasoning": "<分类理由的详细说明>",
  "confidence": <置信度，0.0-1.0之间的数值>
}
```

注意：
1. 如果无法确定某个字段，请将其设为 null
2. confidence 表示你对分类结果的置信程度
3. reasoning 请用中文详细说明分类依据
4. 只返回 JSON，不要返回其他内容'''
    ;
  }

  /// 调用 DeepSeek API
  Future<String> _callDeepSeekAPI(String prompt) async {
    // 获取配置
    final configApiKey = apiKey ?? await _configService.getApiKey();
    final configBaseUrl = baseUrl ?? await _configService.getBaseUrl();

    if (configApiKey == null || configApiKey.isEmpty) {
      throw Exception('未配置 DeepSeek API Key，请在设置中配置');
    }

    final url = Uri.parse('$configBaseUrl/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $configApiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': '你是一个专业的大学生综合测评分类助手，擅长根据活动描述自动识别分类。'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      }),
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
  }

  /// 解析 AI 响应
  AIClassificationResult _parseAIResponse(String response) {
    try {
      // 提取 JSON 内容（处理可能的 markdown 代码块）
      String jsonStr = response;

      // 如果响应包含 markdown 代码块，提取其中的 JSON
      final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(response);
      if (codeBlockMatch != null) {
        jsonStr = codeBlockMatch.group(1)!.trim();
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AIClassificationResult.fromJson(json);
    } catch (e) {
      throw FormatException('解析 AI 响应失败: $e\n原始响应: $response');
    }
  }
}
