import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LoanManagementApp());
}

class LoanManagementApp extends StatelessWidget {
  const LoanManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة الصكوك والقروض',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1E3C72),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3C72),
          primary: const Color(0xFF1E3C72),
          secondary: const Color(0xFF2A5298),
        ),
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const LoginPage(),
    );
  }
}

class SafeMemoryStorage {
  static String? _user;
  static String? _pass;

  static void save(String u, String p) {
    _user = u;
    _pass = p;
  }

  static Map<String, String?> get() {
    return {'user': _user, 'pass': _pass};
  }

  static void clear() {
    _user = null;
    _pass = null;
  }
}

final Map<String, String> globalEmployeePasswords = {
  'usama': 'admin964',
  'saif': 'admin964',
};

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final String _firestoreSettingsUrl =
      'https://firestore.googleapis.com/v1/projects/nasiriyaloans/databases/(default)/documents/settings/officers_config';

  @override
  void initState() {
    super.initState();
    _loadSavedUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadSavedUser() {
    try {
      final saved = SafeMemoryStorage.get();
      if (saved['user'] != null && saved['pass'] != null) {
        setState(() {
          _usernameController.text = saved['user']!;
          _passwordController.text = saved['pass']!;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('يرجى كتابة اسم الموظف وكلمة المرور', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool isAuthorized = false;
      bool isAdmin = (username.toLowerCase() == 'usama' ||
          username.toLowerCase() == 'saif');

      if (isAdmin) {
        isAuthorized = true;
      } else {
        final response = await http.get(Uri.parse(_firestoreSettingsUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          var fields = data['fields'] ?? {};
          if (fields['officers'] != null &&
              fields['officers']['arrayValue'] != null) {
            List officersList =
                fields['officers']['arrayValue']['values'] ?? [];
            for (var o in officersList) {
              String val = o['stringValue'] ?? '';
              if (val.trim().toLowerCase() == username.toLowerCase()) {
                isAuthorized = true;
                break;
              }
            }
          }
        }
      }

      String correctPass = globalEmployeePasswords.containsKey(username)
          ? globalEmployeePasswords[username]!
          : '123456';

      if (isAuthorized && password == correctPass) {
        try {
          if (_rememberMe) {
            SafeMemoryStorage.save(username, password);
          } else {
            SafeMemoryStorage.clear();
          }
        } catch (_) {}

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              employeeName: username,
              isAdmin: isAdmin,
              onPasswordChanged: (newPassword) {
                globalEmployeePasswords[username] = newPassword;
              },
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('اسم الموظف أو كلمة المرور غير صحيحة', Colors.redAccent);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('خطأ في الاتصال: تأكد من تفعيل الإنترنت على الهاتف',
          Colors.redAccent);
    }
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.cairo(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      size: 65, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'نظام إدارة الصكوك والقروض',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'فرع الناصرية - بوابة الموظفين',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'تصميم وبرمجة: م. أسامة همام',
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: const Color(0xFF34D399),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 10,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسجيل الدخول',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3C72),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'اسم الموظف',
                            prefixIcon: const Icon(Icons.person_outline,
                                color: Color(0xFF1E3C72)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: ValueKey(_isPasswordVisible),
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: Color(0xFF1E3C72)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xFF1E3C72),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                            ),
                            Text(
                              'تذكرني على هذا الجهاز',
                              style: GoogleFonts.cairo(
                                  fontSize: 14, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3C72),
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    'دخول الحساب',
                                    style: GoogleFonts.cairo(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final String employeeName;
  final bool isAdmin;
  final Function(String) onPasswordChanged;

  const DashboardPage({
    super.key,
    required this.employeeName,
    required this.isAdmin,
    required this.onPasswordChanged,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  String _serverStatus = 'جاري الاتصال بقاعدة بيانات الموقع...';
  Timer? _liveTimer;

  List<Map<String, dynamic>> _uncashedCheques = [];
  List<Map<String, dynamic>> _cashedCheques = [];
  List<String> _branchOfficers = [];

  num _totalUncashedAmount = 0;
  num _totalCashedAmount = 0;

  final String _firestoreLoansUrl =
      'https://firestore.googleapis.com/v1/projects/nasiriyaloans/databases/(default)/documents/loans';
  final String _firestoreSettingsUrl =
      'https://firestore.googleapis.com/v1/projects/nasiriyaloans/databases/(default)/documents/settings/officers_config';

  @override
  void initState() {
    super.initState();
    _fetchLiveFirestoreData();

    _liveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchLiveFirestoreData(isBackground: true);
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveFirestoreData({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        _isLoading = true;
        _serverStatus = widget.isAdmin
            ? 'جاري جلب كافة سجلات الفرع...'
            : 'جاري جلب الصكوك والمجاميع الخاصة بك...';
      });
    }

    try {
      List<String> officersList = [];
      final settingsRes = await http.get(Uri.parse(_firestoreSettingsUrl));
      if (settingsRes.statusCode == 200) {
        final settingsData = json.decode(settingsRes.body);
        var fields = settingsData['fields'] ?? {};
        if (fields['officers'] != null &&
            fields['officers']['arrayValue'] != null) {
          List rawList = fields['officers']['arrayValue']['values'] ?? [];
          for (var o in rawList) {
            String val = o['stringValue'] ?? '';
            if (val.isNotEmpty) officersList.add(val);
          }
        }
      }

      List<Map<String, dynamic>> uncashedList = [];
      List<Map<String, dynamic>> cashedList = [];
      num uncashedSum = 0;
      num cashedSum = 0;

      final response = await http.get(Uri.parse(_firestoreLoansUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('documents')) {
          List docs = data['documents'];

          for (var docItem in docs) {
            var fields = docItem['fields'] ?? {};

            String name = fields['name']?['stringValue'] ?? 'عميل غير مسمى';
            String state = fields['state']?['stringValue'] ?? 'متبقي';
            String cycle = fields['cycle']?['stringValue'] ?? '1';
            String lo = fields['lo']?['stringValue'] ?? '';
            String date = fields['date']?['stringValue'] ??
                fields['checkDate']?['stringValue'] ??
                'غير محدد';

            bool shouldInclude = widget.isAdmin ||
                (lo.trim().toLowerCase() ==
                    widget.employeeName.trim().toLowerCase());

            if (shouldInclude) {
              num amountNum = 0;
              if (fields['amount'] != null) {
                if (fields['amount']['integerValue'] != null) {
                  amountNum =
                      int.parse(fields['amount']['integerValue'].toString());
                } else if (fields['amount']['doubleValue'] != null) {
                  amountNum = fields['amount']['doubleValue'];
                }
              }

              var chequeObj = {
                'customer': name,
                'cycle': 'الدورة $cycle ($lo)',
                'amount': '${_formatCurrency(amountNum)} د.ع',
                'date': date,
              };

              if (state == 'صرف') {
                cashedList.add(chequeObj);
                cashedSum += amountNum;
              } else {
                uncashedList.add(chequeObj);
                uncashedSum += amountNum;
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _branchOfficers = officersList;
          _uncashedCheques = uncashedList;
          _cashedCheques = cashedList;
          _totalUncashedAmount = uncashedSum;
          _totalCashedAmount = cashedSum;
          _isLoading = false;
          _serverStatus = 'محدث الآن (تحديث مباشر من الموقع)';
        });
      }
    } catch (_) {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _serverStatus = 'متصل بالنظام المباشر';
        });
      }
    }
  }

  String _formatCurrency(num amount) {
    if (amount == 0) return '0';
    String str = amount.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  void _openChangePasswordDialog() {
    final passController = TextEditingController();
    bool _isDialogPassVisible = false;
    String? selectedOfficerToReset;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
              widget.isAdmin
                  ? 'إدارة واسترجاع كلمات المرور'
                  : 'تغيير كلمة المرور',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isAdmin) ...[
                  Text(
                      'استرجاع كلمة المرور لموظف (تعليقها وإعادتها إلى 123456):',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedOfficerToReset,
                    hint: Text('اختر الموظف...',
                        style: GoogleFonts.cairo(fontSize: 13)),
                    items: _branchOfficers
                        .map((off) => DropdownMenuItem(
                              value: off,
                              child: Text(off,
                                  style: GoogleFonts.cairo(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedOfficerToReset = val;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: selectedOfficerToReset == null
                          ? null
                          : () {
                              globalEmployeePasswords[selectedOfficerToReset!] =
                                  '123456';
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'تم استرجاع كلمة المرور للموظف ($selectedOfficerToReset) إلى 123456 بنجاح',
                                      style: GoogleFonts.cairo()),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                      child: Text(
                          'استرجاع كلمة المرور للموظف المختار إلى 123456',
                          style: GoogleFonts.cairo(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),
                  Text('تغيير كلمة المرور الخاصة بك كأدمن:',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900)),
                  const SizedBox(height: 6),
                ],
                TextField(
                  key: ValueKey(_isDialogPassVisible),
                  controller: passController,
                  obscureText: !_isDialogPassVisible,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon:
                        const Icon(Icons.lock_reset, color: Color(0xFF1E3C72)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isDialogPassVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey),
                      onPressed: () {
                        setDialogState(() {
                          _isDialogPassVisible = !_isDialogPassVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3C72),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (passController.text.isNotEmpty) {
                  widget.onPasswordChanged(passController.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تحديث كلمة المرور بنجاح وتفعيلها وحدها',
                          style: GoogleFonts.cairo()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text('حفظ',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        title: Text(
            widget.isAdmin
                ? 'لوحة المشرف العام: ${widget.employeeName}'
                : 'حساب الموظف: ${widget.employeeName}',
            style:
                GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'إدارة كلمات المرور',
            onPressed: _openChangePasswordDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1E3C72)),
                  const SizedBox(height: 15),
                  Text(_serverStatus,
                      style: GoogleFonts.cairo(color: Colors.grey.shade700)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchLiveFirestoreData(isBackground: false),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_manual_record,
                              size: 14, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.isAdmin
                                  ? 'مشرف النظام: ${widget.employeeName} | عرض شامل لجميع صكوك الفرع'
                                  : 'الموظف: ${widget.employeeName} | مزامنة فورية مع قاعدة البيانات',
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: const Color(0xFF1E3C72),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'غير مصروفة (${_uncashedCheques.length})',
                            amount:
                                '${_formatCurrency(_totalUncashedAmount)} د.ع',
                            color: Colors.orange.shade800,
                            bgColor: Colors.orange.shade50,
                            icon: Icons.pending_actions_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'مصروفة (${_cashedCheques.length})',
                            amount:
                                '${_formatCurrency(_totalCashedAmount)} د.ع',
                            color: Colors.green.shade800,
                            bgColor: Colors.green.shade50,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.isAdmin
                          ? 'سجل كافة الصكوك غير المصروفة بالفرع'
                          : 'الصكوك غير المصروفة الخاصة بك',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3C72)),
                    ),
                    const SizedBox(height: 8),
                    if (_uncashedCheques.isEmpty)
                      _buildEmptyState('لا توجد صكوك غير مصروفة حالياً')
                    else
                      ..._uncashedCheques
                          .map((c) => _buildChequeTile(c, isCashed: false)),
                    const SizedBox(height: 24),
                    Text(
                      widget.isAdmin
                          ? 'سجل كافة الصكوك المصروفة بالفرع'
                          : 'سجل الصكوك المصروفة الخاصة بك',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3C72)),
                    ),
                    const SizedBox(height: 8),
                    if (_cashedCheques.isEmpty)
                      _buildEmptyState('لا توجد صكوك مصروفة مسجلة حالياً')
                    else
                      ..._cashedCheques
                          .map((c) => _buildChequeTile(c, isCashed: true)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String amount,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 12),
          Text(amount,
              style: GoogleFonts.cairo(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title,
              style:
                  GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildChequeTile(Map<String, dynamic> cheque,
      {required bool isCashed}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor:
              isCashed ? Colors.green.shade50 : Colors.orange.shade50,
          child: Icon(
            isCashed
                ? Icons.check_circle_rounded
                : Icons.access_time_filled_rounded,
            color: isCashed ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        ),
        title: Text(
          cheque['customer'],
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        subtitle: Text(
          '${cheque['cycle']} | التاريخ: ${cheque['date']}',
          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Text(
          cheque['amount'],
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: isCashed ? Colors.green.shade800 : Colors.orange.shade800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(text, style: GoogleFonts.cairo(color: Colors.grey)),
      ),
    );
  }
}
