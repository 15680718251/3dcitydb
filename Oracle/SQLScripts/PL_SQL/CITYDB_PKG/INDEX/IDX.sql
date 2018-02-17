-- 3D City Database - The Open Source CityGML Database
-- http://www.3dcitydb.org/
-- 
-- Copyright 2013 - 2018
-- Chair of Geoinformatics
-- Technical University of Munich, Germany
-- https://www.gis.bgu.tum.de/
-- 
-- The 3D City Database is jointly developed with the following
-- cooperation partners:
-- 
-- virtualcitySYSTEMS GmbH, Berlin <http://www.virtualcitysystems.de/>
-- M.O.S.S. Computer Grafik Systeme GmbH, Taufkirchen <http://www.moss.de/>
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
--     
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

/*****************************************************************
* TYPE INDEX_OBJ
* 
* global type to store information relevant to indexes
******************************************************************/
CREATE OR REPLACE TYPE INDEX_OBJ AS OBJECT
  (index_name VARCHAR2(30),
   table_name VARCHAR2(30),
   attribute_name VARCHAR2(30),
   parameters VARCHAR2(256),
   type NUMBER(1),
   srid NUMBER,
   is_3d NUMBER(1, 0),
     STATIC function construct_spatial_3d
     (index_name VARCHAR2, table_name VARCHAR2, attribute_name VARCHAR2, parameters VARCHAR2 := NULL, srid NUMBER := 0)
     RETURN INDEX_OBJ,
     STATIC function construct_spatial_2d
     (index_name VARCHAR2, table_name VARCHAR2, attribute_name VARCHAR2, parameters VARCHAR2 := NULL, srid NUMBER := 0)
     RETURN INDEX_OBJ,
     STATIC function construct_normal
     (index_name VARCHAR2, table_name VARCHAR2, attribute_name VARCHAR2, parameters VARCHAR2 := NULL, srid NUMBER := 0)
     RETURN INDEX_OBJ
  );
/

/*****************************************************************
* TYPE BODY INDEX_OBJ
* 
* constructors for INDEX_OBJ instances
******************************************************************/
CREATE OR REPLACE TYPE BODY INDEX_OBJ IS
  STATIC FUNCTION construct_spatial_3d
  (index_name VARCHAR2, table_name VARCHAR2, attribute_name VARCHAR2, parameters VARCHAR2 := NULL, srid NUMBER := 0)
  RETURN INDEX_OBJ IS
  BEGIN
    RETURN INDEX_OBJ(upper(index_name), upper(table_name), upper(attribute_name), parameters, 1, srid, 1);
  END;
  STATIC FUNCTION construct_spatial_2d
  (index_name VARCHAR2, table_name VARCHAR2, attribute_name VARCHAR2, parameters VARCHAR2 := NULL, srid NUMBER := 0)
  RETURN INDEX_OBJ IS
  BEGIN
    RETURN INDEX_OBJ(upper(index_name), upper(table_name), upper(attribute_name), parameters, 1, srid, 0);
  END;
  STATIC FUNCTION construct_normal
  (index_name VARCHAR2, table_name VARCHAR2, attribute_name VARCHAR2, parameters VARCHAR2 := NULL, srid NUMBER := 0)
  RETURN INDEX_OBJ IS
  BEGIN
    RETURN INDEX_OBJ(upper(index_name), upper(table_name), upper(attribute_name), parameters, 0, srid, 0);
  END;
END;
/

/******************************************************************
* INDEX_TABLE that holds INDEX_OBJ instances
* 
******************************************************************/
CREATE TABLE INDEX_TABLE (
  ID          NUMBER PRIMARY KEY,
  obj         INDEX_OBJ
);

CREATE SEQUENCE INDEX_TABLE_SEQ INCREMENT BY 1 START WITH 1 MINVALUE 1;

