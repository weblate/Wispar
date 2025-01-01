import 'package:flutter/material.dart';
import '../widgets/publication_card.dart';
import '../models/crossref_journals_works_models.dart' as journalsWorks;
import '../services/crossref_api.dart';

class ArticleSearchResultsScreen extends StatefulWidget {
  final List<journalsWorks.Item> initialSearchResults;
  final bool initialHasMore;
  final Map<String, dynamic> queryParams;

  const ArticleSearchResultsScreen({
    Key? key,
    required this.initialSearchResults,
    required this.initialHasMore,
    required this.queryParams,
  }) : super(key: key);

  @override
  _ArticleSearchResultsScreenState createState() =>
      _ArticleSearchResultsScreenState();
}

class _ArticleSearchResultsScreenState
    extends State<ArticleSearchResultsScreen> {
  late List<journalsWorks.Item> _searchResults;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreResults = true;

  @override
  void initState() {
    super.initState();
    _searchResults = widget.initialSearchResults;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 70 &&
          !_isLoadingMore &&
          _hasMoreResults) {
        _loadMoreResults();
      }
    });
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore) return; // Prevent multiple API calls

    _isLoadingMore = true;

    try {
      final ListAndMore<journalsWorks.Item> newResults =
          await CrossRefApi.getWorksByQuery(widget.queryParams);

      setState(() {
        _searchResults.addAll(newResults.list);
        _hasMoreResults = newResults.hasMore;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more results')),
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search results'),
      ),
      body: _searchResults.isNotEmpty
          ? ListView.builder(
              controller: _scrollController,
              itemCount: _searchResults.length + (_hasMoreResults ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _searchResults.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final item = _searchResults[index];
                return PublicationCard(
                  title: item.title,
                  abstract: item.abstract,
                  journalTitle: item.journalTitle,
                  issn: item.issn,
                  publishedDate: item.publishedDate,
                  doi: item.doi,
                  authors: item.authors,
                  url: item.url,
                  license: item.license,
                  licenseName: item.licenseName,
                );
              },
            )
          : Center(
              child: Text('No results found'),
            ),
    );
  }
}
