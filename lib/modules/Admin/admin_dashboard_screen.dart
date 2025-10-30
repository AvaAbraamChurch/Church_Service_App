import 'package:flutter/material.dart';
import 'package:church/core/services/admin_service.dart';
import 'package:church/core/utils/remote%20config/remote_config.dart';
import 'package:church/core/services/remote_config_update_service.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/styles/colors.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final RemoteConfigService _remoteConfig = RemoteConfigService();
  final RemoteConfigUpdateService _updateService = RemoteConfigUpdateService();

  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isSaving = false;

  // Controllers for theme values
  late TextEditingController _primaryColorController;
  late TextEditingController _secondaryColorController;
  late TextEditingController _scaffoldBgColorController;
  late TextEditingController _scaffoldBgImageController;
  late TextEditingController _appBarBgColorController;
  late TextEditingController _fontFamilyController;

  bool _enableCustomTheme = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadConfig();
  }

  Future<void> _checkAdminAndLoadConfig() async {
    setState(() => _isLoading = true);

    final isAdmin = await _adminService.isAdmin();
    setState(() => _isAdmin = isAdmin);

    if (isAdmin) {
      await _loadCurrentConfig();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadCurrentConfig() async {
    // Load current values from Remote Config
    final config = _remoteConfig.getThemeConfig();

    _enableCustomTheme = _remoteConfig.isCustomThemeEnabled;
    _isDarkMode = _remoteConfig.isDarkMode;

    // Initialize controllers with current values
    _primaryColorController = TextEditingController(
      text: _colorToHex(config['primaryColor']),
    );
    _secondaryColorController = TextEditingController(
      text: _colorToHex(config['secondaryColor']),
    );
    _scaffoldBgColorController = TextEditingController(
      text: _colorToHex(config['scaffoldBackgroundColor']),
    );
    _scaffoldBgImageController = TextEditingController(
      text: config['scaffoldBackgroundImage'] ?? 'assets/images/bg.png',
    );
    _appBarBgColorController = TextEditingController(
      text: _colorToHex(config['appBarBackgroundColor']),
    );
    _fontFamilyController = TextEditingController(
      text: config['fontFamily'] ?? 'Alexandria',
    );
  }

  String _colorToHex(Color color) {
    final r = ((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final b = ((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  @override
  void dispose() {
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _scaffoldBgColorController.dispose();
    _scaffoldBgImageController.dispose();
    _appBarBgColorController.dispose();
    _fontFamilyController.dispose();
    super.dispose();
  }

  Future<void> _saveConfiguration() async {
    setState(() => _isSaving = true);

    try {
      // Prepare the updates map
      final updates = {
        'theme_primary_color': _primaryColorController.text,
        'theme_secondary_color': _secondaryColorController.text,
        'theme_scaffold_background_color': _scaffoldBgColorController.text,
        'theme_scaffold_background_image': _scaffoldBgImageController.text,
        'theme_appbar_background_color': _appBarBgColorController.text,
        'theme_font_family': _fontFamilyController.text,
        'enable_custom_theme': _enableCustomTheme,
        'theme_is_dark_mode': _isDarkMode,
      };

      // Call the Cloud Function to update Remote Config
      final result = await _updateService.updateRemoteConfig(updates);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✓ تم حفظ الإعدادات بنجاح',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'الإصدار: ${result['version'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );

          // Refresh the config to get the latest values
          await _remoteConfig.fetchAndActivate();
          await _loadCurrentConfig();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message'] ?? 'فشل الحفظ'}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ThemedScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return ThemedScaffold(
        appBar: AppBar(
          title: const Text(
            'لوحة التحكم',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: teal900,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [red500, red700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: red500.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'غير مصرح لك بالدخول',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: teal900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'هذه الصفحة متاحة للكهنة فقط',
                  style: TextStyle(
                    fontSize: 16,
                    color: sage700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sage50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: sage700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'يرجى التواصل مع الإدارة للحصول على الصلاحيات',
                        style: TextStyle(color: sage700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ThemedScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [teal900, teal700, teal500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: teal900.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'لوحة تحكم المظهر',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'إدارة إعدادات المظهر والألوان',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: _checkAdminAndLoadConfig,
                      tooltip: 'تحديث القيم',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildThemeToggles(),
                  const SizedBox(height: 16),
                  _buildColorSettings(),
                  const SizedBox(height: 16),
                  _buildBackgroundImageSettings(),
                  const SizedBox(height: 16),
                  _buildFontSettings(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                  _buildInstructions(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [teal50, sage50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teal300.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: teal500.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [teal500, teal700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: teal500.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات مهمة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_outlined, color: teal700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يمكنك الآن تعديل وحفظ القيم مباشرة من هذه اللوحة.\nسيتم تطبيق التغييرات على Firebase Remote Config وجميع المستخدمين.',
                    style: TextStyle(fontSize: 14, color: sage900, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggles() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: sage500.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [brown300, brown500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: brown500.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إعدادات عامة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernSwitch(
            title: 'تفعيل المظهر المخصص',
            subtitle: 'enable_custom_theme',
            value: _enableCustomTheme,
            icon: Icons.palette_rounded,
            gradient: [teal300, teal500],
            onChanged: (value) {
              setState(() => _enableCustomTheme = value);
            },
          ),
          const SizedBox(height: 12),
          _buildModernSwitch(
            title: 'الوضع الليلي',
            subtitle: 'theme_is_dark_mode',
            value: _isDarkMode,
            icon: Icons.dark_mode_rounded,
            gradient: [sage500, sage700],
            onChanged: (value) {
              setState(() => _isDarkMode = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required List<Color> gradient,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient[0].withValues(alpha: 0.1),
            gradient[1].withValues(alpha: 0.1),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradient[0].withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: gradient[1], size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: teal900,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, right: 28),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: sage700,
            ),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: gradient[1],
        activeTrackColor: gradient[0],
      ),
    );
  }

  Widget _buildColorSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: teal500.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [red300, red500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: red500.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.color_lens_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إعدادات الألوان',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildColorField(
            'اللون الأساسي',
            'theme_primary_color',
            _primaryColorController,
            Icons.palette_rounded,
          ),
          const SizedBox(height: 16),
          _buildColorField(
            'اللون الثانوي',
            'theme_secondary_color',
            _secondaryColorController,
            Icons.palette_outlined,
          ),
          const SizedBox(height: 16),
          _buildColorField(
            'لون خلفية الصفحة',
            'theme_scaffold_background_color',
            _scaffoldBgColorController,
            Icons.format_paint_rounded,
          ),
          const SizedBox(height: 16),
          _buildColorField(
            'لون خلفية شريط التطبيق',
            'theme_appbar_background_color',
            _appBarBgColorController,
            Icons.dashboard_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildColorField(
    String label,
    String configKey,
    TextEditingController controller,
    IconData icon,
  ) {
    final color = _parseColor(controller.text);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sage50,
            Colors.white,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sage300.withValues(alpha: 0.1), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: teal900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      configKey,
                      style: TextStyle(
                        fontSize: 11,
                        color: sage600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showColorPicker(context, controller, label),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sage300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.colorize_rounded,
                      color: color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    color: sage900,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: '#RRGGBB',
                    hintStyle: TextStyle(color: sage500),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: sage300, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: sage300, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: teal500, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    prefixIcon: Icon(Icons.edit, color: sage600, size: 18),
                  ),
                  onChanged: (value) {
                    // Trigger rebuild to update the color preview
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [teal500, teal700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: teal500.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _showColorPicker(context, controller, label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.palette_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'اختر لون',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, TextEditingController controller, String label) {
    Color pickerColor = _parseColor(controller.text);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.palette_rounded, color: teal700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'اختر $label',
                  style: TextStyle(
                    color: teal900,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (Color color) {
                    pickerColor = color;
                  },
                  labelTypes: const [],
                  pickerAreaHeightPercent: 0.8,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                  enableAlpha: false,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sage50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sage300.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: sage700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'اضغط على "تأكيد" لتطبيق اللون',
                        style: TextStyle(
                          color: sage900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: sage700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [teal500, teal700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      controller.text = _colorToHex(pickerColor);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: const Text(
                      'تأكيد',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildBackgroundImageSettings() {
    final availableImages = [
      {'path': 'assets/images/bg.png', 'name': 'الخلفية الافتراضية', 'icon': Icons.image_rounded},
      {'path': 'assets/images/christmas_bg.jpg', 'name': 'خلفية الكريسماس', 'icon': Icons.celebration_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: brown500.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tawny, brown500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: brown500.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wallpaper_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إعدادات الخلفية',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [sage50, Colors.white],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sage300.withValues(alpha: 0.1), width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.image_rounded, color: brown500, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اختر صورة الخلفية',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: teal900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'theme_scaffold_background_image',
                  style: TextStyle(
                    fontSize: 11,
                    color: sage600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sage300, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: availableImages.any((img) => img['path'] == _scaffoldBgImageController.text)
                          ? _scaffoldBgImageController.text
                          : availableImages.first['path'] as String,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      borderRadius: BorderRadius.circular(10),
                      icon: Icon(Icons.arrow_drop_down, color: brown500),
                      style: TextStyle(
                        color: sage900,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      items: availableImages.map((image) {
                        return DropdownMenuItem<String>(
                          value: image['path'] as String,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: brown100.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  image['icon'] as IconData,
                                  color: brown500,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      image['name'] as String,
                                      style: TextStyle(
                                        color: teal900,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        fontFamily: 'Alexandria',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      image['path'] as String,
                                      style: TextStyle(
                                        color: sage600,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _scaffoldBgImageController.text = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: brown100.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: brown300.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: brown700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'المسار المحدد: ${_scaffoldBgImageController.text}',
                          style: TextStyle(
                            color: sage900,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: sage500.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [sage500, sage700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: sage500.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.font_download_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إعدادات الخط',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [sage50, Colors.white],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sage300.withValues(alpha: 0.1), width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.text_fields_rounded, color: sage700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'اسم الخط',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: teal900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'theme_font_family',
                  style: TextStyle(
                    fontSize: 11,
                    color: sage600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fontFamilyController,
                  style: TextStyle(
                    color: sage900,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Alexandria',
                    hintStyle: TextStyle(color: sage500),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: sage300, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: sage300, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: teal500, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    prefixIcon: Icon(Icons.edit, color: sage600, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isSaving
              ? [sage300, sage500]
              : [teal500, teal700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isSaving
            ? []
            : [
                BoxShadow(
                  color: teal500.withValues(alpha: 0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _saveConfiguration,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSaving ? Icons.hourglass_empty_rounded : Icons.save_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _isSaving ? 'جاري الحفظ...' : 'حفظ الإعدادات في Firebase',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brown100.withValues(alpha: 0.1), sage50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brown300.withValues(alpha: 0.1), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [brown300, brown500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'كيفية الاستخدام',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep('1', 'عدل القيم المطلوبة في الحقول أعلاه', Icons.edit_rounded),
          const SizedBox(height: 8),
          _buildInstructionStep('2', 'اضغط على "حفظ الإعدادات في Firebase"', Icons.save_rounded),
          const SizedBox(height: 8),
          _buildInstructionStep('3', 'انتظر رسالة التأكيد', Icons.check_circle_rounded),
          const SizedBox(height: 8),
          _buildInstructionStep('4', 'سيتم تطبيق التغييرات على جميع المستخدمين', Icons.cloud_sync_rounded),
          const SizedBox(height: 8),
          _buildInstructionStep('5', 'اضغط على "تحديث" لرؤية آخر التغييرات', Icons.refresh_rounded),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sage300.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [teal300, teal500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: brown500, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: sage900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

