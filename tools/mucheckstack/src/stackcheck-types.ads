--
--  Copyright (C) 2017  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2017  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

private with Ada.Strings.Unbounded;
private with Ada.Containers.Doubly_Linked_Lists;

package Stackcheck.Types
is

   --  Subprogram information related to stack usage.
   type Subprogram_Type is private;

   Null_Subprogram : constant Subprogram_Type;

   --  Create subprogram with given information.
   function Create
     (Name        : String;
      Stack_Usage : Natural)
      return Subprogram_Type;

   --  Returns the name of the given subprogram.
   function Get_Name (Subprogram : Subprogram_Type) return String;

   --  Returns the stack usage of the given subprogram.
   function Get_Stack_Usage (Subprogram : Subprogram_Type) return Natural;

   --  Returns the worst-case stack usage of the subprogram by considering all
   --  calls made.
   function Get_Max_Stack_Usage (Subprogram : Subprogram_Type) return Natural;

   --  Set worst-case stack usage of given subprogram to specified value.
   procedure Set_Max_Stack_Usage
     (Subprogram : in out Subprogram_Type;
      Value      :        Natural);

   --  Add call with given name to subprogram.
   procedure Add_Call
     (Subprogram  : in out Subprogram_Type;
      Callee_Name :        String);

   --  Return the number of calls of the given subprogram.
   function Get_Call_Count (Subprogram : Subprogram_Type) return Natural;

   --  Invokes the specified Process procedure for each call of the given
   --  subprogram.
   procedure Iterate_Calls
     (Subprogram : Subprogram_Type;
      Process    : not null access procedure (Callee : String));

private

   use Ada.Strings.Unbounded;

   package List_of_Subprogram_Calls is new Ada.Containers.Doubly_Linked_Lists
     (Element_Type => Unbounded_String);
   package LOSC renames List_of_Subprogram_Calls;

   type Subprogram_Type is record
      Name            : Unbounded_String;
      Own_Stack_Usage : Natural;
      Max_Stack_Usage : Natural;
      Calls           : LOSC.List;
   end record;

   Null_Subprogram : constant Subprogram_Type
     := (Name            => Null_Unbounded_String,
         Own_Stack_Usage => 0,
         Max_Stack_Usage => 0,
         Calls           => LOSC.Empty_List);

end Stackcheck.Types;
