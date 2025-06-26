# Quick Checklist - Deprecated APIs

> **Checklist nhanh để kiểm tra và tránh deprecated APIs trong Flutter**

## ⚡ Quick Check Commands

```bash
# Kiểm tra deprecated warnings
flutter analyze

# Kiểm tra cụ thể deprecated
flutter analyze | grep deprecated

# Format code
dart format .
```

## 🔍 Common Deprecated Patterns

### ❌ AVOID
```dart
// MaterialStateProperty (deprecated)
MaterialStateProperty.resolveWith((states) => ...)
MaterialState.selected

// withOpacity (precision loss)
color.withOpacity(0.5)

// surfaceVariant (Material Design 3)
colorScheme.surfaceVariant

// background (ColorScheme)
colorScheme.background

// Dangling doc comments
/// Documentation
import 'package:flutter/material.dart';
```

### ✅ USE INSTEAD
```dart
// WidgetStateProperty (new)
WidgetStateProperty.resolveWith((states) => ...)
WidgetState.selected

// withValues (precision safe)
color.withValues(alpha: 0.5)

// surfaceContainerHighest (Material Design 3)
colorScheme.surfaceContainerHighest

// surface (ColorScheme)
colorScheme.surface

// Library directive
/// Documentation
library;
import 'package:flutter/material.dart';
```

## 📋 Pre-Commit Checklist

- [ ] `flutter analyze` returns 0 issues
- [ ] No `MaterialStateProperty` usage
- [ ] No `MaterialState` usage  
- [ ] No `withOpacity()` usage
- [ ] No `surfaceVariant` usage
- [ ] All doc comments have `library;`
- [ ] App runs without warnings

## 🎯 Priority Fixes

1. **HIGH**: MaterialStateProperty → WidgetStateProperty
2. **MEDIUM**: withOpacity() → withValues()
3. **MEDIUM**: surfaceVariant → surfaceContainerHighest
4. **LOW**: background → surface
5. **LOW**: Add library directives

## 🔧 Auto-Fix Commands

```bash
# Try auto-fix (some deprecated APIs)
dart fix --apply

# Manual search & replace
grep -r "MaterialStateProperty" lib/
grep -r "withOpacity" lib/
grep -r "surfaceVariant" lib/
```

---
**Last updated**: Dec 2024 - Flutter 3.18+ 