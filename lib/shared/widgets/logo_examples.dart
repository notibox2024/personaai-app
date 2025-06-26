import 'package:flutter/material.dart';
import '../shared_exports.dart';

/// Widget ví dụ cách sử dụng Kienlongbank logos
class LogoExamples extends StatelessWidget {
  const LogoExamples({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logo Examples'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Kienlongbank Logos',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Basic usage
            _buildSection(
              title: '1. Sử dụng cơ bản',
              children: [
                Row(
                  children: [
                    // Icon
                    SvgAsset.kienlongbankIcon(
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 16),
                    const Text('Kienlongbank Icon (32x32)'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Logo
                    SvgAsset.kienlongbankLogo(
                      height: 40,
                    ),
                    const SizedBox(width: 16),
                    const Text('Kienlongbank Logo (height: 40)'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // With colors
            _buildSection(
              title: '2. Với màu sắc tùy chỉnh',
              children: [
                Row(
                  children: [
                    SvgAsset.kienlongbankIcon(
                      width: 32,
                      height: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Text('Primary color', style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SvgAsset.kienlongbankIcon(
                      width: 32,
                      height: 32,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 16),
                    Text('Error color', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Helper methods
            _buildSection(
              title: '3. Sử dụng helper methods',
              children: [
                Row(
                  children: [
                    SvgHelper.kienlongbankIcon(size: 24),
                    const SizedBox(width: 16),
                    const Text('SvgHelper.kienlongbankIcon()'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SvgHelper.kienlongbankLogo(height: 30),
                    const SizedBox(width: 16),
                    const Text('SvgHelper.kienlongbankLogo()'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Direct constants usage
            _buildSection(
              title: '4. Sử dụng constants trực tiếp',
              children: [
                Row(
                  children: [
                    SvgAsset(
                      AssetsLogos.kienlongbankIcon,
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 16),
                    const Text('AssetsLogos.kienlongbankIcon'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SvgAsset(
                      AssetsLogos.kienlongbankLogo,
                      height: 30,
                    ),
                    const SizedBox(width: 16),
                    const Text('AssetsLogos.kienlongbankLogo'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Extension usage
            _buildSection(
              title: '5. Sử dụng extensions',
              children: [
                Row(
                  children: [
                    AssetsLogos.kienlongbankIcon.toSvgAsset(
                      width: 24,
                      height: 24,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    const Text('Using .toSvgAsset() extension'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
} 