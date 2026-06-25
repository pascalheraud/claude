---
name: backend-db-postgis
description: PostGIS geometry column conventions — coordinate order, SRID, insert syntax, test schema differences
---

# PostGIS Conventions

## Geometry columns

- Columns are of type `geometry` (PostGIS), no explicit SRID declared in DDL
- Coordinates are stored as **(longitude, latitude)** — use `ST_FlipCoordinates` if importing lat/lon data
- Use `st_geomfromtext('POINT(lon lat)')` for inserts

## In test schemas

- Use an explicit SRID: `GEOMETRY(Point, 4326)` instead of bare `geometry` (Testcontainers / test setup may require it)
