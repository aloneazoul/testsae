-- ===============================
-- INDEXES USERS
-- ===============================

-- idx_users_search : FULLTEXT sur username
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND index_name = 'idx_users_search'
);
SET @sql := IF(
    @idx_exists = 0,
    'ALTER TABLE users ADD FULLTEXT INDEX idx_users_search (username)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES PLACES
-- ===============================

-- idx_places_location : latitude / longitude
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'places'
      AND index_name = 'idx_places_location'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_places_location ON places(latitude, longitude)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES TRIPS
-- ===============================

-- idx_trips_hist_trip : historique par trip
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'trips_hist'
      AND index_name = 'idx_trips_hist_trip'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_trips_hist_trip ON trips_hist(trip_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_trips_public : voyages publics
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'trips'
      AND index_name = 'idx_trips_public'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_trips_public ON trips(is_public_flag)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_trips_user : voyages par user
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'trips'
      AND index_name = 'idx_trips_user'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_trips_user ON trips(user_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_trip_places_order : ordre des places d’un trip
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'trip_places'
      AND index_name = 'idx_trip_places_order'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_trip_places_order ON trip_places(trip_id, ordinal)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES POSTS
-- ===============================

-- idx_posts_user_date : posts par user + date
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'posts'
      AND index_name = 'idx_posts_user_date'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_posts_user_date ON posts(user_id, publication_date)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_posts_location : latitude / longitude
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'posts'
      AND index_name = 'idx_posts_location'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_posts_location ON posts(latitude, longitude)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_posts_search : FULLTEXT sur titre + description
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'posts'
      AND index_name = 'idx_posts_search'
);
SET @sql := IF(
    @idx_exists = 0,
    'ALTER TABLE posts ADD FULLTEXT INDEX idx_posts_search (post_title, post_description)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES MEDIA
-- ===============================

-- idx_media_post : par post
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'media'
      AND index_name = 'idx_media_post'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_media_post ON media(post_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES STORIES
-- ===============================

-- idx_stories_active : stories actives par user
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'stories'
      AND index_name = 'idx_stories_active'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_stories_active ON stories(user_id, expires_at)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES LIKES
-- ===============================

-- idx_likes_post : likes par post
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'likes'
      AND index_name = 'idx_likes_post'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_likes_post ON likes(post_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES COMMENTS
-- ===============================

-- idx_comments_post : commentaires par post + date
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'comments'
      AND index_name = 'idx_comments_post'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_comments_post ON comments(post_id, creation_date)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES MENTIONS
-- ===============================

-- idx_mentions_user : mentions d’un user
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'mentions'
      AND index_name = 'idx_mentions_user'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_mentions_user ON mentions(mentioned_user_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES SAVED POSTS
-- ===============================

-- idx_saved_posts_user : favoris par user
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'saved_posts'
      AND index_name = 'idx_saved_posts_user'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_saved_posts_user ON saved_posts(user_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES POST SHARES
-- ===============================

-- idx_post_shares_post : partages par post
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'post_shares'
      AND index_name = 'idx_post_shares_post'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_post_shares_post ON post_shares(post_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES USER INTERACTIONS
-- ===============================

-- ⚠ interaction_date doit bien exister dans user_interactions (modèle corrigé)
-- idx_interactions_user : interactions par user + date
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'user_interactions'
      AND index_name = 'idx_interactions_user'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_interactions_user ON user_interactions(user_id, interaction_date)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_interactions_post : interactions par post
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'user_interactions'
      AND index_name = 'idx_interactions_post'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_interactions_post ON user_interactions(post_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES PRIVATE MESSAGES
-- ===============================

-- idx_pm_conversation : conversation (pair sender/receiver + date)
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'private_messages'
      AND index_name = 'idx_pm_conversation'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_pm_conversation ON private_messages(sender_id, receiver_id, sent_at)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_pm_unread : messages non lus pour un user
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'private_messages'
      AND index_name = 'idx_pm_unread'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_pm_unread ON private_messages(receiver_id, is_read_flag)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES GROUP MEMBERS
-- ===============================

-- idx_group_members_group : membres par groupe
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'group_members'
      AND index_name = 'idx_group_members_group'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_group_members_group ON group_members(group_chat_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_group_members_user : groupes par user
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'group_members'
      AND index_name = 'idx_group_members_user'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_group_members_user ON group_members(user_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES GROUP MESSAGES
-- ===============================

-- idx_group_messages_group : messages par groupe + date
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'group_messages'
      AND index_name = 'idx_group_messages_group'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_group_messages_group ON group_messages(group_chat_id, sent_at)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES NOTIFICATIONS
-- ===============================

-- idx_notifications_user : notifs par user
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'notifications'
      AND index_name = 'idx_notifications_user'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_notifications_user ON notifications(user_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_notifications_unread : notifs non lues par user
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'notifications'
      AND index_name = 'idx_notifications_unread'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read_flag)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ===============================
-- INDEXES MAP_FEED
-- ===============================

-- idx_map_feed_location : par position
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'map_feed'
      AND index_name = 'idx_map_feed_location'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_map_feed_location ON map_feed(latitude, longitude)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_map_feed_date : par date
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'map_feed'
      AND index_name = 'idx_map_feed_date'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_map_feed_date ON map_feed(publication_date)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_map_feed_user : par user
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'map_feed'
      AND index_name = 'idx_map_feed_user'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_map_feed_user ON map_feed(user_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
