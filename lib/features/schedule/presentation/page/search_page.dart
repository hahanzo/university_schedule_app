import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../widgets/lesson_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchBar(
                controller: _controller,
                hintText: "Викладач, група або предмет...",
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                trailing: [
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        context.read<SearchBloc>().add(SearchQueryChanged(''));
                      },
                    ),
                ],
                onChanged: (query) {
                  context.read<SearchBloc>().add(SearchQueryChanged(query));
                },
                onSubmitted: (query) {
                  context.read<SearchBloc>().add(SearchSubmitted(query));
                },
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surfaceContainerHigh,
                ),
              ),
            ),

            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (state is SearchSuggestionsLoaded) {
                    return ListView.builder(
                      itemCount: state.suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = state.suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.history, color: Colors.grey),
                          title: Text(suggestion),
                          onTap: () {
                            _controller.text = suggestion;
                            context.read<SearchBloc>().add(SearchSubmitted(suggestion));
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                        );
                      },
                    );
                  }

                  if (state is SearchResultsLoaded) {
                    if (state.results.isEmpty) {
                      return Center(
                        child: Text("Нічого не знайдено 😔", 
                          style: Theme.of(context).textTheme.bodyLarge),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.results.length,
                      itemBuilder: (context, index) {
                        return LessonCard(lesson: state.results[index]);
                      },
                    );
                  }
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("Введіть запит для пошуку"),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}