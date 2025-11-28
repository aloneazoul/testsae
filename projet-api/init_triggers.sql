-- ===============================
-- USERS
-- ===============================
DROP TRIGGER IF EXISTS trg_users_update;
CREATE TRIGGER trg_users_update
BEFORE UPDATE ON users
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- USER PREFERENCES
-- ===============================
DROP TRIGGER IF EXISTS trg_user_preferences_update;
CREATE TRIGGER trg_user_preferences_update
BEFORE UPDATE ON user_preferences
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- COUNTRIES
-- ===============================
DROP TRIGGER IF EXISTS trg_countries_update;
CREATE TRIGGER trg_countries_update
BEFORE UPDATE ON countries
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- CITIES
-- ===============================
DROP TRIGGER IF EXISTS trg_cities_update;
CREATE TRIGGER trg_cities_update
BEFORE UPDATE ON cities
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- PLACES
-- ===============================
DROP TRIGGER IF EXISTS trg_places_update;
CREATE TRIGGER trg_places_update
BEFORE UPDATE ON places
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- FRIENDS
-- ===============================
DROP TRIGGER IF EXISTS trg_friends_update;
CREATE TRIGGER trg_friends_update
BEFORE UPDATE ON friends
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- FOLLOWERS
-- ===============================
DROP TRIGGER IF EXISTS trg_followers_update;
CREATE TRIGGER trg_followers_update
BEFORE UPDATE ON followers
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- TRIPS
-- ===============================
DROP TRIGGER IF EXISTS trg_trips_update;
CREATE TRIGGER trg_trips_update
BEFORE UPDATE ON trips
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- POSTS
-- ===============================
DROP TRIGGER IF EXISTS trg_posts_update;
CREATE TRIGGER trg_posts_update
BEFORE UPDATE ON posts
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- MEDIA
-- ===============================
DROP TRIGGER IF EXISTS trg_media_update;
CREATE TRIGGER trg_media_update
BEFORE UPDATE ON media
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- COMMENTS
-- ===============================
DROP TRIGGER IF EXISTS trg_comments_update;
CREATE TRIGGER trg_comments_update
BEFORE UPDATE ON comments
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- LIKES
-- ===============================
DROP TRIGGER IF EXISTS trg_likes_update;
CREATE TRIGGER trg_likes_update
BEFORE UPDATE ON likes
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- PRIVATE MESSAGES
-- ===============================
DROP TRIGGER IF EXISTS trg_private_messages_update;
CREATE TRIGGER trg_private_messages_update
BEFORE UPDATE ON private_messages
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- GROUP CHATS
-- ===============================
DROP TRIGGER IF EXISTS trg_group_chats_update;
CREATE TRIGGER trg_group_chats_update
BEFORE UPDATE ON group_chats
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- GROUP MEMBERS
-- ===============================
DROP TRIGGER IF EXISTS trg_group_members_update;
CREATE TRIGGER trg_group_members_update
BEFORE UPDATE ON group_members
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- GROUP MESSAGES
-- ===============================
DROP TRIGGER IF EXISTS trg_group_messages_update;
CREATE TRIGGER trg_group_messages_update
BEFORE UPDATE ON group_messages
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;

-- ===============================
-- NOTIFICATIONS
-- ===============================
DROP TRIGGER IF EXISTS trg_notifications_update;
CREATE TRIGGER trg_notifications_update
BEFORE UPDATE ON notifications
FOR EACH ROW
SET NEW.last_modification_date = CURRENT_TIMESTAMP;


-- ===============================
-- Story views: auto increment view_count
-- ===============================

DROP TRIGGER IF EXISTS trg_story_view_increment;

CREATE TRIGGER trg_story_view_increment
AFTER INSERT ON story_views
FOR EACH ROW
UPDATE stories
SET view_count = view_count + 1
WHERE story_id = NEW.story_id;
