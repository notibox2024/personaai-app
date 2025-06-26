import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/attendance_header.dart';
import '../widgets/check_in_out_section.dart';
import '../widgets/current_status_card.dart';
import '../widgets/location_info_card.dart';
import '../widgets/today_summary_card.dart';
import '../widgets/quick_actions_row.dart';
import '../../data/models/attendance_session.dart';
import '../../data/models/location_data.dart';
import '../../data/models/time_tracking.dart';
import 'attendance_history_page.dart';
import '../../../../shared/shared_exports.dart';

/// Trang chấm công chính
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with WidgetsBindingObserver {
  bool _isLoading = false;
  late AttendanceSession _currentSession;
  late LocationData _locationData;
  late TimeTracking _timeTracking;
  
  // Mock workplace location (Tọa độ văn phòng)
  static const WorkplaceLocation _workplaceLocation = WorkplaceLocation(
    id: 'main_office',
    name: 'Văn phòng chính',
    latitude: 10.762622, // Tọa độ mẫu ở TP.HCM
    longitude: 106.660172,
    radiusInMeters: 100.0,
    address: '123 Đường ABC, Quận 1, TP.HCM',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh location when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkLocationAndRefresh();
    }
  }

  void _initializeData() {
    _currentSession = _getMockAttendanceSession();
    _locationData = _getMockLocationData();
    _timeTracking = _getMockTimeTracking();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Set status bar color to match header gradient
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons on orange background
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surfaceContainerLowest,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.light 
            ? Brightness.dark 
            : Brightness.light,
        systemNavigationBarDividerColor: theme.colorScheme.outline,
      ),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // Scrollable Header (extends to status bar)
            SliverToBoxAdapter(
              child: AttendanceHeader(
                onHistoryTap: _showAttendanceHistory,
                session: _currentSession,
              ),
            ),

            // Top spacing for content
            SliverToBoxAdapter(
              child: SafeArea(
                top: false, // Header already handles top safe area
                child: const SizedBox(height: 16),
              ),
            ),

            // Check-in/out Section
            SliverToBoxAdapter(
              child: CheckInOutSection(
                session: _currentSession,
                locationData: _locationData,
                isLoading: _isLoading,
                onCheckIn: _handleCheckIn,
                onCheckOut: _handleCheckOut,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Current Status Card
            SliverToBoxAdapter(
              child: CurrentStatusCard(
                timeTracking: _timeTracking,
                session: _currentSession,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Location Info Card
            SliverToBoxAdapter(
              child: LocationInfoCard(
                locationData: _locationData,
                onRefreshLocation: _refreshLocation,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Today Summary Card
            SliverToBoxAdapter(
              child: TodaySummaryCard(
                timeTracking: _timeTracking,
                session: _currentSession,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Quick Actions Row
            SliverToBoxAdapter(
              child: QuickActionsRow(
                onBreakTap: _handleBreakRequest,
                onOvertimeTap: _handleOvertimeRequest,
                onLeaveTap: _handleLeaveRequest,
                onReportTap: _handleIncidentReport,
              ),
            ),

            // Bottom spacing with safe area
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ),
          ],
        ),
      ),
    );
  }

  // =============== EVENT HANDLERS ===============

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    _initializeData();
    setState(() => _isLoading = false);
  }

  Future<void> _handleCheckIn() async {
    if (!_locationData.isValid) {
      _showLocationErrorDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        _showLocationErrorDialog();
        return;
      }

      // Create check-in location
      final checkInLocation = CheckInLocation.fromPosition(
        position,
        await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        ),
      );

      // Update session
      setState(() {
        _currentSession = _currentSession.copyWith(
          checkInTime: DateTime.now(),
          status: SessionStatus.active,
          checkInLocation: checkInLocation.address,
        );
        _timeTracking = _timeTracking.copyWith(
          expectedEndTime: DateTime.now().add(const Duration(hours: 8)),
        );
      });

      // TODO: Send to API
      _showSuccessSnackBar('Chấm công vào thành công!');
      
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chấm công: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckOut() async {
    if (!_locationData.isValid) {
      _showLocationErrorDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        _showLocationErrorDialog();
        return;
      }

      // Create check-out location
      final checkOutLocation = CheckInLocation.fromPosition(
        position,
        await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        ),
      );

      // Update session
      setState(() {
        _currentSession = _currentSession.copyWith(
          checkOutTime: DateTime.now(),
          status: SessionStatus.completed,
          checkOutLocation: checkOutLocation.address,
        );
      });

      // TODO: Send to API
      _showSuccessSnackBar('Chấm công ra thành công!');
      
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chấm công: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _locationData = _locationData.copyWith(
        validationStatus: LocationValidationStatus.checking,
        validationMessage: 'Đang kiểm tra vị trí...',
      );
    });

    try {
      final position = await LocationService.getCurrentLocation();
      
      if (position == null) {
        _updateLocationData(_locationData.copyWith(
          validationStatus: LocationValidationStatus.invalid,
          validationMessage: 'Không thể lấy vị trí',
        ));
        return;
      }

      // Check location accuracy
      if (!LocationService.isLocationAccurate(position)) {
        _updateLocationData(_locationData.copyWith(
          validationStatus: LocationValidationStatus.warning,
          validationMessage: 'Độ chính xác thấp: ±${position.accuracy.round()}m',
        ));
        return;
      }

      // Check if within workplace range
      final isWithinRange = LocationService.isWithinAllowedRange(
        position,
        _workplaceLocation.latitude,
        _workplaceLocation.longitude,
        radiusInMeters: _workplaceLocation.radiusInMeters,
      );

      final distance = LocationService.calculateDistanceToWorkplace(
        position,
        _workplaceLocation.latitude,
        _workplaceLocation.longitude,
      );

      if (isWithinRange) {
        _updateLocationData(LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          address: await LocationService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          ),
          isInOfficeRadius: true,
          isOfficeWifi: false, // TODO: Implement WiFi detection
          validationStatus: LocationValidationStatus.valid,
          validationMessage: 'Vị trí hợp lệ - ${(distance).round()}m từ văn phòng',
          timestamp: DateTime.now(),
        ));
      } else {
        _updateLocationData(LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          address: await LocationService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          ),
          isInOfficeRadius: false,
          isOfficeWifi: false,
          validationStatus: LocationValidationStatus.invalid,
          validationMessage: 'Ngoài phạm vi - ${(distance).round()}m từ văn phòng',
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _updateLocationData(_locationData.copyWith(
        validationStatus: LocationValidationStatus.invalid,
        validationMessage: 'Lỗi: ${e.toString()}',
      ));
    }
  }

  void _updateLocationData(LocationData newLocationData) {
    if (mounted) {
      setState(() {
        _locationData = newLocationData;
      });
    }
  }

  Future<void> _checkLocationAndRefresh() async {
    final status = await LocationService.getLocationPermissionStatus();
    
    if (status == LocationPermissionStatus.whileInUse || 
        status == LocationPermissionStatus.always) {
      await _refreshLocation();
    }
  }

  void _handleBreakRequest() {
    // TODO: Implement break request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở giao diện xin nghỉ giải lao')),
    );
  }

  void _handleOvertimeRequest() {
    // TODO: Implement overtime request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở giao diện đăng ký tăng ca')),
    );
  }

  void _handleLeaveRequest() {
    // TODO: Implement leave request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở giao diện xin nghỉ phép')),
    );
  }

  void _handleIncidentReport() {
    // TODO: Implement incident report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở giao diện báo cáo sự cố')),
    );
  }

  void _showAttendanceHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AttendanceHistoryPage(),
      ),
    );
  }

  // =============== MOCK DATA ===============

  AttendanceSession _getMockAttendanceSession() {
    final now = DateTime.now();
    return AttendanceSession(
      sessionId: 'session_001',
      employeeId: 'EMP001',
      checkInTime: now.hour >= 8 ? DateTime(now.year, now.month, now.day, 8, 30) : null,
      checkOutTime: null,
      status: now.hour >= 8 ? SessionStatus.active : SessionStatus.pending,
      sessionType: SessionType.normal,
      checkInLocation: 'Văn phòng chính - Tầng 5',
      checkOutLocation: null,
      notes: '',
      isValidated: true,
    );
  }

  LocationData _getMockLocationData() {
    return LocationData(
      latitude: 10.7769,
      longitude: 106.7009,
      accuracy: 5.0,
      address: 'Tòa nhà KienlongBank, 123 Nguyễn Huệ, Q1, TP.HCM',
      wifiSSID: 'KienlongBank_Office_5G',
      isInOfficeRadius: true,
      isOfficeWifi: true,
      validationStatus: LocationValidationStatus.valid,
      timestamp: DateTime.now(),
    );
  }

  TimeTracking _getMockTimeTracking() {
    final now = DateTime.now();
    final workStart = DateTime(now.year, now.month, now.day, 8, 30);
    
    return TimeTracking(
      currentWorkTime: now.isAfter(workStart) ? now.difference(workStart) : Duration.zero,
      totalBreakTime: const Duration(hours: 1),
      expectedEndTime: DateTime(now.year, now.month, now.day, 17, 0),
      overtimeHours: Duration.zero,
      efficiencyScore: 0.85,
      breakSessions: [
        BreakSession(
          id: 'break1',
          startTime: DateTime(now.year, now.month, now.day, 12, 0),
          endTime: DateTime(now.year, now.month, now.day, 13, 0),
          type: 'lunch',
        ),
      ],
    );
  }

  // =============== HELPERS ===============

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          TablerIcons.location_off,
          color: Theme.of(context).colorScheme.error,
          size: 32,
        ),
        title: const Text('Không thể chấm công'),
        content: Text(
          _locationData.displayMessage,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _refreshLocation();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              TablerIcons.check,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              TablerIcons.alert_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
} 