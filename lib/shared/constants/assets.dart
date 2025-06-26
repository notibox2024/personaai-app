/// Constants cho tất cả assets trong dự án
class Assets {
  Assets._();

  // ============== BASE PATHS ==============
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = '$_imagesPath/icons';
  static const String _fontsPath = 'assets/fonts';

  // ============== HELPER METHODS ==============
  
  /// Lấy đường dẫn icon với resolution phù hợp
  static String getIcon(String iconName, {double pixelRatio = 1.0}) {
    if (pixelRatio >= 3.0) {
      return '$_iconsPath/3x/$iconName@3x.png';
    } else if (pixelRatio >= 2.0) {
      return '$_iconsPath/2x/$iconName@2x.png';
    } else {
      return '$_iconsPath/$iconName.png';
    }
  }

  /// Kiểm tra xem asset có tồn tại không (cần implement với rootBundle)
  static Future<bool> assetExists(String path) async {
    try {
      // await rootBundle.load(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Kiểm tra xem file có phải SVG không
  static bool isSvgFile(String path) {
    return path.toLowerCase().endsWith('.svg');
  }

  /// Lấy extension của file asset
  static String getAssetExtension(String path) {
    return path.split('.').last.toLowerCase();
  }
}

/// Custom icons constants
class AssetsIcons {
  AssetsIcons._();
  
  static const String _path = 'assets/images/icons';
  
  // Ví dụ custom icons - uncomment khi có file thật
  // static const String logo = '$_path/logo.png';
  // static const String logoSmall = '$_path/logo_small.png';
  // static const String appIcon = '$_path/app_icon.png';
}

/// High resolution icons (2x)
class AssetsIcons2x {
  AssetsIcons2x._();
  
  static const String _path = 'assets/images/icons/2x';
  
  // static const String logo = '$_path/logo@2x.png';
  // static const String logoSmall = '$_path/logo_small@2x.png';
}

/// High resolution icons (3x)
class AssetsIcons3x {
  AssetsIcons3x._();
  
  static const String _path = 'assets/images/icons/3x';
  
  // static const String logo = '$_path/logo@3x.png';
  // static const String logoSmall = '$_path/logo_small@3x.png';
}

/// Illustrations constants
class AssetsIllustrations {
  AssetsIllustrations._();
  
  static const String _path = 'assets/images/illustrations';
  
  // Ví dụ illustrations - uncomment khi có file thật
  // static const String welcome = '$_path/welcome.png';
  // static const String emptyState = '$_path/empty_state.png';
  // static const String error = '$_path/error.png';
  // static const String success = '$_path/success.png';
  // static const String noInternet = '$_path/no_internet.png';
}

/// Avatars constants
class AssetsAvatars {
  AssetsAvatars._();
  
  static const String _path = 'assets/images/avatars';
  
  // Default avatars - uncomment khi có file thật
  // static const String defaultMale = '$_path/default_male.png';
  // static const String defaultFemale = '$_path/default_female.png';
  // static const String placeholder = '$_path/placeholder.png';
  // static const String anonymous = '$_path/anonymous.png';
}

/// Background images constants
class AssetsBackgrounds {
  AssetsBackgrounds._();
  
  static const String _path = 'assets/images/backgrounds';
  
  // Background images - uncomment khi có file thật
  // static const String splash = '$_path/splash_bg.png';
  // static const String login = '$_path/login_bg.png';
  // static const String pattern = '$_path/pattern.png';
  // static const String gradient = '$_path/gradient_bg.png';
}

/// Logos constants
class AssetsLogos {
  AssetsLogos._();
  
  static const String _path = 'assets/images/logos';
  
  // Kienlongbank logos
  static const String kienlongbankIcon = '$_path/kienlongbank_icon.svg';
  static const String kienlongbankLogo = '$_path/kienlongbank_logo.svg';
  
  // Company/App logos - uncomment khi có file thật
  // static const String appLogo = '$_path/app_logo.png';
  // static const String companyLogo = '$_path/company_logo.png';
  // static const String logoLight = '$_path/logo_light.png';
  // static const String logoDark = '$_path/logo_dark.png';
}

/// Onboarding images constants
class AssetsOnboarding {
  AssetsOnboarding._();
  
  static const String _path = 'assets/images/onboarding';
  
  // Onboarding images - uncomment khi có file thật
  // static const String step1 = '$_path/step1.png';
  // static const String step2 = '$_path/step2.png';
  // static const String step3 = '$_path/step3.png';
  // static const String welcome = '$_path/welcome.png';
}

/// App Icon assets
class AssetsAppIcon {
  AssetsAppIcon._();
  
  static const String _path = 'assets/images/app_icon';
  
  // App icon files
  static const String appIcon = '$_path/app_icon.png';
  static const String template = '$_path/template.html';
}

/// Splash Screen assets
class AssetsSplash {
  AssetsSplash._();
  
  static const String _path = 'assets/images/splash';
  
  // Splash screen files
  static const String splashLogo = '$_path/splash_logo.png';
  static const String splashBackground = '$_path/splash_background.png';
}

/// Fonts constants
class AssetsFonts {
  AssetsFonts._();
  
  // Custom font families - uncomment khi có fonts thật
  // static const String primaryFont = 'Inter';
  // static const String secondaryFont = 'Roboto';
  // static const String displayFont = 'Poppins';
  // static const String monoFont = 'JetBrainsMono';
}

/// Extension để dễ dàng sử dụng assets
extension AssetString on String {
  /// Convert string thành asset path
  String get asAsset => 'assets/images/$this';
  
  /// Convert thành icon path
  String get asIcon => 'assets/images/icons/$this';
  
  /// Convert thành illustration path  
  String get asIllustration => 'assets/images/illustrations/$this';
  
  /// Convert thành avatar path
  String get asAvatar => 'assets/images/avatars/$this';
  
  /// Convert thành background path
  String get asBackground => 'assets/images/backgrounds/$this';
  
  /// Convert thành logo path
  String get asLogo => 'assets/images/logos/$this';
  
  /// Convert thành SVG logo path
  String get asSvgLogo => 'assets/images/logos/$this.svg';
}

/// Enum cho các loại assets
enum AssetType {
  icon,
  illustration,
  avatar,
  background,
  logo,
  onboarding,
  appIcon,
  splash,
}

/// Helper class để build asset paths dynamically
class AssetPathBuilder {
  final AssetType type;
  final String fileName;
  final String? subfolder;
  
  const AssetPathBuilder({
    required this.type,
    required this.fileName,
    this.subfolder,
  });
  
  String get path {
    String basePath = 'assets/images';
    
    switch (type) {
      case AssetType.icon:
        basePath += '/icons';
        break;
      case AssetType.illustration:
        basePath += '/illustrations';
        break;
      case AssetType.avatar:
        basePath += '/avatars';
        break;
      case AssetType.background:
        basePath += '/backgrounds';
        break;
      case AssetType.logo:
        basePath += '/logos';
        break;
      case AssetType.onboarding:
        basePath += '/onboarding';
        break;
      case AssetType.appIcon:
        basePath += '/app_icon';
        break;
      case AssetType.splash:
        basePath += '/splash';
        break;
    }
    
    if (subfolder != null) {
      basePath += '/$subfolder';
    }
    
    return '$basePath/$fileName';
  }
  
  @override
  String toString() => path;
} 