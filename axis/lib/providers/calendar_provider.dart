import 'package:flutter/foundation.dart';

class CalendarProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedMonth => _focusedMonth;

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setFocusedMonth(DateTime month) {
    _focusedMonth = month;
    notifyListeners();
  }

  void goToToday() {
    _selectedDate = DateTime.now();
    _focusedMonth = DateTime.now();
    notifyListeners();
  }
}
