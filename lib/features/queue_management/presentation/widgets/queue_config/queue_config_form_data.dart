import 'package:flutter/material.dart';
import 'package:sewa_web/features/queue_management/domain/entities/queue_configuration.dart';

/// Holds all form data for queue configuration
/// This class is used to share state between different section widgets
class QueueConfigFormData extends ChangeNotifier {
  // Office Hours
  TimeOfDay _officeStartTime;
  TimeOfDay _officeEndTime;
  TimeOfDay? _lunchStartTime;
  TimeOfDay? _lunchEndTime;
  bool _hasLunchBreak;
  int _avgServiceTimeMinutes;

  // Documents
  final List<DocumentItem> _documents;

  // Prebooking
  bool _prebookingAllowed;
  int _prebookingLeadHours;
  int _prebookingQuotaPerDay;

  // Emergency
  bool _emergencyAllowed;
  double _emergencyFee;
  int _emergencyQuotaPerDay;

  // Higher Officials
  final List<String> _selectedOfficialIds;

  // Progress Tracking
  bool _enableProgressTracking;
  final List<String> _progressSteps;

  QueueConfigFormData({
    TimeOfDay? officeStartTime,
    TimeOfDay? officeEndTime,
    TimeOfDay? lunchStartTime,
    TimeOfDay? lunchEndTime,
    bool hasLunchBreak = false,
    int avgServiceTimeMinutes = 15,
    List<DocumentItem>? documents,
    bool prebookingAllowed = false,
    int prebookingLeadHours = 24,
    int prebookingQuotaPerDay = 10,
    bool emergencyAllowed = false,
    double emergencyFee = 500,
    int emergencyQuotaPerDay = 5,
    List<String>? selectedOfficialIds,
    bool enableProgressTracking = false,
    List<String>? progressSteps,
  }) : _officeStartTime =
           officeStartTime ?? const TimeOfDay(hour: 9, minute: 0),
       _officeEndTime = officeEndTime ?? const TimeOfDay(hour: 17, minute: 0),
       _lunchStartTime = lunchStartTime,
       _lunchEndTime = lunchEndTime,
       _hasLunchBreak = hasLunchBreak,
       _avgServiceTimeMinutes = avgServiceTimeMinutes,
       _documents = documents ?? [],
       _prebookingAllowed = prebookingAllowed,
       _prebookingLeadHours = prebookingLeadHours,
       _prebookingQuotaPerDay = prebookingQuotaPerDay,
       _emergencyAllowed = emergencyAllowed,
       _emergencyFee = emergencyFee,
       _emergencyQuotaPerDay = emergencyQuotaPerDay,
       _selectedOfficialIds = selectedOfficialIds ?? [],
       _enableProgressTracking = enableProgressTracking,
       _progressSteps = progressSteps ?? [];

  /// Create from existing QueueConfiguration entity
  factory QueueConfigFormData.fromConfig(QueueConfiguration config) {
    return QueueConfigFormData(
      officeStartTime: config.officeStartTime,
      officeEndTime: config.officeEndTime,
      lunchStartTime: config.lunchStartTime,
      lunchEndTime: config.lunchEndTime,
      hasLunchBreak: config.lunchStartTime != null,
      avgServiceTimeMinutes: config.averageServiceTimeMinutes,
      documents: config.documentsRequired
          .map(
            (d) => DocumentItem(name: d.name, sampleImageUrl: d.sampleImageUrl),
          )
          .toList(),
      prebookingAllowed: config.prebookingAllowed,
      prebookingLeadHours: config.prebookingLeadHours ?? 24,
      prebookingQuotaPerDay: config.prebookingQuotaPerDay ?? 10,
      emergencyAllowed: config.emergencyAllowed,
      emergencyFee: config.emergencyFee ?? 500,
      emergencyQuotaPerDay: config.emergencyQuotaPerDay ?? 5,
      selectedOfficialIds: List<String>.from(config.higherOfficialIds),
      enableProgressTracking: config.enableProgressTracking,
      progressSteps: config.progressSteps.map((s) => s.title).toList(),
    );
  }

  // Getters
  TimeOfDay get officeStartTime => _officeStartTime;
  TimeOfDay get officeEndTime => _officeEndTime;
  TimeOfDay? get lunchStartTime => _lunchStartTime;
  TimeOfDay? get lunchEndTime => _lunchEndTime;
  bool get hasLunchBreak => _hasLunchBreak;
  int get avgServiceTimeMinutes => _avgServiceTimeMinutes;
  List<DocumentItem> get documents => List.unmodifiable(_documents);
  bool get prebookingAllowed => _prebookingAllowed;
  int get prebookingLeadHours => _prebookingLeadHours;
  int get prebookingQuotaPerDay => _prebookingQuotaPerDay;
  bool get emergencyAllowed => _emergencyAllowed;
  double get emergencyFee => _emergencyFee;
  int get emergencyQuotaPerDay => _emergencyQuotaPerDay;
  List<String> get selectedOfficialIds =>
      List.unmodifiable(_selectedOfficialIds);
  bool get enableProgressTracking => _enableProgressTracking;
  List<String> get progressSteps => List.unmodifiable(_progressSteps);

  /// Calculate daily capacity based on office hours and average service time
  int get calculatedDailyCapacity {
    int totalMinutes =
        (_officeEndTime.hour * 60 + _officeEndTime.minute) -
        (_officeStartTime.hour * 60 + _officeStartTime.minute);

    if (_hasLunchBreak && _lunchStartTime != null && _lunchEndTime != null) {
      int lunchMinutes =
          (_lunchEndTime!.hour * 60 + _lunchEndTime!.minute) -
          (_lunchStartTime!.hour * 60 + _lunchStartTime!.minute);
      totalMinutes -= lunchMinutes;
    }

    if (_avgServiceTimeMinutes <= 0) return 0;
    return (totalMinutes / _avgServiceTimeMinutes).floor();
  }

