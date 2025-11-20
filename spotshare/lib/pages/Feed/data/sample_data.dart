import 'package:spotshare/models/post_model.dart';

final List<PostModel> sampleData = [
  // ---- Ronan ----
  PostModel(
    id: '1',
    userId: 'u1',
    userName: 'Ronan',
    profileImageUrl: 'https://picsum.photos/seed/ronan/50',
    imageUrls: [
      'https://picsum.photos/seed/ronan_recent1/600/400', // paysage
      'https://picsum.photos/seed/ronan_recent2/400/600', // portrait
      'https://picsum.photos/seed/ronan_recent3/400/400', // carré
    ],
    caption: 'Mon post le plus récent ! 😎 gggggggggggggggghgggggggggggggghggggggggggghggggg',
    likes: 20,
    comments: 4,
    date: DateTime(2025, 10, 9, 15, 30), // Ronan le plus récent
  ),

  PostModel(
    id: '2',
    userId: 'u1',
    userName: 'Ronan',
    profileImageUrl: 'https://picsum.photos/seed/ronan/50',
    imageUrls: ['https://picsum.photos/seed/ronan_old1/400/400'], // carré
    caption: 'Ancien post de Ronan',
    likes: 10,
    comments: 2,
    date: DateTime(2025, 10, 7, 14, 15),
  ),

  // ---- Emma ----
  PostModel(
    id: '3',
    userId: 'u2',
    userName: 'Emma',
    profileImageUrl: 'https://picsum.photos/seed/emma/50',
    imageUrls: [
      'https://picsum.photos/seed/emma1/600/600', // carré
      'https://picsum.photos/seed/emma2/700/500', // paysage
    ],
    caption: 'Deux images pour tester le carrousel',
    likes: 18,
    comments: 3,
    date: DateTime(2025, 10, 6, 10, 0),
  ),

  PostModel(
    id: '4',
    userId: 'u2',
    userName: 'Emma',
    profileImageUrl: 'https://picsum.photos/seed/emma/50',
    imageUrls: ['https://picsum.photos/seed/emma3/500/700'], // portrait
    caption: 'Portrait seul',
    likes: 22,
    comments: 5,
    date: DateTime(2025, 10, 4, 9, 0),
  ),

  // ---- Lucas ----
  PostModel(
    id: '5',
    userId: 'u3',
    userName: 'Lucas',
    profileImageUrl: 'https://picsum.photos/seed/lucas/50',
    imageUrls: ['https://picsum.photos/seed/lucas1/500/500'], // carré
    caption: 'Carré seul',
    likes: 8,
    comments: 1,
    date: DateTime(2025, 10, 3, 16, 45),
  ),

  PostModel(
    id: '6',
    userId: 'u3',
    userName: 'Lucas',
    profileImageUrl: 'https://picsum.photos/seed/lucas/50',
    imageUrls: [
      'https://picsum.photos/seed/lucas2/600/800', // portrait
      'https://picsum.photos/seed/lucas3/800/400', // paysage
      'https://picsum.photos/seed/lucas4/400/400', // carré
      'https://picsum.photos/seed/lucas5/700/700', // carré
    ],
    caption: 'Carrousel 4 images',
    likes: 12,
    comments: 3,
    date: DateTime(2025, 10, 5, 12, 0),
  ),

  // ---- Zoé ----
  PostModel(
    id: '7',
    userId: 'u4',
    userName: 'Zoé',
    profileImageUrl: 'https://picsum.photos/seed/zoe/50',
    imageUrls: [
      'https://picsum.photos/seed/zoe1/400/600', // portrait
      'https://picsum.photos/seed/zoe2/800/400', // paysage
    ],
    caption: 'Carrousel mix portrait + paysage',
    likes: 18,
    comments: 4,
    date: DateTime(2025, 10, 2, 11, 20),
  ),

  // ---- Léa ----
  PostModel(
    id: '8',
    userId: 'u5',
    userName: 'Léa',
    profileImageUrl: 'https://picsum.photos/seed/lea/50',
    imageUrls: ['https://picsum.photos/seed/lea1/700/500'], // paysage
    caption: 'Petit challenge du jour : animation cœur sur double tap 💚',
    likes: 30,
    comments: 6,
    date: DateTime(2025, 10, 7, 8, 50),
  ),

  // ---- Noah ----
  PostModel(
    id: '9',
    userId: 'u6',
    userName: 'Noah',
    profileImageUrl: 'https://picsum.photos/seed/noah/50',
    imageUrls: [
      'https://picsum.photos/seed/noah1/600/600',
      'https://picsum.photos/seed/noah2/600/600',
    ],
    caption: 'Double carré pour tester le carrousel',
    likes: 5,
    comments: 0,
    date: DateTime(2025, 10, 8, 12, 0),
  ),

  // ---- Un autre utilisateur pour tester ----
  PostModel(
    id: '10',
    userId: 'u7',
    userName: 'Mia',
    profileImageUrl: 'https://picsum.photos/seed/mia/50',
    imageUrls: ['https://picsum.photos/seed/mia1/400/400'], // carré
    caption: 'Test post simple pour Mia',
    likes: 7,
    comments: 2,
    date: DateTime(2025, 10, 6, 9, 0),
  ),
];
