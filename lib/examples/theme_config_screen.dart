import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:church/core/providers/theme_provider.dart';

/// Example screen showing how to use Remote Config Theme
/// This can be integrated into your settings or admin panel
class ThemeConfigScreen extends StatelessWidget {
  const ThemeConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Configuration'),
        centerTitle: true,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          if (!themeProvider.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final config = themeProvider.getThemeConfig();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Header Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Remote Config Theme',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Theme is controlled via Firebase Remote Config. Changes made in Firebase Console will appear here after refresh.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Custom Theme Toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Enable Custom Theme'),
                  subtitle: const Text('Use Firebase Remote Config theme'),
                  value: config['isCustomThemeEnabled'],
                  onChanged: (value) {
                    themeProvider.toggleCustomTheme(value);
                  },
                  secondary: const Icon(Icons.palette),
                ),
              ),
              const SizedBox(height: 16),

              // Theme Info Section
              _buildSectionTitle('Current Theme Configuration'),
              const SizedBox(height: 8),

              _buildColorInfoCard(
                'Primary Color',
                config['primaryColor'],
                Icons.color_lens,
              ),
              _buildColorInfoCard(
                'Secondary Color',
                config['secondaryColor'],
                Icons.color_lens_outlined,
              ),
              _buildColorInfoCard(
                'Scaffold Background',
                config['scaffoldBackgroundColor'],
                Icons.dashboard,
              ),
              _buildColorInfoCard(
                'AppBar Background',
                config['appBarBackgroundColor'],
                Icons.web_asset,
              ),

              const SizedBox(height: 16),
              _buildInfoCard(
                'Dark Mode',
                config['isDarkMode'] ? 'Enabled' : 'Disabled',
                config['isDarkMode'] ? Icons.dark_mode : Icons.light_mode,
              ),
              _buildInfoCard(
                'Font Family',
                config['fontFamily'],
                Icons.text_fields,
              ),

              const SizedBox(height: 24),

              // Refresh Button
              ElevatedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing theme from Firebase...'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  await themeProvider.refreshTheme();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Theme updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Theme from Firebase'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 16),

              // Instructions
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'How to Update Theme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionStep('1', 'Go to Firebase Console'),
                      _buildInstructionStep('2', 'Navigate to Remote Config'),
                      _buildInstructionStep('3', 'Update theme parameters'),
                      _buildInstructionStep('4', 'Publish changes'),
                      _buildInstructionStep('5', 'Tap "Refresh Theme" button above'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColorInfoCard(String title, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Container(
          width: 80,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
              style: TextStyle(
                color: _getContrastColor(color),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.orange.shade900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

