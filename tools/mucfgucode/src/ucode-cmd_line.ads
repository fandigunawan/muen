--
--  Copyright (C) 2023  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2023  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with Ada.Strings.Unbounded;

with GNAT.Command_Line;

package Ucode.Cmd_Line
is

   --  Init command line, use given tool description in usage output.
   procedure Init (Description : String);

   --  Return path to system policy.
   function Get_Policy return String;

   --  Return path to MCU files.
   function Get_Ucode_Dir return String;

   --  Return output directory.
   function Get_Output_Dir return String;

   Invalid_Cmd_Line : exception;

private

   Policy     : Ada.Strings.Unbounded.Unbounded_String;
   Ucode_Dir  : Ada.Strings.Unbounded.Unbounded_String;
   Output_Dir : Ada.Strings.Unbounded.Unbounded_String;

   Parser : GNAT.Command_Line.Opt_Parser
     := GNAT.Command_Line.Command_Line_Parser;

end Ucode.Cmd_Line;
