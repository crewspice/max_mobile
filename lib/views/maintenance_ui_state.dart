import 'package:flutter/material.dart';

enum RecordMode { pm, repair, issue }

enum HistoryFilter {
  pms,
  rentals,
  issues,
  annuals,
}

class MaintenanceUiState extends ChangeNotifier {
  RecordMode? selectedRecord;

  final Set<HistoryFilter> selectedHistory = {};

  int? expandedHistory;

  final Set<int> expandedRepairs = {};
  final Set<int> noRepairNeeded = {};

  void selectRecord(RecordMode? mode) {
    selectedRecord = selectedRecord == mode ? null : mode;
    notifyListeners();
  }

  void toggleHistoryFilter(HistoryFilter filter) {
    if (selectedHistory.contains(filter)) {
      selectedHistory.remove(filter);
    } else {
      selectedHistory.add(filter);
    }
    notifyListeners();
  }

  void toggleHistory(int index) {
    expandedHistory = expandedHistory == index ? null : index;
    notifyListeners();
  }

  void toggleRepairExpanded(int actionId) {
    if (expandedRepairs.contains(actionId)) {
      expandedRepairs.remove(actionId);
    } else {
      expandedRepairs.add(actionId);
    }
    notifyListeners();
  }

  void setNoRepairNeeded(int actionId, bool value) {
    if (value) {
      noRepairNeeded.add(actionId);
    } else {
      noRepairNeeded.remove(actionId);
    }
    notifyListeners();
  }

  void resetForNewLift() {
    selectedRecord = null;
    expandedHistory = null;
    expandedRepairs.clear();
    noRepairNeeded.clear();

    selectedHistory.clear();

    notifyListeners();
  }
}