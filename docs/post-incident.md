# Post-incident note (Phase 02)

**Date:** 2026-11-14  
**Symptom:** ALB returned HTTP 502 after both app instances were terminated from the EC2 console.  
**Impact:** Site unavailable until replacements passed health checks.  
**Detection:** Browser 502; target group showed `unhealthy` / empty targets.  
**Root cause:** ASG replaced EC2 capacity, but launch template `user_data` only set `role=app`. New boxes had no Docker/app, so port 8080 failed health checks.  
**Fix:** Extended launch template bootstrap to install Docker, read `/uncooked/app/image_tag` + JWT from SSM, pull ECR images, and start `docker-compose.app.yml`. Grace period set to 900s.  
**Verify:** Terminate one app instance → replacement reaches `bootstrap ok` → TG healthy → `/health` 200 without manual deploy.  
**Follow-up:** Prefer terminating one instance at a time in demos; keep CD rolling deploy for version changes.
