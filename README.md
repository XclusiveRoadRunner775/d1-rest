# d1-secret-rest
Fetch results or execute queries against a D1 CRUD REST API

## Performance
This REST API implementation offers significantly faster performance compared to the official D1 API:

| API | Avg. Speed | Avg. Response Time |
|-----|------------|-------------------|
| d1-secret-rest | 1,729 bytes/sec | 0.22 seconds |
| Official D1 API | 574 bytes/sec | 0.79 seconds |

> Based on benchmark testing with identical queries. d1-secret-rest performs ~3x faster on average.

## Quick Start
```bash
# Example: Get users with filtering and pagination
curl --location 'https://d1-rest.<YOUR-IDENTIFIER>.workers.dev/rest/users?limit=2&age=25' \
--header 'Authorization: Bearer <YOUR-SECRET-VALUE>'

# Example: Execute raw SQL query
curl --location 'https://d1-rest.<YOUR-IDENTIFIER>.workers.dev/query' \
--header 'Authorization: Bearer <YOUR-SECRET-VALUE>' \
--header 'Content-Type: application/json' \
--data '{
    "query": "SELECT * FROM users WHERE age > ? LIMIT ?;",
    "params": [21, 2]
}'
```

## Authentication
All endpoints require authentication using a Bearer token:
```bash
--header 'Authorization: Bearer <YOUR-SECRET-VALUE>'
```

## REST API Endpoints

### List Records
```bash
# Basic listing
GET /rest/{table}

# With filtering
GET /rest/{table}?column_name=value
GET /rest/{table}?age=25&status=active

# With sorting
GET /rest/{table}?sort_by=column_name&order=asc
GET /rest/{table}?sort_by=name&order=desc

# With pagination
GET /rest/{table}?limit=10&offset=20

# Combined example
GET /rest/{table}?age=25&sort_by=name&order=desc&limit=10&offset=20
```

### Get Single Record
```bash
GET /rest/{table}/{id}
```

### Create Record
```bash
POST /rest/{table}
Content-Type: application/json

{
    "column1": "value1",
    "column2": "value2"
}
```

Example:
```bash
POST /rest/users
Content-Type: application/json

{
    "name": "John Doe",
    "age": 30,
    "email": "john@example.com"
}
```

### Update Record
```bash
PATCH /rest/{table}/{id}
Content-Type: application/json

{
    "column1": "new_value"
}
```

Example:
```bash
PATCH /rest/users/123
Content-Type: application/json

{
    "age": 31,
    "email": "john.doe@example.com"
}
```

### Delete Record
```bash
DELETE /rest/{table}/{id}
```

## Raw SQL Queries
For more complex queries, you can use the raw SQL endpoint:

```bash
POST /query
Content-Type: application/json

{
    "query": "SELECT * FROM users WHERE age > ? AND status = ? LIMIT ?;",
    "params": [21, "active", 10]
}
```

## Query Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `sort_by` | Column to sort by | `sort_by=name` |
| `order` | Sort order (asc/desc) | `order=desc` |
| `limit` | Maximum number of records to return | `limit=10` |
| `offset` | Number of records to skip | `offset=20` |
| Any column name | Filter by column value | `age=25` |

## Response Format

### Successful Response
```json
{
    "success": true,
    "meta": {
        "served_by": "v3-prod",
        "served_by_region": "ENAM",
        "served_by_primary": true,
        "timings": {
            "sql_duration_ms": 0.1746
        },
        "duration": 0.1746,
        "changes": 0,
        "last_row_id": 0,
        "changed_db": false,
        "size_after": 28672,
        "rows_read": 2,
        "rows_written": 0
    },
    "results": [
        {
            "user_id": 1,
            "name": "Alice",
            "email": "alice@example.com"
        },
        {
            "user_id": 2,
            "name": "Bob",
            "email": "bob@example.com"
        }
    ]
}
```

### Error Response
```json
{
    "success": false,
    "error": "Error message here"
}
```

The response includes:
- `success`: Boolean indicating if the request was successful
- `meta`: Execution metadata including timing and database statistics
- `results`: Array of returned records (for GET requests)

## Security Notes
- All column names and table names are sanitized to prevent SQL injection
- Only alphanumeric characters and underscores are allowed in identifiers
- Authentication is required for all endpoints