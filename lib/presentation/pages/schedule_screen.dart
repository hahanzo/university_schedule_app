import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/injection.dart';
import '../bloc/schedule_cubit.dart';
import '../bloc/schedule_state.dart';
import '../widgets/lesson_card.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/schedule_header.dart';
import '../../core/theme/app_colors.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _cubit = getIt<ScheduleCubit>();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cubit.loadSchedule('КН-11-1'); 
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    // Here you can add filtering by day of week,
    // if your repository supports filtering at the request level
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _cubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Search and Filter Header
              ScheduleHeader(
                onSearchChanged: (query) => _cubit.searchLessons(query),
                onFilterPressed: () {
                  // Call BottomSheet with filters (implement in next step)
                },
              ),

              // Calendar strip (Mon-Fri)
              CalendarStrip(
                selectedDate: _selectedDate,
                onDateSelected: _onDateChanged,
              ),

              const Divider(height: 1, color: Colors.black12),

              // List of lessons
              Expanded(
                child: BlocBuilder<ScheduleCubit, ScheduleState>(
                  builder: (context, state) {
                    return state.when(
                      initial: () => const Center(child: Text("Select a group")),
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (message) => Center(child: Text(message)),
                      loaded: (allLessons, filteredLessons) {
                        //Logic to determine if we are currently searching or just filtering by date
                        
                        bool isSearching = filteredLessons.length != allLessons.length;

                        final displayList = isSearching 
                            ? filteredLessons 
                            : filteredLessons.where((l) => l.dayOfWeek == _selectedDate.weekday).toList();

                        if (displayList.isEmpty) {
                          return const Center(child: Text("Nothing found 🔍"));
                        }

                        return ListView.builder(
                          itemCount: displayList.length,
                          itemBuilder: (context, index) => LessonCard(lesson: displayList[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}