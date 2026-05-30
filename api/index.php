<?php
/**
 * LovingHarmony API - Main Entry Point & Router
 * 
 * All API requests are routed through this file via .htaccess
 */

// Set headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Load helpers
require_once __DIR__ . '/helpers/response.php';
require_once __DIR__ . '/helpers/jwt.php';
require_once __DIR__ . '/helpers/upload.php';
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/middleware/auth.php';

// Parse the request URI dynamically to support different hosting environments
$scriptDir = dirname($_SERVER['SCRIPT_NAME']);
$basePath = ($scriptDir === '/' || $scriptDir === '\\') ? '' : $scriptDir;

$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Strip basePath from requestUri if it matches
$path = $requestUri;
if (substr($requestUri, 0, strlen($basePath)) === $basePath) {
    $path = substr($requestUri, strlen($basePath));
}

// Support fallback route parameter for NGINX without rewriting
if (isset($_GET['route']) && !empty($_GET['route'])) {
    $path = $_GET['route'];
}

$path = trim($path, '/');
// If path is just index.php or empty, clear it
if ($path === 'index.php') {
    $path = '';
} elseif (strpos($path, 'index.php/') === 0) {
    $path = substr($path, 10);
}

$method = $_SERVER['REQUEST_METHOD'];

// Split path into segments
$segments = $path ? explode('/', $path) : [];

// Route dispatcher
try {
    if (empty($segments)) {
        jsonSuccess([
            'app' => 'LovingHarmony API',
            'version' => '1.0.0',
            'status' => 'running'
        ], 'Welcome to LovingHarmony API');
    }

    $resource = $segments[0] ?? '';

    switch ($resource) {
        case 'auth':
            require_once __DIR__ . '/controllers/AuthController.php';
            $controller = new AuthController();
            $action = $segments[1] ?? '';

            switch ($action) {
                case 'register':
                    if ($method === 'POST') $controller->register();
                    break;
                case 'login':
                    if ($method === 'POST') $controller->login();
                    break;
                case 'profile':
                    if ($method === 'GET') $controller->getProfile();
                    if ($method === 'PUT' || $method === 'POST') $controller->updateProfile();
                    break;
                case 'fcm-token':
                    if ($method === 'POST') $controller->registerFcmToken();
                    break;
                case 'onboarding':
                    if ($method === 'POST') $controller->onboarding();
                    break;
                default:
                    jsonError('Auth endpoint not found', 404);
            }
            break;

        case 'food-logs':
            require_once __DIR__ . '/controllers/FoodLogController.php';
            $controller = new FoodLogController();
            $id = $segments[1] ?? null;

            if ($id === 'sync' && $method === 'POST') {
                $controller->sync();
            } elseif ($id === 'streak' && $method === 'GET') {
                $controller->streak();
            } elseif ($id && isset($segments[2]) && $segments[2] === 'analyze' && $method === 'POST') {
                $controller->analyze($id);
            } elseif ($id && $method === 'GET') {
                $controller->show($id);
            } elseif ($id && ($method === 'PUT' || $method === 'POST') && isset($segments[2]) && $segments[2] === 'update') {
                $controller->update($id);
            } elseif ($id && $method === 'DELETE') {
                $controller->delete($id);
            } elseif (!$id && $method === 'GET') {
                $controller->index();
            } elseif (!$id && $method === 'POST') {
                $controller->store();
            } else {
                jsonError('Food log endpoint not found', 404);
            }
            break;

        case 'news':
            require_once __DIR__ . '/controllers/NewsController.php';
            $controller = new NewsController();
            $id = $segments[1] ?? null;

            if ($id && $method === 'GET') {
                $controller->show($id);
            } elseif (!$id && $method === 'GET') {
                $controller->index();
            } else {
                jsonError('News endpoint not found', 404);
            }
            break;

        case 'recipes':
            require_once __DIR__ . '/controllers/RecipeController.php';
            $controller = new RecipeController();
            $id = $segments[1] ?? null;

            if ($id && $method === 'GET') {
                $controller->show($id);
            } elseif (!$id && $method === 'GET') {
                $controller->index();
            } else {
                jsonError('Recipe endpoint not found', 404);
            }
            break;

        case 'groups':
            require_once __DIR__ . '/controllers/GroupController.php';
            $controller = new GroupController();
            $action = $segments[1] ?? null;

            if ($action === 'join' && $method === 'POST') {
                $controller->join();
            } elseif ($action && isset($segments[2])) {
                $subAction = $segments[2];
                if ($subAction === 'posts' && $method === 'GET') {
                    $controller->getPosts($action);
                } elseif ($subAction === 'posts' && $method === 'POST') {
                    $controller->createPost($action);
                } elseif ($subAction === 'leave' && $method === 'DELETE') {
                    $controller->leave($action);
                } elseif ($subAction === 'members' && $method === 'GET') {
                    $controller->getMembers($action);
                } else {
                    jsonError('Group endpoint not found', 404);
                }
            } elseif ($action && $method === 'GET') {
                $controller->show($action);
            } elseif (!$action && $method === 'GET') {
                $controller->index();
            } elseif (!$action && $method === 'POST') {
                $controller->store();
            } else {
                jsonError('Group endpoint not found', 404);
            }
            break;

        case 'notifications':
            require_once __DIR__ . '/controllers/NotificationController.php';
            $controller = new NotificationController();
            
            if ($method === 'GET') {
                $controller->index();
            } else {
                jsonError('Notification endpoint not found', 404);
            }
            break;

        case 'quotes':
            require_once __DIR__ . '/controllers/QuoteController.php';
            $controller = new QuoteController();
            $action = $segments[1] ?? null;

            if ($action === 'today' && $method === 'GET') {
                $controller->today();
            } elseif ($action && is_numeric($action) && $method === 'PUT') {
                $controller->update($action);
            } elseif ($action && is_numeric($action) && ($method === 'POST') && isset($segments[2]) && $segments[2] === 'update') {
                $controller->update($action);
            } elseif ($action && is_numeric($action) && $method === 'DELETE') {
                $controller->delete($action);
            } elseif (!$action && $method === 'GET') {
                $controller->index();
            } elseif (!$action && $method === 'POST') {
                $controller->store();
            } else {
                jsonError('Quote endpoint not found', 404);
            }
            break;

        case 'activity-logs':
            require_once __DIR__ . '/controllers/ActivityLogController.php';
            $controller = new ActivityLogController();
            
            if ($method === 'POST') {
                $controller->store();
            } else {
                jsonError('Activity logs endpoint not found', 404);
            }
            break;

        default:
            jsonError('Resource not found', 404);
    }

} catch (Exception $e) {
    jsonError('Internal server error: ' . $e->getMessage(), 500);
}
