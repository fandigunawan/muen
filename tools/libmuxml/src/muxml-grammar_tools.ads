--
--  Copyright (C) 2023 secunet Security Networks AG
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

with Ada.Containers.Indefinite_Ordered_Maps;

package Muxml.Grammar_Tools
is
   type Insert_Query_Result_Type is range -2 .. Integer'Last;
   subtype Insert_Index is Insert_Query_Result_Type
      range 0 .. Insert_Query_Result_Type'Last;
   No_Unique_Index : constant Insert_Query_Result_Type := -1;
   No_Legal_Index  : constant Insert_Query_Result_Type := -2;

   use type String_Vector.Vector;

   --  This function is used to tell amend and other tools where to insert a
   --  particular node.
   --  Returns an index before which New_Child can be inserted such that
   --    the schema is satisfied (e.g. "0" means "before the first child").
   --  Ancestors is a list always containing the name of the parent P of
   --    New_Child. More names of ancestors may follow in order of distance
   --    (starting with the parent of P).
   --  Siblings: names of children of P, in order of appearance in P.
   --    Application-Note: It is legal to substitute consecutive subsequences
   --    of equal names to one name. E.g.:
   --        ([...]^1, "channel", "channel", "channel", [...]^2)
   --     -> ([...]^1, "channel", [...]^2)
   --  "After the last sibling" is expressed by index Length(Siblings)
   --  No_Unique_Index is returned if a correct index cannot be determined
   --    (missing information).
   --  No_Legal_Index is returned if no legal insertion position exists
   --    (error).
   function Get_Insert_Index
      (Ancestors : String_Vector.Vector;
       New_Child : String;
       Siblings  : String_Vector.Vector)
      return Insert_Query_Result_Type;

   --  Starting from the root-node N: Delete all children of N that
   --  cannot be a child of N according to the currently
   --  loaded schema information (loadable with Init_Order_Information).
   --  Afterwards, recurses into the remaining children of N.
   --  Only tag-names are evaluated.
   procedure Filter_XML (XML_Data : Muxml.XML_Data_Type);

   --  Raised if the schema uses a construction which is not supported.
   Not_Implemented : exception;

   -- raised if the schema is not compliant with
   -- https://www.w3.org/TR/xmlschema-0/
   Validation_Error : exception;

   --  Read the given schema definition and write the
   --  following to the internal package state:
   --  (1) a mapping of the form
   --     "typename -> ((nodename1, nodename2, ...),
   --                   (type nodename1, type nodename2, ...))"  and
   --  (2) a mapping of the form
   --     "nodename  -> (unique typename of nodename)".
   --  The procedure overwrites any former order information.
   procedure Init_Order_Information (Schema_XML_Data : String);

private

   --  Raised only internally to signal that a certain query cannot be decided.
   Insufficient_Information : exception;

   type Vector_Tuple is
   record
      Node_Names : String_Vector.Vector;
      Type_Names : String_Vector.Vector;
   end record;

   --  Used for a mapping from 'typename' to
   --  ('element-node in that type', 'types of these element-nodes').
   package String_To_Vector_Tuple is new Ada.Containers.Indefinite_Ordered_Maps
      (Key_Type     => String,
       Element_Type => Vector_Tuple);

   --  Used as a temporary holder for multiple strings.
   package String_To_String_Vector is new  Ada.Containers.Indefinite_Ordered_Maps
      (Key_Type     => String,
       Element_Type => String_Vector.Vector);

   --  Type of the internal state of the package.
   type Order_Information is
   record
      Type_To_Children : String_To_Vector_Tuple.Map;
      Name_To_Type     : String_To_String_Vector.Map;
   end record;

   --  The package extracts schema-information at elaboration time and stores
   --  its results in Order_Info.
   Order_Info : Order_Information;

   --  Return a string representation of Order_Information.
   --  More To_String functions are implemented in the body.
   --  This function is in the spec because it is used in the unittests.
   function To_String (OI : Order_Information) return String;

end Muxml.Grammar_Tools;
