import 'package:flutter/foundation.dart';

enum Gender { male, female }

enum ExperienceLevel { newLifter, months, year, years, competitor }

enum EquipmentType { fullGym, barbells, dumbbells, kettlebells, machines, none }

class OnboardingModel extends ChangeNotifier {
  int step = 0;
  Gender? gender;
  final Set<String> goals = <String>{};
  final Set<String> focusAreas = <String>{};
  final Set<String> trackingReasons = <String>{};
  ExperienceLevel? experienceLevel;
  int? workoutDays;
  final Set<EquipmentType> equipment = <EquipmentType>{};

  bool metric = true;
  int weightMajor = 75;
  int weightDecimal = 0;

  static const int totalSteps = 12;

  double get progress => (step + 1) / totalSteps;

  bool get canContinue {
    switch (step) {
      case 0:
        return true;
      case 1:
        return gender != null;
      case 2:
        return goals.isNotEmpty;
      case 3:
        return focusAreas.isNotEmpty;
      case 4:
        return trackingReasons.isNotEmpty;
      case 5:
        return experienceLevel != null;
      case 6:
        return workoutDays != null;
      case 7:
        return equipment.isNotEmpty;
      case 8:
      case 9:
      case 10:
      case 11:
        return true;
      default:
        return false;
    }
  }

  void nextStep() {
    if (step < totalSteps - 1) {
      step += 1;
      notifyListeners();
    }
  }

  void previousStep() {
    if (step > 0) {
      step -= 1;
      notifyListeners();
    }
  }

  void setGender(Gender value) {
    gender = value;
    notifyListeners();
  }

  void toggleGoal(String value) {
    if (!goals.add(value)) goals.remove(value);
    notifyListeners();
  }

  void toggleFocusArea(String value) {
    if (!focusAreas.add(value)) focusAreas.remove(value);
    notifyListeners();
  }

  void toggleTrackingReason(String value) {
    if (!trackingReasons.add(value)) trackingReasons.remove(value);
    notifyListeners();
  }

  void setExperience(ExperienceLevel value) {
    experienceLevel = value;
    notifyListeners();
  }

  void setWorkoutDays(int value) {
    workoutDays = value;
    notifyListeners();
  }

  void toggleEquipment(EquipmentType value) {
    if (!equipment.add(value)) equipment.remove(value);
    notifyListeners();
  }

  void setMetric(bool value) {
    metric = value;
    if (metric) {
      weightMajor = 75;
      weightDecimal = 0;
    } else {
      weightMajor = 165;
      weightDecimal = 0;
    }
    notifyListeners();
  }

  void setWeightMajor(int value) {
    weightMajor = value;
    notifyListeners();
  }

  void setWeightDecimal(int value) {
    weightDecimal = value;
    notifyListeners();
  }
}