/******************************************************************
* Populate INDEX_TABLE with INDEX_OBJ instances
* 
******************************************************************/
INSERT INTO index_table (id, obj) VALUES (INDEX_TABLE_SEQ.nextval, INDEX_OBJ.construct_spatial_3d('CITYOBJECT_ENVELOPE_SPX', 'CITYOBJECT', 'ENVELOPE', 'PARALLEL'));
INSERT INTO index_table (id, obj) VALUES (INDEX_TABLE_SEQ.nextval, INDEX_OBJ.construct_spatial_3d('SURFACE_GEOM_SPX', 'SURFACE_GEOMETRY', 'GEOMETRY', 'PARALLEL'));
INSERT INTO index_table (id, obj) VALUES (INDEX_TABLE_SEQ.nextval, INDEX_OBJ.construct_spatial_3d('SURFACE_GEOM_SOLID_SPX', 'SURFACE_GEOMETRY', 'SOLID_GEOMETRY', 'PARAMETERS (''sdo_indx_dims=3'') PARALLEL'));
INSERT INTO index_table (id, obj) VALUES (INDEX_TABLE_SEQ.nextval, INDEX_OBJ.construct_normal('CITYOBJECT_INX', 'CITYOBJECT', 'GMLID, GMLID_CODESPACE'));
INSERT INTO index_table (id, obj) VALUES (INDEX_TABLE_SEQ.nextval, INDEX_OBJ.construct_normal('CITYOBJECT_LINEAGE_INX', 'CITYOBJECT', 'LINEAGE'));
INSERT INTO index_table (id, obj) VALUES (INDEX_TABLE_SEQ.nextval, INDEX_OBJ.construct_normal('SURFACE_GEOM_INX', 'SURFACE_GEOMETRY', 'GMLID, GMLID_CODESPACE'));
INSERT INTO index_table (id, obj) VALUES (INDEX_TABLE_SEQ.nextval, INDEX_OBJ.construct_normal('APPEARANCE_INX', 'APPEARANCE', 'GMLID, GMLID_CODESPACE'));
INSERT INTO index_table (id, obj) VALUES (INDEX_TABLE_SEQ.nextval, INDEX_OBJ.construct_normal('APPEARANCE_THEME_INX', 'APPEARANCE', 'THEME'));
INSERT INTO index_table (id, obj) VALUES (INDEX_TABLE_SEQ.nextval, INDEX_OBJ.construct_normal('SURFACE_DATA_INX', 'SURFACE_DATA', 'GMLID, GMLID_CODESPACE'));
INSERT INTO index_table (id, obj) VALUES (INDEX_TABLE_SEQ.nextval, INDEX_OBJ.construct_normal('ADDRESS_INX', 'ADDRESS', 'GMLID, GMLID_CODESPACE'));
COMMIT;

/*****************************************************************
* PACKAGE citydb_idx
* 
* utility methods for index handling
******************************************************************/
CREATE OR REPLACE PACKAGE citydb_idx AUTHID CURRENT_USER
AS
  FUNCTION index_status(idx INDEX_OBJ) RETURN VARCHAR2;
  FUNCTION index_status(table_name VARCHAR2, column_name VARCHAR2) RETURN VARCHAR2;
  FUNCTION status_spatial_indexes RETURN STRARRAY;
  FUNCTION status_normal_indexes RETURN STRARRAY;
  FUNCTION create_index(idx INDEX_OBJ, is_versioned BOOLEAN) RETURN VARCHAR2;
  FUNCTION drop_index(idx INDEX_OBJ, is_versioned BOOLEAN) RETURN VARCHAR2;
  FUNCTION create_spatial_indexes RETURN STRARRAY;
  FUNCTION drop_spatial_indexes RETURN STRARRAY;
  FUNCTION create_normal_indexes RETURN STRARRAY;
  FUNCTION drop_normal_indexes RETURN STRARRAY;
  FUNCTION get_index(table_name VARCHAR2, column_name VARCHAR2) RETURN INDEX_OBJ;
END citydb_idx;
/

