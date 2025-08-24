import 'package:flutter/foundation.dart';

// 事件类型
enum AppEvent {
  assessmentItemChanged, // 条目数据变更
  categoryChanged,       // 分类数据变更
}

// 简单的事件总线
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final Map<AppEvent, List<VoidCallback>> _listeners = {};

  // 添加监听器
  void on(AppEvent event, VoidCallback callback) {
    _listeners[event] ??= [];
    _listeners[event]!.add(callback);
  }

  // 移除监听器
  void off(AppEvent event, VoidCallback callback) {
    _listeners[event]?.remove(callback);
  }

  // 触发事件
  void emit(AppEvent event) {
    final callbacks = _listeners[event];
    if (callbacks != null) {
      for (final callback in callbacks) {
        callback();
      }
    }
  }

  // 清理所有监听器
  void clear() {
    _listeners.clear();
  }
}