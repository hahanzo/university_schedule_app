import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../bloc/schedule_bloc.dart';
import '../bloc/search_bloc.dart';
import '../widgets/lesson_card.dart';
import '../widgets/week_calendar_strip.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Temporery data (later take from SettingsBloc)
  final String _groupName = "КН-11-1"; 
  DateTime _selectedDate = DateTime.now();
  final String _currentWeekType = 'numerator';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('uk_UA', null);
    _loadSchedule();
  }

  void _loadSchedule() {
    context.read<ScheduleBloc>().add(LoadSchedule(
      groupId: _groupName,
      dayOfWeek: _selectedDate.weekday,
      currentWeek: _currentWeekType,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Title formating
    final todayStr = DateFormat('d MMMM', 'uk_UA').format(_selectedDate);
    final weekDayStr = DateFormat('EEEE', 'uk_UA').format(_selectedDate);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Мій розклад",
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        todayStr,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        weekDayStr.toUpperCase(),
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  // Search
                  IconButton.filledTonal(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => SearchBloc(
                              repository: context.read<ScheduleRepository>(), 
                            ),
                            child: const SearchPage(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search),
                  ),
                  // Avator or setting button
                  IconButton.filledTonal(
                    onPressed: () { 
                    },
                    icon: const Icon(Icons.settings_outlined),
                  )
                ],
              ),
            ),

            // Day strip
            WeekCalendarStrip(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
                _loadSchedule();
              },
            ),
            
            const SizedBox(height: 16),

            // Lesson list
            Expanded(
              child: Container(
                // A small background for the list to separate it visually
                decoration: BoxDecoration(
                  color: colorScheme.surface, 
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: BlocBuilder<ScheduleBloc, ScheduleState>(
                  builder: (context, state) {
                    if (state is ScheduleLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ScheduleLoaded) {
                      if (state.lessons.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 20, bottom: 20),
                        itemCount: state.lessons.length,
                        itemBuilder: (context, index) {
                          return LessonCard(lesson: state.lessons[index]);
                        },
                      );
                    } else if (state is ScheduleError) {
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.weekend_outlined, 
            size: 80, 
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "Пар немає, відпочивай!",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}