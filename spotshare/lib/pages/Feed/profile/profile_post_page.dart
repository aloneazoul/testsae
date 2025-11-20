import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import '../widgets/post_card.dart';

class ProfilePostPage extends StatefulWidget {
  final List<PostModel> userPosts;
  final int initialIndex;

  ProfilePostPage({required this.userPosts, required this.initialIndex});

  @override
  _ProfilePostPageState createState() => _ProfilePostPageState();
}

class _ProfilePostPageState extends State<ProfilePostPage> {
  late final ScrollController _scrollController;
  late final List<PostModel> orderedPosts;

  @override
  void initState() {
    super.initState();

    // Trier par date décroissante
    orderedPosts = List.from(widget.userPosts);
    orderedPosts.sort((a, b) => b.date.compareTo(a.date));

    // ScrollController
    _scrollController = ScrollController();

    // Calculer la position approximative à scroller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double position = widget.initialIndex * 410.0; 
      // 410 est une estimation de la hauteur d'un PostCard (ajuste si nécessaire)
      _scrollController.jumpTo(position);
    });
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
        title: Text(orderedPosts[0].userName),
        elevation: 0,
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: orderedPosts.length,
        itemBuilder: (context, index) {
          final post = orderedPosts[index];
          return PostCard(post: post);
        },
      ),
    );
  }
}
