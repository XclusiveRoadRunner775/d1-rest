import { Hono, Context, Next } from "hono";
import { cors } from "hono/cors";
import { secureHeaders } from "hono/secure-headers";
import { handleRest } from './rest';

export interface Env {
    DB: D1Database;
    SECRET: SecretsStoreSecret;
}

// Rate limiting configuration
const RATE_LIMIT_WINDOW = 60000; // 1 minute
const MAX_REQUESTS = 100;
const requestCounts = new Map<string, { count: number; resetTime: number }>();

// # List all users
// GET /rest/users

// # Get filtered and sorted users
// GET /rest/users?age=25&sort_by=name&order=desc

// # Get paginated results
// GET /rest/users?limit=10&offset=20

// # Create a new user
// POST /rest/users
// { "name": "John", "age": 30 }

// # Update a user
// PATCH /rest/users/123
// { "age": 31 }

// # Delete a user
// DELETE /rest/users/123

export default {
    async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
        const app = new Hono<{ Bindings: Env }>();

        // Apply security headers to all routes
        app.use('*', secureHeaders({
            contentSecurityPolicy: {
                defaultSrc: ["'self'"],
                scriptSrc: ["'self'", "'unsafe-inline'"],
                styleSrc: ["'self'", "'unsafe-inline'"],
                imgSrc: ["'self'", "data:", "https:"],
                connectSrc: ["'self'"],
                fontSrc: ["'self'"],
                objectSrc: ["'none'"],
                mediaSrc: ["'self'"],
                frameSrc: ["'none'"]
            },
            strictTransportSecurity: "max-age=63072000; includeSubDomains; preload",
            xFrameOptions: "DENY",
            xContentTypeOptions: "nosniff",
            referrerPolicy: "strict-origin-when-cross-origin",
            permissionsPolicy: {
                camera: ["()"]
            }
        }));

        // Apply CORS to all routes
        app.use('*', async (c, next) => {
            return cors({
                origin: '*',
                allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
                allowHeaders: ['Content-Type', 'Authorization'],
                maxAge: 86400
            })(c, next);
        });

        // Rate limiting middleware
        app.use('*', async (c, next) => {
            const clientIP = c.req.header('cf-connecting-ip') || c.req.header('x-forwarded-for') || 'unknown';
            const now = Date.now();
            const clientData = requestCounts.get(clientIP);

            if (clientData) {
                if (now > clientData.resetTime) {
                    requestCounts.set(clientIP, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
                } else if (clientData.count >= MAX_REQUESTS) {
                    return c.json({ error: 'Too many requests. Please try again later.' }, 429);
                } else {
                    clientData.count++;
                }
            } else {
                requestCounts.set(clientIP, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
            }

            return next();
        })

        // Secret Store key value that we have set
        const secret = await env.SECRET.get();

        // Authentication middleware that verifies the Authorization header
        // is sent in on each request and matches the value of our Secret key.
        // If a match is not found we return a 401 and prevent further access.
        const authMiddleware = async (c: Context, next: Next) => {
            const authHeader = c.req.header('Authorization');
            if (!authHeader) {
                c.header('WWW-Authenticate', 'Bearer realm="API"');
                return c.json({ error: 'Unauthorized: Missing authentication token' }, 401);
            }

            const token = authHeader.startsWith('Bearer ')
                ? authHeader.substring(7)
                : authHeader;

            // Constant-time comparison to prevent timing attacks
            if (token.length !== secret.length || token !== secret) {
                c.header('WWW-Authenticate', 'Bearer realm="API"');
                return c.json({ error: 'Unauthorized: Invalid authentication token' }, 401);
            }

            return next();
        };

        // CRUD REST endpoints made available to all of our tables
        app.all('/rest/*', authMiddleware, handleRest);

        // Execute a raw SQL statement with parameters with this route
        app.post('/query', authMiddleware, async (c) => {
            try {
                const body = await c.req.json();
                const { query, params } = body;

                if (!query || typeof query !== 'string') {
                    return c.json({ error: 'Valid query string is required' }, 400);
                }

                // Prevent multiple statements and dangerous operations
                const trimmedQuery = query.trim().toLowerCase();
                if (trimmedQuery.includes(';') && trimmedQuery.split(';').filter(s => s.trim()).length > 1) {
                    return c.json({ error: 'Multiple SQL statements are not allowed' }, 400);
                }

                // Block dangerous operations in raw queries
                const dangerousPatterns = [
                    /\bdrop\s+table\b/i,
                    /\bdrop\s+database\b/i,
                    /\btruncate\b/i,
                    /\balter\s+table\b/i
                ];

                if (dangerousPatterns.some(pattern => pattern.test(query))) {
                    return c.json({ error: 'Query contains potentially dangerous operations' }, 403);
                }

                // Validate params is an array if provided
                if (params !== undefined && !Array.isArray(params)) {
                    return c.json({ error: 'Parameters must be an array' }, 400);
                }

                // Execute the query against D1 database
                const results = await env.DB.prepare(query)
                    .bind(...(params || []))
                    .all();

                return c.json(results);
            } catch (error: any) {
                // Don't expose internal error details
                console.error('Query error:', error);
                return c.json({ error: 'Internal server error processing query' }, 500);
            }
        });

        return app.fetch(request, env, ctx);
    }
} satisfies ExportedHandler<Env>;
