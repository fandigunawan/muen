--
--  Copyright (C) 2014  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2014  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

private with Ada.Streams;

package VTd.Tables
is

   --  Maximal number of entries in Interrupt Remapping Table.
   type IR_Entry_Range is range 0 .. 2 ** 16 - 1;

   type Bit_Type is range 0 .. 1
     with
       Size => 1;

private

   type Bit_Array is array (Positive range <>) of Bit_Type
     with
       Pack;

   --  Write given stream to file.
   procedure Write
     (Stream   : Ada.Streams.Stream_Element_Array;
      Filename : String);

end VTd.Tables;