CREATE OR REPLACE PACKAGE BODY citydb_idx
AS 
  NORMAL CONSTANT NUMBER(1) := 0;
  SPATIAL CONSTANT NUMBER(1) := 1;

  /*****************************************************************
  * index_status
  * 
  * @param idx index to retrieve status from
  * @return VARCHAR2 string representation of status, may include
  *                  'DROPPED', 'VALID', 'FAILED', 'INVALID'
  ******************************************************************/
  FUNCTION index_status(
    idx INDEX_OBJ
    ) RETURN VARCHAR2
  IS
    status VARCHAR2(20);
  BEGIN
    IF idx.type = SPATIAL THEN
      SELECT
        upper(domidx_opstatus)
      INTO
        status
      FROM
        user_indexes
      WHERE
        index_name = idx.index_name;
    ELSE
      SELECT
        upper(status)
      INTO
        status
      FROM
        user_indexes
      WHERE
        index_name = idx.index_name;
    END IF;

    RETURN status;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'DROPPED';
    WHEN others THEN
      RETURN 'INVALID';
  END;

  /*****************************************************************
  * index_status
  * 
  * @param table_name table_name of index to retrieve status from
  * @param column_name column_name of index to retrieve status from
  * @return VARCHAR2 string representation of status, may include
  *                  'DROPPED', 'VALID', 'FAILED', 'INVALID'
  ******************************************************************/
  FUNCTION index_status(
    table_name VARCHAR2, 
    column_name VARCHAR2
    ) RETURN VARCHAR2
  IS
    internal_table_name VARCHAR2(100);
    index_type VARCHAR2(35);
    index_name VARCHAR2(35);
    status VARCHAR2(20);
  BEGIN
    internal_table_name := table_name;

    IF citydb_util.versioning_table(table_name) = 'ON' THEN
      internal_table_name := table_name || '_LT';
    END IF;     

    SELECT
      upper(index_type),
      index_name
    INTO
      index_type,
      index_name
    FROM
      user_indexes
    WHERE
      index_name = (
        SELECT
          upper(index_name)
        FROM
          user_ind_columns
        WHERE 
          table_name = upper(internal_table_name)
          AND column_name = upper(column_name)
      );

    IF index_type = 'DOMAIN' THEN
      SELECT
        upper(domidx_opstatus)
      INTO
        status
      FROM
        user_indexes
      WHERE
        index_name = index_name;
    ELSE
      SELECT
        upper(status)
      INTO
        status
      FROM
        user_indexes
      WHERE
        index_name = index_name;
    END IF;

    RETURN status;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'DROPPED';
    WHEN others THEN
      RETURN 'INVALID';
  END;

  /*****************************************************************
  * create_spatial_metadata (private)
  * 
  * @param idx index to create metadata for
  * @param is_versioned TRUE if database table is version-enabled
  ******************************************************************/
  PROCEDURE create_spatial_metadata(
    idx INDEX_OBJ, 
    is_versioned BOOLEAN
    )
  IS
    table_name VARCHAR2(100);
    schema_srid DATABASE_SRS.SRID%TYPE;
  BEGIN
    table_name := idx.table_name;

    IF is_versioned THEN
      table_name := table_name || '_LT';
    END IF;    

    DELETE FROM
      user_sdo_geom_metadata
    WHERE
      table_name = table_name
      AND column_name = idx.attribute_name;

    IF idx.srid = 0 THEN
      SELECT srid INTO schema_srid FROM database_srs;
    ELSE
      schema_srid := idx.srid;
    END IF;

    IF idx.is_3d = 0 THEN
      INSERT INTO
        user_sdo_geom_metadata (table_name, column_name, diminfo, srid)
      VALUES (
        table_name,
        idx.attribute_name,
        MDSYS.SDO_DIM_ARRAY(
          MDSYS.SDO_DIM_ELEMENT('X', 0.000, 10000000.000, 0.0005), 
          MDSYS.SDO_DIM_ELEMENT('Y', 0.000, 10000000.000, 0.0005)
        ),
        schema_srid
      );
    ELSE
      INSERT INTO
        user_sdo_geom_metadata (table_name, column_name, diminfo, srid)
      VALUES (
        table_name,
        idx.attribute_name,
        MDSYS.SDO_DIM_ARRAY(
          MDSYS.SDO_DIM_ELEMENT('X', 0.000, 10000000.000, 0.0005), 
          MDSYS.SDO_DIM_ELEMENT('Y', 0.000, 10000000.000, 0.0005),
          MDSYS.SDO_DIM_ELEMENT('Z', -1000, 10000, 0.0005)
        ),
        schema_srid
      );
    END IF;    
  END;

  /*****************************************************************
  * create_index
  * 
  * @param idx index to create
  * @param is_versioned TRUE if database table is version-enabled
  * @return VARCHAR2 sql error code, 0 for no errors
  ******************************************************************/
  FUNCTION create_index(
    idx INDEX_OBJ,
    is_versioned BOOLEAN
    ) RETURN VARCHAR2
  IS
    create_ddl VARCHAR2(1000);
    table_name VARCHAR2(100);
    sql_err_code VARCHAR2(20);
  BEGIN    
    IF index_status(idx) <> 'VALID' THEN
      sql_err_code := drop_index(idx, is_versioned);

      BEGIN
        table_name := idx.table_name;

        IF is_versioned THEN
          dbms_wm.BEGINDDL(idx.table_name);
          table_name := table_name || '_LTS';
        END IF;

        create_ddl :=
          'CREATE INDEX '
          || idx.index_name
          || ' ON ' || table_name
          || ' (' || idx.attribute_name || ')';

        -- we cannot create spatial metadata for different users 
        IF idx.type = SPATIAL THEN
          create_spatial_metadata(idx, is_versioned);
          create_ddl := create_ddl || ' INDEXTYPE is MDSYS.SPATIAL_INDEX';
        END IF;

        IF idx.parameters is not null THEN
          create_ddl := create_ddl || ' ' || idx.parameters;
        END IF;

        EXECUTE IMMEDIATE create_ddl;

        IF is_versioned THEN
          dbms_wm.COMMITDDL(idx.table_name);
        END IF;

      EXCEPTION
        WHEN others THEN
          dbms_output.put_line(SQLERRM);

          IF is_versioned THEN
            dbms_wm.ROLLBACKDDL(idx.table_name);
          END IF;

          RETURN SQLCODE;
      END;
    END IF;
    
    RETURN '0';
  END;
  
  /*****************************************************************
  * drop_index
  * 
  * @param idx index to drop
  * @param is_versioned TRUE if database table is version-enabled
  * @return VARCHAR2 sql error code, 0 for no errors
  ******************************************************************/
  FUNCTION drop_index(
    idx INDEX_OBJ, 
    is_versioned BOOLEAN
    ) RETURN VARCHAR2
  IS
    index_name VARCHAR2(100);
  BEGIN
    IF index_status(idx) <> 'DROPPED' THEN
      BEGIN
        index_name := idx.index_name;

        IF is_versioned THEN
          dbms_wm.BEGINDDL(idx.table_name);
          index_name := index_name || '_LTS';
        END IF;

        EXECUTE IMMEDIATE 'DROP INDEX ' || index_name;

        IF is_versioned THEN
          dbms_wm.COMMITDDL(idx.table_name);
        END IF;
      EXCEPTION
        WHEN others THEN
          dbms_output.put_line(SQLERRM);

          IF is_versioned THEN
            dbms_wm.ROLLBACKDDL(idx.table_name);
          END IF;

          RETURN SQLCODE;
      END;
    END IF;
    
    RETURN '0';
  END;

  /*****************************************************************
  * create_indexes
  * private convenience method for invoking create_index on indexes 
  * of same index type
  * 
  * @param type type of index, e.g. SPATIAL or NORMAL
  * @return STRARRAY array of log message strings
  ******************************************************************/
  FUNCTION create_indexes(
    type SMALLINT
    ) RETURN STRARRAY
  IS
    log STRARRAY;
    sql_error_code VARCHAR2(20);
  BEGIN
    log := STRARRAY();

    FOR rec IN (SELECT * FROM index_table) LOOP
      IF rec.obj.type = type THEN
        sql_error_code := create_index(rec.obj, citydb_util.versioning_table(rec.obj.table_name) = 'ON');
        log.extend;
        log(log.count) := index_status(rec.obj)
          || ':' || rec.obj.index_name
          || ':' || rec.obj.table_name
          || ':' || rec.obj.attribute_name
          || ':' || sql_error_code;
      END IF;
    END LOOP;

    RETURN log;
  END;
  
  /*****************************************************************
  * drop_indexes
  * private convenience method for invoking drop_index on indexes 
  * of same index type
  * 
  * @param type type of index, e.g. SPATIAL or NORMAL
  * @return STRARRAY array of log message strings
  ******************************************************************/
  FUNCTION drop_indexes(type SMALLINT) RETURN STRARRAY
  IS
    log STRARRAY;
    sql_error_code VARCHAR2(20);
  BEGIN
    log := STRARRAY();
    
    FOR rec IN (SELECT * FROM index_table) LOOP
      IF rec.obj.type = type THEN
        sql_error_code := drop_index(rec.obj, citydb_util.versioning_table(rec.obj.table_name) = 'ON');
        log.extend;
        log(log.count) := index_status(rec.obj)
          || ':' || rec.obj.index_name
          || ':' || rec.obj.table_name
          || ':' || rec.obj.attribute_name
          || ':' || sql_error_code;
      END IF;
    END LOOP; 

    RETURN log;
  END;

  /*****************************************************************
  * status_spatial_indexes
  *
  * @return STRARRAY array of log message strings
  ******************************************************************/
  FUNCTION status_spatial_indexes RETURN STRARRAY
  IS
    log STRARRAY;
    status VARCHAR2(20);
  BEGIN
    log := STRARRAY();

    FOR rec IN (SELECT * FROM index_table) LOOP
      IF rec.obj.type = SPATIAL THEN
        status := index_status(rec.obj);
        log.extend;
        log(log.count) := status
          || ':' || rec.obj.index_name
          || ':' || rec.obj.table_name
          || ':' || rec.obj.attribute_name;
      END IF;
    END LOOP;

    RETURN log;
  END;

  /*****************************************************************
  * status_normal_indexes
  *
  * @return STRARRAY array of log message strings
  ******************************************************************/
  FUNCTION status_normal_indexes RETURN STRARRAY
  IS
    log STRARRAY;
    status VARCHAR2(20);
  BEGIN
    log := STRARRAY();

    FOR rec IN (SELECT * FROM index_table) LOOP
      IF rec.obj.type = NORMAL THEN
        status := index_status(rec.obj);
        log.extend;
        log(log.count) := status
          || ':' || rec.obj.index_name
          || ':' || rec.obj.table_name
          || ':' || rec.obj.attribute_name;
      END IF;
    END LOOP;

    RETURN log;
  END;

  /*****************************************************************
  * create_spatial_indexes
  * convenience method for invoking create_index on all spatial indexes 
  *
  * @return STRARRAY array of log message strings
  ******************************************************************/
  FUNCTION create_spatial_indexes RETURN STRARRAY
  IS
  BEGIN
    dbms_output.enable;
    RETURN create_indexes(SPATIAL);
  END;

  /*****************************************************************
  * drop_spatial_indexes
  * convenience method for invoking drop_index on all spatial indexes 
  *
  * @return STRARRAY array of log message strings
  ******************************************************************/
  FUNCTION drop_spatial_indexes RETURN STRARRAY
  IS
  BEGIN
    dbms_output.enable;
    RETURN drop_indexes(SPATIAL);
  END;

  /*****************************************************************
  * create_normal_indexes
  * convenience method for invoking create_index on all normal indexes 
  *
  * @return STRARRAY array of log message strings
  ******************************************************************/
  FUNCTION create_normal_indexes RETURN STRARRAY
  IS
  BEGIN
    dbms_output.enable;
    RETURN create_indexes(NORMAL);
  END;

  /*****************************************************************
  * drop_normal_indexes
  * convenience method for invoking drop_index on all normal indexes 
  *
  * @return STRARRAY array of log message strings
  ******************************************************************/
  FUNCTION drop_normal_indexes RETURN STRARRAY
  IS
  BEGIN
    dbms_output.enable;
    RETURN drop_indexes(NORMAL);
  END;

  /*****************************************************************
  * get_index
  * convenience method for getting an index object 
  * given the table and column it indexes
  * 
  * @param table_name
  * @param column_name
  * @return INDEX_OBJ
  ******************************************************************/
  FUNCTION get_index(
    table_name VARCHAR2, 
    column_name VARCHAR2
	) RETURN INDEX_OBJ
  IS
    idx INDEX_OBJ;
  BEGIN
    FOR rec IN (SELECT * FROM index_table) LOOP
      IF rec.obj.attribute_name = upper(column_name) AND rec.obj.table_name = upper(table_name) THEN
        idx := rec.obj;
        EXIT;
      END IF;
    END LOOP;

    RETURN idx;
  END;
END citydb_idx;
/