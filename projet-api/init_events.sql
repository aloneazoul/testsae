DROP EVENT IF EXISTS ev_cleanup_expired_stories;

CREATE EVENT ev_cleanup_expired_stories
ON SCHEDULE EVERY 1 DAY
DO
  DELETE FROM stories
  WHERE expires_at < CURRENT_TIMESTAMP;
