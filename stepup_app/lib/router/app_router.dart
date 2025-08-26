import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/assessment_list_page.dart';
import '../pages/assessment_form_page.dart';
import '../pages/statistics_page.dart';
import '../pages/categories_page.dart';
import '../pages/settings_page.dart';
import '../pages/image_preview_page.dart';
import '../pages/document_preview_page.dart';
import '../pages/category_detail_page.dart';
import '../pages/user_onboarding_page.dart';
import '../pages/first_time_welcome_page.dart';
import '../pages/user_profile_edit_page.dart';
import '../models/category.dart';

class AppRouter {
  // 初始路由，默认是首页
  static String _initialLocation = '/home';
  
  // 设置初始路由
  static void setInitialRoute(String route) {
    _initialLocation = route;
  }
  
  static final GoRouter router = GoRouter(
    initialLocation: _initialLocation,
    routes: [
      // 用户引导页面（独立页面）
  GoRoute(
    path: '/onboarding',
    name: 'onboarding',
    builder: (context, state) => const UserOnboardingPage(),
  ),
  // 首次欢迎页面（简化版）
  GoRoute(
    path: '/welcome',
    name: 'welcome',
    builder: (context, state) => const FirstTimeWelcomePage(),
  ),
  // 用户信息编辑页面
  GoRoute(
    path: '/profile/edit',
    name: 'profile-edit',
    builder: (context, state) => const UserProfileEditPage(),
  ),
      // 底部导航栏的主要页面
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationPage(navigationShell: navigationShell);
        },
        branches: [
          // 首页分支
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          // 综测条目分支
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assessment',
                name: 'assessment',
                builder: (context, state) => const AssessmentListPage(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'assessment-add',
                    builder: (context, state) => const AssessmentFormPage(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    name: 'assessment-edit',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return AssessmentFormPage(itemId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // 统计分支
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                name: 'statistics',
                builder: (context, state) => const StatisticsPage(),
              ),
            ],
          ),
          // 分类管理分支
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                name: 'categories',
                builder: (context, state) => const CategoriesPage(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    name: 'category-detail',
                    builder: (context, state) {
                      final categoryData = state.extra as Category?;
                      if (categoryData == null) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('错误')),
                          body: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 64, color: Colors.red),
                                SizedBox(height: 16),
                                Text('缺少分类数据'),
                              ],
                            ),
                          ),
                        );
                      }
                      return CategoryDetailPage(category: categoryData);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // 设置页面（独立页面）
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      // 图片预览页面
      GoRoute(
        path: '/image-preview',
        name: 'image-preview',
        builder: (context, state) {
          final imagePath = state.uri.queryParameters['path'];
          final title = state.uri.queryParameters['title'];
          
          if (imagePath == null || imagePath.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('错误')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('缺少图片路径参数'),
                  ],
                ),
              ),
            );
          }
          
          return ImagePreviewPage(
            imagePath: imagePath,
            title: title,
          );
        },
      ),
      // 文档预览页面
      GoRoute(
        path: '/document-preview',
        name: 'document-preview',
        builder: (context, state) {
          final documentPath = state.uri.queryParameters['path'];
          final title = state.uri.queryParameters['title'];
          
          if (documentPath == null || documentPath.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('错误')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('缺少文档路径参数'),
                  ],
                ),
              ),
            );
          }
          
          return DocumentPreviewPage(
            documentPath: documentPath,
            title: title,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '页面未找到: ${state.uri}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
}

// 主导航页面，包含底部导航栏
class MainNavigationPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationPage({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: '综测',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: '分类',
          ),
        ],
      ),
    );
  }
}