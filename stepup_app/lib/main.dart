import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'dart:ffi';
import 'dart:io';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/database_helper.dart';
import 'services/file_manager.dart';
import 'services/user_dao.dart';
import 'providers/theme_provider.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 初始化pdfrx
    pdfrxFlutterInitialize();

    // 在桌面平台上初始化FFI数据库
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 应用 sqlite3_flutter_libs 提供的动态库
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      // Windows 平台需要加载 sqlite3.dll
      if (Platform.isWindows) {
        try {
          final script = File(Platform.script.toFilePath());
          final libraryNextToScript = File('${script.parent.path}/sqlite3.dll');
          if (libraryNextToScript.existsSync()) {
            open.overrideForAll(() => DynamicLibrary.open(libraryNextToScript.path));
          }
        } catch (e) {
          debugPrint('加载本地 sqlite3.dll 失败，将使用系统库: $e');
        }
      }
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // 为Windows平台设置UI样式
    if (Platform.isWindows) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      );
    }

    // 初始化应用数据，添加超时保护
    await _initializeApp().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('应用初始化超时，请检查以下问题：\n'
            '1. 磁盘是否有足够空间\n'
            '2. 是否有写入权限\n'
            '3. 杀毒软件是否阻止了应用运行');
      },
    );

    runApp(const MyApp());
  } catch (e, stackTrace) {
    // 捕获所有初始化错误，显示错误页面
    debugPrint('应用初始化失败: $e');
    debugPrint('堆栈跟踪: $stackTrace');
    runApp(ErrorApp(error: e.toString(), stackTrace: stackTrace.toString()));
  }
}

/// 初始化应用数据
Future<void> _initializeApp() async {
  // 初始化数据库
  final databaseHelper = DatabaseHelper();
  await databaseHelper.database; // 这会触发数据库创建或升级

  // 迁移现有的证明材料文件到应用data目录
  final fileManager = FileManager();
  await fileManager.migrateProofMaterials();

  // 检查是否存在用户
  final userDao = UserDao();
  final hasUser = await userDao.hasUsers();

  // 设置初始路由
  if (!hasUser) {
    AppRouter.setInitialRoute('/welcome');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseHelper>(
          create: (context) => DatabaseHelper(),
        ),
        Provider<UserDao>(
          create: (context) => UserDao(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'StepUp 综合测评系统',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.materialThemeMode,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// 错误提示页面
/// 当应用初始化失败时显示，帮助用户诊断问题
class ErrorApp extends StatelessWidget {
  final String error;
  final String stackTrace;

  const ErrorApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StepUp - 启动错误',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: ErrorPage(error: error, stackTrace: stackTrace),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 错误详情页面
class ErrorPage extends StatelessWidget {
  final String error;
  final String stackTrace;

  const ErrorPage({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用启动失败'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '抱歉，应用无法正常启动',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '这可能是由以下原因导致的：',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSuggestionItem('1. 磁盘空间不足', '请确保系统盘有至少 100MB 的可用空间'),
            _buildSuggestionItem('2. 权限问题', '请尝试以管理员身份运行应用'),
            _buildSuggestionItem('3. 杀毒软件拦截', '请将本应用添加到杀毒软件的白名单中'),
            _buildSuggestionItem('4. 数据文件损坏', '尝试删除应用目录下的 data 文件夹后重新启动'),
            const SizedBox(height: 24),
            const Text(
              '错误详情：',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    error,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // 尝试重新启动应用
                  _restartApp();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _restartApp() {
    // 简单的重新加载方式
    // 在实际生产环境中，可能需要使用更复杂的方式重启应用
    exit(0);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and used to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
