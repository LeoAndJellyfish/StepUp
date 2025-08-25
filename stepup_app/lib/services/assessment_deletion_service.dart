import '../services/assessment_item_dao.dart';
import '../services/file_attachment_dao.dart';
import '../services/tag_dao.dart';
import '../services/file_manager.dart';

/// 评估条目删除服务
/// 负责删除评估条目及其关联的所有数据和文件
class AssessmentItemDeletionService {
  static final AssessmentItemDeletionService _instance = AssessmentItemDeletionService._internal();
  factory AssessmentItemDeletionService() => _instance;
  AssessmentItemDeletionService._internal();

  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final FileAttachmentDao _fileAttachmentDao = FileAttachmentDao();
  final TagDao _tagDao = TagDao();
  final FileManager _fileManager = FileManager();

  /// 完整删除评估条目
  /// 包括：
  /// 1. 删除所有文件附件的物理文件
  /// 2. 删除数据库中的文件附件记录
  /// 3. 删除标签关联
  /// 4. 删除评估条目本身
  Future<void> deleteAssessmentItem(int itemId) async {
    try {
      // 1. 获取所有文件附件
      final attachments = await _fileAttachmentDao.getAttachmentsByItemId(itemId);
      
      // 2. 删除物理文件
      for (final attachment in attachments) {
        await _fileManager.deleteFile(attachment.filePath);
      }
      
      // 3. 删除文件附件记录
      await _fileAttachmentDao.deleteAttachmentsByItemId(itemId);
      
      // 4. 删除标签关联
      await _tagDao.setTagsForAssessmentItem(itemId, []);
      
      // 5. 删除评估条目
      await _assessmentItemDao.deleteItem(itemId);
      
    } catch (e) {
      throw Exception('删除评估条目失败: $e');
    }
  }

  /// 删除单个文件附件
  /// 包括：
  /// 1. 删除物理文件
  /// 2. 删除数据库记录
  Future<void> deleteFileAttachment(int attachmentId) async {
    try {
      // 1. 获取文件附件信息
      final attachment = await _fileAttachmentDao.getAttachmentById(attachmentId);
      if (attachment == null) {
        throw Exception('文件附件不存在');
      }
      
      // 2. 删除物理文件
      await _fileManager.deleteFile(attachment.filePath);
      
      // 3. 删除数据库记录
      await _fileAttachmentDao.deleteAttachment(attachmentId);
      
    } catch (e) {
      throw Exception('删除文件附件失败: $e');
    }
  }

  /// 批量删除评估条目
  Future<List<String>> deleteMultipleItems(List<int> itemIds) async {
    final List<String> errors = [];
    
    for (final itemId in itemIds) {
      try {
        await deleteAssessmentItem(itemId);
      } catch (e) {
        errors.add('删除条目ID $itemId 失败: $e');
      }
    }
    
    return errors;
  }

  /// 清理未使用的文件
  /// 删除不再被任何条目引用的孤立文件
  Future<void> cleanupOrphanedFiles() async {
    try {
      // 获取所有文件附件路径
      final usedFilePaths = await _fileAttachmentDao.getAllFilePaths();
      
      // 清理未使用的文件
      await _fileManager.cleanupUnusedFiles(usedFilePaths);
      
    } catch (e) {
      throw Exception('清理孤立文件失败: $e');
    }
  }
}