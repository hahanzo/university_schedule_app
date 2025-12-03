import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/schedule_repository.dart';

// --- EVENTS ---
abstract class SearchEvent {}

class SearchQueryChanged extends SearchEvent {
  final String query;
  SearchQueryChanged(this.query);
}

class SearchSubmitted extends SearchEvent {
  final String query;
  SearchSubmitted(this.query);
}

// --- STATES ---
abstract class SearchState {}
class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}
class SearchSuggestionsLoaded extends SearchState {
  final List<String> suggestions;
  SearchSuggestionsLoaded(this.suggestions);
}
class SearchResultsLoaded extends SearchState {
  final List<LessonEntity> results;
  SearchResultsLoaded(this.results);
}
class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

// --- BLOC ---
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ScheduleRepository repository;

  SearchBloc({required this.repository}) : super(SearchInitial()) {
    
    on<SearchQueryChanged>((event, emit) async {
      if (event.query.isEmpty) {
        emit(SearchInitial());
        return;
      }
      try {
        final suggestions = await repository.getSearchSuggestions(event.query);
        emit(SearchSuggestionsLoaded(suggestions));
      } catch (e) {
        emit(SearchError("Помилка пошуку"));
      }
    }, transformer: (events, mapper) {
      return events.debounceTime(const Duration(milliseconds: 300)).asyncExpand(mapper);
    });

    on<SearchSubmitted>((event, emit) async {
      emit(SearchLoading());
      try {
        final results = await repository.searchLessons(event.query);
        emit(SearchResultsLoaded(results));
      } catch (e) {
        emit(SearchError("Нічого не знайдено"));
      }
    });
  }
}