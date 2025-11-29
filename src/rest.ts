import { Context } from 'hono';
import type { Env } from './index';

/**
 * Sanitizes an identifier by removing all non-alphanumeric characters except underscores.
 */
function sanitizeIdentifier(identifier: string): string {
    return identifier.replace(/[^a-zA-Z0-9_]/g, '');
}

/**
 * Processing when the table name is a keyword in SQLite.
 */
function sanitizeKeyword(identifier: string): string {
    return '`'+sanitizeIdentifier(identifier)+'`';
}

/**
 * Handles GET requests to fetch records from a table
 */
async function handleGet(c: Context<{ Bindings: Env }>, tableName: string, id?: string): Promise<Response> {
    const table = sanitizeKeyword(tableName);
    const searchParams = new URL(c.req.url).searchParams;
    
    try {
        let query = `SELECT * FROM ${table}`;
        const params: any[] = [];
        const conditions: string[] = [];

        // Handle ID filter
        if (id) {
            conditions.push('id = ?');
            params.push(id);
        }

        // Handle search parameters (basic filtering)
        for (const [key, value] of searchParams.entries()) {
            if (['sort_by', 'order', 'limit', 'offset'].includes(key)) continue;
            
            const sanitizedKey = sanitizeIdentifier(key);
            conditions.push(`${sanitizedKey} = ?`);
            params.push(value);
        }

        // Add WHERE clause if there are conditions
        if (conditions.length > 0) {
            query += ` WHERE ${conditions.join(' AND ')}`;
        }

        // Handle sorting
        const sortBy = searchParams.get('sort_by');
        if (sortBy) {
            const order = searchParams.get('order')?.toUpperCase() === 'DESC' ? 'DESC' : 'ASC';
            query += ` ORDER BY ${sanitizeIdentifier(sortBy)} ${order}`;
        }

        // Handle pagination
        const limit = searchParams.get('limit');
        if (limit) {
            query += ` LIMIT ?`;
            params.push(parseInt(limit));

            const offset = searchParams.get('offset');
            if (offset) {
                query += ` OFFSET ?`;
                params.push(parseInt(offset));
            }
        }

        const results = await c.env.DB.prepare(query)
            .bind(...params)
            .all();

        return c.json(results);
    } catch (error: any) {
        return c.json({ error: error.message }, 500);
    }
}

/**
 * Handles POST requests to create new records
 */
async function handlePost(c: Context<{ Bindings: Env }>, tableName: string): Promise<Response> {
    const table = sanitizeKeyword(tableName);
    const data = await c.req.json();

    if (!data || typeof data !== 'object' || Array.isArray(data)) {
        return c.json({ error: 'Invalid data format' }, 400);
    }

    try {
        const columns = Object.keys(data).map(sanitizeIdentifier);
        const placeholders = columns.map(() => '?').join(', ');
        const query = `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${placeholders})`;
        const params = columns.map(col => data[col]);

        const result = await c.env.DB.prepare(query)
            .bind(...params)
            .run();

        return c.json({ message: 'Resource created successfully', data }, 201);
    } catch (error: any) {
        return c.json({ error: error.message }, 500);
    }
}

/**
 * Handles PUT/PATCH requests to update records
 */
async function handleUpdate(c: Context<{ Bindings: Env }>, tableName: string, id: string): Promise<Response> {
    const table = sanitizeKeyword(tableName);
    const data = await c.req.json();

    if (!data || typeof data !== 'object' || Array.isArray(data)) {
        return c.json({ error: 'Invalid data format' }, 400);
    }

    try {
        const setColumns = Object.keys(data)
            .map(sanitizeIdentifier)
            .map(col => `${col} = ?`)
            .join(', ');

        const query = `UPDATE ${table} SET ${setColumns} WHERE id = ?`;
        const params = [...Object.values(data), id];

        const result = await c.env.DB.prepare(query)
            .bind(...params)
            .run();

        return c.json({ message: 'Resource updated successfully', data });
    } catch (error: any) {
        return c.json({ error: error.message }, 500);
    }
}

/**
 * Handles DELETE requests to remove records
 */
async function handleDelete(c: Context<{ Bindings: Env }>, tableName: string, id: string): Promise<Response> {
    const table = sanitizeKeyword(tableName);

    try {
        const query = `DELETE FROM ${table} WHERE id = ?`;
        const result = await c.env.DB.prepare(query)
            .bind(id)
            .run();

        return c.json({ message: 'Resource deleted successfully' });
    } catch (error: any) {
        return c.json({ error: error.message }, 500);
    }
}

/**
 * Main REST handler that routes requests to appropriate handlers
 */
export async function handleRest(c: Context<{ Bindings: Env }>): Promise<Response> {
    const url = new URL(c.req.url);
    const pathParts = url.pathname.split('/').filter(Boolean);
    
    if (pathParts.length < 2) {
        return c.json({ error: 'Invalid path. Expected format: /rest/{tableName}/{id?}' }, 400);
    }

    const tableName = pathParts[1];
    const id = pathParts[2];
    
    switch (c.req.method) {
        case 'GET':
            return handleGet(c, tableName, id);
        case 'POST':
            return handlePost(c, tableName);
        case 'PUT':
        case 'PATCH':
            if (!id) return c.json({ error: 'ID is required for updates' }, 400);
            return handleUpdate(c, tableName, id);
        case 'DELETE':
            if (!id) return c.json({ error: 'ID is required for deletion' }, 400);
            return handleDelete(c, tableName, id);
        default:
            return c.json({ error: 'Method not allowed' }, 405);
    }
} 