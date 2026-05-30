<?php
/**
 * Group Controller
 * LovingHarmony API
 * 
 * Handles: Create, Join, List groups, Posts
 */

class GroupController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/groups
     * List groups for authenticated user
     */
    public function index() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $stmt = $this->db->prepare(
            "SELECT g.*, gm.role, u.name as creator_name,
                    (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as member_count
             FROM groups_tbl g
             INNER JOIN group_members gm ON g.id = gm.group_id AND gm.user_id = ?
             INNER JOIN users u ON g.created_by = u.id
             ORDER BY gm.joined_at DESC"
        );
        $stmt->execute([$userId]);
        $groups = $stmt->fetchAll();

        $formatted = array_map(function ($g) {
            return [
                'id' => (int) $g['id'],
                'name' => $g['name'],
                'description' => $g['description'],
                'code' => $g['code'],
                'photo' => $g['photo'] ? getUploadUrl($g['photo']) : null,
                'role' => $g['role'],
                'creator_name' => $g['creator_name'],
                'member_count' => (int) $g['member_count'],
                'created_at' => $g['created_at']
            ];
        }, $groups);

        jsonSuccess($formatted);
    }

    /**
     * GET /api/groups/{id}
     */
    public function show($id) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Check membership
        $stmt = $this->db->prepare(
            "SELECT gm.role FROM group_members gm WHERE gm.group_id = ? AND gm.user_id = ?"
        );
        $stmt->execute([$id, $userId]);
        $membership = $stmt->fetch();

        if (!$membership) {
            jsonError('You are not a member of this group', 403);
        }

        $stmt = $this->db->prepare(
            "SELECT g.*, u.name as creator_name,
                    (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as member_count
             FROM groups_tbl g
             INNER JOIN users u ON g.created_by = u.id
             WHERE g.id = ?"
        );
        $stmt->execute([$id]);
        $group = $stmt->fetch();

        if (!$group) {
            jsonError('Group not found', 404);
        }

        jsonSuccess([
            'id' => (int) $group['id'],
            'name' => $group['name'],
            'description' => $group['description'],
            'code' => $group['code'],
            'photo' => $group['photo'] ? getUploadUrl($group['photo']) : null,
            'role' => $membership['role'],
            'creator_name' => $group['creator_name'],
            'member_count' => (int) $group['member_count'],
            'created_at' => $group['created_at']
        ]);
    }

    /**
     * POST /api/groups
     * Create a new group
     */
    public function store() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $data = getJsonBody();
        validateRequired($data, ['name']);

        $name = trim($data['name']);
        $description = isset($data['description']) ? trim($data['description']) : null;

        // Generate unique 6-char code
        $code = $this->generateUniqueCode();

        $this->db->beginTransaction();
        try {
            $stmt = $this->db->prepare(
                "INSERT INTO groups_tbl (name, description, code, created_by) VALUES (?, ?, ?, ?)"
            );
            $stmt->execute([$name, $description, $code, $userId]);
            $groupId = $this->db->lastInsertId();

            // Add creator as admin member
            $stmt = $this->db->prepare(
                "INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'admin')"
            );
            $stmt->execute([$groupId, $userId]);

            $this->db->commit();

            jsonSuccess([
                'id' => (int) $groupId,
                'name' => $name,
                'description' => $description,
                'code' => $code,
                'member_count' => 1
            ], 'Group created successfully', 201);
        } catch (Exception $e) {
            $this->db->rollBack();
            jsonError('Failed to create group: ' . $e->getMessage(), 500);
        }
    }

    /**
     * POST /api/groups/join
     * Join a group via invite code
     */
    public function join() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $data = getJsonBody();
        validateRequired($data, ['code']);

        $code = strtoupper(trim($data['code']));

        // Find group by code
        $stmt = $this->db->prepare("SELECT * FROM groups_tbl WHERE code = ?");
        $stmt->execute([$code]);
        $group = $stmt->fetch();

        if (!$group) {
            jsonError('Invalid group code', 404);
        }

        // Check if already a member
        $stmt = $this->db->prepare(
            "SELECT id FROM group_members WHERE group_id = ? AND user_id = ?"
        );
        $stmt->execute([$group['id'], $userId]);
        if ($stmt->fetch()) {
            jsonError('You are already a member of this group', 409);
        }

        // Join group
        $stmt = $this->db->prepare(
            "INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'member')"
        );
        $stmt->execute([$group['id'], $userId]);

        jsonSuccess([
            'id' => (int) $group['id'],
            'name' => $group['name'],
            'description' => $group['description'],
            'code' => $group['code']
        ], 'Successfully joined the group');
    }

    /**
     * GET /api/groups/{id}/posts
     */
    public function getPosts($groupId) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Verify membership
        $stmt = $this->db->prepare(
            "SELECT id FROM group_members WHERE group_id = ? AND user_id = ?"
        );
        $stmt->execute([$groupId, $userId]);
        if (!$stmt->fetch()) {
            jsonError('You are not a member of this group', 403);
        }

        $page = max(1, (int) ($_GET['page'] ?? 1));
        $perPage = min(50, max(1, (int) ($_GET['per_page'] ?? 20)));
        $offset = ($page - 1) * $perPage;

        $countStmt = $this->db->prepare("SELECT COUNT(*) as total FROM group_posts WHERE group_id = ?");
        $countStmt->execute([$groupId]);
        $total = $countStmt->fetch()['total'];

        $stmt = $this->db->prepare(
            "SELECT gp.*, u.name as user_name, u.photo as user_photo
             FROM group_posts gp
             INNER JOIN users u ON gp.user_id = u.id
             WHERE gp.group_id = ?
             ORDER BY gp.created_at DESC
             LIMIT ? OFFSET ?"
        );
        $stmt->execute([$groupId, $perPage, $offset]);
        $posts = $stmt->fetchAll();

        $formatted = array_map(function ($post) {
            return [
                'id' => (int) $post['id'],
                'content' => $post['content'],
                'type' => $post['type'],
                'user_name' => $post['user_name'],
                'user_photo' => $post['user_photo'] ? getUploadUrl($post['user_photo']) : null,
                'created_at' => $post['created_at']
            ];
        }, $posts);

        jsonPaginated($formatted, $total, $page, $perPage);
    }

    /**
     * POST /api/groups/{id}/posts
     */
    public function createPost($groupId) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Verify membership
        $stmt = $this->db->prepare(
            "SELECT id FROM group_members WHERE group_id = ? AND user_id = ?"
        );
        $stmt->execute([$groupId, $userId]);
        if (!$stmt->fetch()) {
            jsonError('You are not a member of this group', 403);
        }

        $data = getJsonBody();
        validateRequired($data, ['content']);

        $content = trim($data['content']);
        $type = $data['type'] ?? 'text';

        $validTypes = ['text', 'achievement', 'quote'];
        if (!in_array($type, $validTypes)) {
            jsonError('Invalid post type', 422);
        }

        $stmt = $this->db->prepare(
            "INSERT INTO group_posts (group_id, user_id, content, type) VALUES (?, ?, ?, ?)"
        );
        $stmt->execute([$groupId, $userId, $content, $type]);

        jsonSuccess([
            'id' => (int) $this->db->lastInsertId(),
            'content' => $content,
            'type' => $type
        ], 'Post created successfully', 201);
    }

    /**
     * GET /api/groups/{id}/members
     */
    public function getMembers($groupId) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Verify membership
        $stmt = $this->db->prepare(
            "SELECT id FROM group_members WHERE group_id = ? AND user_id = ?"
        );
        $stmt->execute([$groupId, $userId]);
        if (!$stmt->fetch()) {
            jsonError('You are not a member of this group', 403);
        }

        $stmt = $this->db->prepare(
            "SELECT u.id, u.name, u.photo, u.bio, gm.role, gm.joined_at
             FROM group_members gm
             INNER JOIN users u ON gm.user_id = u.id
             WHERE gm.group_id = ?
             ORDER BY gm.role ASC, gm.joined_at ASC"
        );
        $stmt->execute([$groupId]);
        $members = $stmt->fetchAll();

        $formatted = array_map(function ($m) {
            return [
                'id' => (int) $m['id'],
                'name' => $m['name'],
                'photo' => $m['photo'] ? getUploadUrl($m['photo']) : null,
                'bio' => $m['bio'],
                'role' => $m['role'],
                'joined_at' => $m['joined_at']
            ];
        }, $members);

        jsonSuccess($formatted);
    }

    /**
     * DELETE /api/groups/{id}/leave
     */
    public function leave($groupId) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Check if user is the creator/last admin
        $stmt = $this->db->prepare("SELECT created_by FROM groups_tbl WHERE id = ?");
        $stmt->execute([$groupId]);
        $group = $stmt->fetch();

        if (!$group) {
            jsonError('Group not found', 404);
        }

        if ((int) $group['created_by'] === (int) $userId) {
            // Check if there are other admins
            $stmt = $this->db->prepare(
                "SELECT COUNT(*) as count FROM group_members WHERE group_id = ? AND role = 'admin' AND user_id != ?"
            );
            $stmt->execute([$groupId, $userId]);
            $adminCount = $stmt->fetch()['count'];

            if ($adminCount === 0) {
                jsonError('You are the only admin. Transfer admin role before leaving, or delete the group.', 400);
            }
        }

        $stmt = $this->db->prepare(
            "DELETE FROM group_members WHERE group_id = ? AND user_id = ?"
        );
        $stmt->execute([$groupId, $userId]);

        jsonSuccess(null, 'Left the group successfully');
    }


    /**
     * GET /api/groups/discover
     * Get all shared food logs
     */
    public function discoverFeed() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $stmt = $this->db->prepare(
            "SELECT fl.*, u.name as username, 
                    (SELECT COUNT(*) FROM food_log_likes WHERE food_log_id = fl.id) as likes_count,
                    (SELECT COUNT(*) FROM food_log_likes WHERE food_log_id = fl.id AND user_id = ?) as is_liked
             FROM food_logs fl
             JOIN users u ON fl.user_id = u.id
             WHERE fl.is_shared = 1
             ORDER BY fl.created_at DESC"
        );
        $stmt->execute([$userId]);
        $logs = $stmt->fetchAll();

        $formatted = array_map(function ($log) {
            return [
                'id' => (int) $log['id'],
                'user_id' => (int) $log['user_id'],
                'photo' => $log['photo'] ? getUploadUrl($log['photo']) : null,
                'food_name' => $log['food_name'],
                'meal_time' => $log['meal_time'],
                'category' => $log['category'],
                'nutrition_notes' => $log['nutrition_notes'],
                'calories' => $log['calories'] !== null ? (float) $log['calories'] : null,
                'carbs' => $log['carbs'] !== null ? (float) $log['carbs'] : null,
                'fat' => $log['fat'] !== null ? (float) $log['fat'] : null,
                'protein' => $log['protein'] !== null ? (float) $log['protein'] : null,
                'is_shared' => (int) $log['is_shared'],
                'created_at' => $log['created_at'],
                'username' => $log['username'],
                'likes_count' => (int) $log['likes_count'],
                'is_liked' => (bool) $log['is_liked']
            ];
        }, $logs);

        jsonSuccess($formatted);
    }

    /**
     * POST /api/groups/discover/like
     * Toggle like/unlike on a shared food log
     */
    public function likeToggle() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $data = getJsonBody();
        validateRequired($data, ['food_log_id']);
        $foodLogId = (int) $data['food_log_id'];

        // Verify that the food log exists
        $stmt = $this->db->prepare("SELECT id FROM food_logs WHERE id = ?");
        $stmt->execute([$foodLogId]);
        if (!$stmt->fetch()) {
            jsonError('Food log not found', 404);
        }

        // Check if already liked
        $stmt = $this->db->prepare("SELECT id FROM food_log_likes WHERE user_id = ? AND food_log_id = ?");
        $stmt->execute([$userId, $foodLogId]);
        $like = $stmt->fetch();

        if ($like) {
            // Delete like (unlike)
            $stmt = $this->db->prepare("DELETE FROM food_log_likes WHERE user_id = ? AND food_log_id = ?");
            $stmt->execute([$userId, $foodLogId]);
            jsonSuccess(['is_liked' => false], 'Unliked successfully');
        } else {
            // Add like
            $stmt = $this->db->prepare("INSERT INTO food_log_likes (user_id, food_log_id) VALUES (?, ?)");
            $stmt->execute([$userId, $foodLogId]);
            jsonSuccess(['is_liked' => true], 'Liked successfully');
        }
    }

    /**
     * Generate a unique 6-character alphanumeric code
     */
    private function generateUniqueCode() {
        $characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 0, 1 to avoid confusion
        $maxAttempts = 10;

        for ($attempt = 0; $attempt < $maxAttempts; $attempt++) {
            $code = '';
            for ($i = 0; $i < 6; $i++) {
                $code .= $characters[random_int(0, strlen($characters) - 1)];
            }

            $stmt = $this->db->prepare("SELECT id FROM groups_tbl WHERE code = ?");
            $stmt->execute([$code]);
            if (!$stmt->fetch()) {
                return $code;
            }
        }

        // Fallback: use longer code
        return strtoupper(substr(uniqid(), -8));
    }
}
