-- ### geojson.io transform query ###
select
	jsonb_build_object(
		'type', 'FeatureCollection',
		'features',
			array_to_json(
				array(
					select
					jsonb_build_object(
						'type', 'Feature',
						'properties', jsonb_build_object('postcode', postcode),
						'geometry',jsonb_build_object(
							'type', 'Polygon',
							'coordinates', jsonb_build_array(make_json_coord_untyped_array_from_polygon(make_polygon_from_json_coord_array(geoms)))
						)
					)
					from postcodes pc where pc.iso = 'FI' --and (postcode like '0%' or  postcode like '1%')
				)
			, true)
	)

-- ### Creates minimal POLYGON from postcode aggregated jsonb points ###
CREATE OR REPLACE FUNCTION make_polygon_from_json_coord_array(coord_array jsonb)
  RETURNS Geometry AS
$BODY$

select st_convexhull(st_collect(ARRAY(
	select st_buffer(st_makepoint(x, y), 0.01) point FROM
	(
		select cast((jsonb_array_elements(coord_array)->'lo')::text as FLOAT) x , cast((jsonb_array_elements(coord_array)->'lt')::text as FLOAT) y
	) coords
 )))

$BODY$
  LANGUAGE sql IMMUTABLE
  COST 100;


-- ### Transforms POLYGON into single points as jsonb array of arrays (lat & lon as array)
CREATE OR REPLACE FUNCTION make_json_coord_untyped_array_from_polygon(the_geom Geometry)
  RETURNS jsonb AS
$BODY$

select array_to_json(array(
 select jsonb_build_array(st_X(point), st_Y(point)) from (
	select (
		st_dumppoints(the_geom)).geom as point
	) points))::jsonb

$BODY$
  LANGUAGE sql IMMUTABLE
  COST 100;

