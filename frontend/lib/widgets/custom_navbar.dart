import 'package:flutter/material.dart';
import 'package:alab/screens/home_screen.dart';
import 'package:alab/screens/calculator_screen.dart';
import 'package:alab/screens/note_screen.dart';
import 'package:alab/screens/profile_screen.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomNavBar({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget target;
    switch (index) {
      case 0:
        target = const HomeScreen();
        break;
      case 1:
        target = const CalculatorScreen();
        break;
      case 2:
        target = const NoteScreen();
        break;
      case 3:
        target = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _navIcon(context, Icons.home, '홈', 0),
        _navIcon(context, Icons.calculate, '계산기', 1),
        _navIcon(context, Icons.book, '노트', 2),
        _navIcon(context, Icons.person, '프로필', 3),
      ],
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, String label, int index) {
    final isSelected = index == currentIndex;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 30),
          color: isSelected ? Colors.blue[700] : Colors.grey,
          onPressed: () => _navigate(context, index),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue[700] : Colors.grey,
          ),
        ),
      ],
    );
  }
}
