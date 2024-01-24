import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wispar/screens/article_website.dart';
import '../services/crossref_api.dart';
import '../models/crossref_journals_works_models.dart';
import '../services/database_helper.dart';
import '../publication_card.dart';

class ArticleScreen extends StatefulWidget {
  final String doi;
  final String title;
  final String issn;

  const ArticleScreen({
    Key? key,
    required this.doi,
    required this.title,
    required this.issn,
  }) : super(key: key);

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late Future<Item> articleDetailsFuture;
  bool isLoading = true;
  late Item articleDetails;
  bool isLiked = false;
  late DatabaseHelper databaseHelper;

  @override
  void initState() {
    super.initState();
    articleDetailsFuture = fetchArticleDetails();
    databaseHelper = DatabaseHelper();
    checkIfLiked();
  }

  Future<Item> fetchArticleDetails() async {
    try {
      return await CrossRefApi.getWorkByDOI(widget.doi);
    } catch (e) {
      print('Error fetching article details: $e');
      throw Exception(
          'Failed to fetch article details. Please try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<Item>(
        future: articleDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Text('No data available'),
            );
          } else {
            articleDetails = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.publishedon} ${_formattedDate(articleDetails.publishedDate)}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      articleDetails.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      _getAuthorsNames(articleDetails.authors),
                    ),
                    SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.abstract,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    Text(
                      articleDetails.abstract.isNotEmpty
                          ? articleDetails.abstract
                          : AppLocalizations.of(context)!.abstractunavailable,
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'DOI: ${articleDetails.doi}\n${AppLocalizations.of(context)!.publishedin} ${articleDetails.journalTitle}',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      bottomNavigationBar: Container(
        height: 80,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.copy_outlined),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: articleDetails.doi));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocalizations.of(context)!.doicopied),
                      duration: const Duration(seconds: 1),
                    ));
                  },
                ),
                Text(AppLocalizations.of(context)!.copydoi),
              ],
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.article),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleWebsite(
                          articleUrl: articleDetails.primaryUrl,
                          doi: articleDetails.doi,
                        ),
                      ),
                    );
                  },
                ),
                Text(AppLocalizations.of(context)!.viewarticle),
              ],
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: () async {
                    setState(() {
                      isLiked = !isLiked;
                    });

                    PublicationCard publicationCard = PublicationCard(
                      title: articleDetails.title,
                      abstract: articleDetails.abstract,
                      journalTitle: articleDetails.journalTitle,
                      issn: widget.issn,
                      publishedDate: articleDetails.publishedDate,
                      doi: articleDetails.doi,
                      authors: articleDetails.authors,
                    );

                    if (isLiked) {
                      await databaseHelper.insertArticle(publicationCard,
                          isLiked: true);
                    } else {
                      await databaseHelper.removeFavorite(articleDetails.doi);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isLiked
                          ? '${articleDetails.title} ${AppLocalizations.of(context)!.favoriteadded}'
                          : '${articleDetails.title} ${AppLocalizations.of(context)!.favoriteremoved}'),
                    ));
                  },
                ),
                Text(AppLocalizations.of(context)!.favorite),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getAuthorsNames(List<PublicationAuthor> authors) {
    return authors
        .map((author) => '${author.given} ${author.family}')
        .join(', ');
  }

  String _formattedDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void checkIfLiked() async {
    bool liked = await databaseHelper.isArticleFavorite(widget.doi);
    setState(() {
      isLiked = liked;
    });
  }
}
