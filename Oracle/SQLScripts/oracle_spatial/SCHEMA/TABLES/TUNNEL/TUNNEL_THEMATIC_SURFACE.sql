-- TUNNEL_THEMATIC_SURFACE.sql
--
-- Authors:     Prof. Dr. Thomas H. Kolbe <thomas.kolbe@tum.de>
--              Zhihang Yao <zhihang.yao@tum.de>
--              Claus Nagel <cnagel@virtualcitysystems.de>
--              Philipp Willkomm <pwillkomm@moss.de>
--              Gerhard K�nig <gerhard.koenig@tu-berlin.de>
--              Alexandra Lorenz <di.alex.lorenz@googlemail.com>
--
-- Copyright:   (c) 2012-2014  Chair of Geoinformatics,
--                             Technische Universit�t M�nchen, Germany
--                             http://www.gis.bv.tum.de
--
--              (c) 2007-2012  Institute for Geodesy and Geoinformation Science,
--                             Technische Universit�t Berlin, Germany
--                             http://www.igg.tu-berlin.de
--
--              This skript is free software under the LGPL Version 2.1.
--              See the GNU Lesser General Public License at
--              http://www.gnu.org/copyleft/lgpl.html
--              for more details.
-------------------------------------------------------------------------------
-- About:
--
--
-------------------------------------------------------------------------------
--
-- ChangeLog:
--
-- Version | Date       | Description                               | Author
-- 3.0.0     2013-12-06   new version for 3DCityDB V3                 ZYao
--                                                                    TKol
--                                                                    CNag
--                                                                    PWil
--
CREATE TABLE TUNNEL_THEMATIC_SURFACE 
(
ID NUMBER NOT NULL,
OBJECTCLASS_ID NUMBER,
TUNNEL_ID NUMBER,
TUNNEL_HOLLOWSPACE_ID NUMBER,
TUNNEL_INSTALLATION_ID NUMBER,
LOD2_MULTI_SURFACE_ID NUMBER,
LOD3_MULTI_SURFACE_ID NUMBER,
LOD4_MULTI_SURFACE_ID NUMBER
)
;
ALTER TABLE TUNNEL_THEMATIC_SURFACE
ADD CONSTRAINT TUNNEL_THEMATIC_SURFACE_PK PRIMARY KEY 
(
  ID 
)
  ENABLE 
; 