  // Setters with notification
  void setOfficeStartTime(TimeOfDay time) {
    _officeStartTime = time;
    notifyListeners();
  }

  void setOfficeEndTime(TimeOfDay time) {
    _officeEndTime = time;
    notifyListeners();
  }

  void setLunchStartTime(TimeOfDay? time) {
    _lunchStartTime = time;
    notifyListeners();
  }

  void setLunchEndTime(TimeOfDay? time) {
    _lunchEndTime = time;
    notifyListeners();
  }

  void setHasLunchBreak(bool value) {
    _hasLunchBreak = value;
    if (!value) {
      _lunchStartTime = null;
      _lunchEndTime = null;
    } else {
      _lunchStartTime ??= const TimeOfDay(hour: 12, minute: 0);
      _lunchEndTime ??= const TimeOfDay(hour: 13, minute: 0);
    }
    notifyListeners();
  }

  void setAvgServiceTimeMinutes(int minutes) {
    _avgServiceTimeMinutes = minutes;
    notifyListeners();
  }

  // Documents
  void addDocument(DocumentItem doc) {
    _documents.add(doc);
    notifyListeners();
  }

  void updateDocument(int index, DocumentItem doc) {
    if (index >= 0 && index < _documents.length) {
      _documents[index] = doc;
      notifyListeners();
    }
  }

  void removeDocument(int index) {
    if (index >= 0 && index < _documents.length) {
      _documents.removeAt(index);
      notifyListeners();
    }
  }

  // Prebooking
  void setPrebookingAllowed(bool value) {
    _prebookingAllowed = value;
    notifyListeners();
  }

  void setPrebookingLeadHours(int hours) {
    _prebookingLeadHours = hours;
    notifyListeners();
  }

  void setPrebookingQuotaPerDay(int quota) {
    _prebookingQuotaPerDay = quota;
    notifyListeners();
  }

  // Emergency
  void setEmergencyAllowed(bool value) {
    _emergencyAllowed = value;
    notifyListeners();
  }

  void setEmergencyFee(double fee) {
    _emergencyFee = fee;
    notifyListeners();
  }

  void setEmergencyQuotaPerDay(int quota) {
    _emergencyQuotaPerDay = quota;
    notifyListeners();
  }

  // Higher Officials
  void addOfficialId(String id) {
    if (!_selectedOfficialIds.contains(id)) {
      _selectedOfficialIds.add(id);
      notifyListeners();
    }
  }

  void removeOfficialId(String id) {
    _selectedOfficialIds.remove(id);
    notifyListeners();
  }

  void clearOfficialIds() {
    _selectedOfficialIds.clear();
    notifyListeners();
  }

  // Progress Tracking
  void setEnableProgressTracking(bool value) {
    _enableProgressTracking = value;
    notifyListeners();
  }

  void addProgressStep(String step) {
    _progressSteps.add(step);
    notifyListeners();
  }

  void updateProgressStep(int index, String step) {
    if (index >= 0 && index < _progressSteps.length) {
      _progressSteps[index] = step;
      notifyListeners();
    }
  }

  void removeProgressStep(int index) {
    if (index >= 0 && index < _progressSteps.length) {
      _progressSteps.removeAt(index);
      notifyListeners();
    }
  }

  void reorderProgressSteps(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _progressSteps.removeAt(oldIndex);
    _progressSteps.insert(newIndex, item);
    notifyListeners();
  }

  /// Convert to Map for API submission
  Map<String, dynamic> toApiMap(String staffServiceId) {
    return {
      'staff_service': staffServiceId,
      'office_start_time': _formatTime(_officeStartTime),
      'office_end_time': _formatTime(_officeEndTime),
      'lunch_start_time': _hasLunchBreak && _lunchStartTime != null
          ? _formatTime(_lunchStartTime!)
          : null,
      'lunch_end_time': _hasLunchBreak && _lunchEndTime != null
          ? _formatTime(_lunchEndTime!)
          : null,
      'average_service_time_minutes': _avgServiceTimeMinutes,
      'calculated_daily_capacity': calculatedDailyCapacity,
      'documents_required': _documents
          .map(
            (doc) => {'name': doc.name, 'sample_image_url': doc.sampleImageUrl},
          )
          .toList(),
      'prebooking_allowed': _prebookingAllowed,
      'prebooking_lead_hours': _prebookingAllowed ? _prebookingLeadHours : null,
      'prebooking_quota_per_day': _prebookingAllowed
          ? _prebookingQuotaPerDay
          : null,
      'emergency_allowed': _emergencyAllowed,
      'emergency_fee': _emergencyAllowed ? _emergencyFee : null,
      'emergency_quota_per_day': _emergencyAllowed
          ? _emergencyQuotaPerDay
          : null,
      // ManyToMany field for higher officials - send array of official IDs
      'higher_officials': _selectedOfficialIds,
      // Send both field names to handle backend column naming inconsistency
      'progress_tracking_enabled': _enableProgressTracking,
      'enable_progress_tracking': _enableProgressTracking,
      'progress_steps': _enableProgressTracking
          ? _progressSteps
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'title': entry.value,
                    'step_order': entry.key + 1,
                  },
                )
                .toList()
          : [],
      'active': true,
    };
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }
}

/// Document item for the form
class DocumentItem {
  final String name;
  final String sampleImageUrl;

  const DocumentItem({required this.name, this.sampleImageUrl = ''});

  DocumentItem copyWith({String? name, String? sampleImageUrl}) {
    return DocumentItem(
      name: name ?? this.name,
      sampleImageUrl: sampleImageUrl ?? this.sampleImageUrl,
    );
  }
}
