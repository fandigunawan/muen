--
--  Copyright (C) 2018  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2018  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with Mulog;
with Mutools.Files;
with Mutools.Utils;

with Paging.ARMv8a.Stage1;
with Paging.ARMv8a.Stage2;
with Paging.Entries;
with Paging.EPT;
with Paging.IA32e;

package body Ptwalk
is

   type Entry_Deserializer is not null access procedure
     (Stream      : not null access Ada.Streams.Root_Stream_Type'Class;
      Table_Entry : out Paging.Entries.Table_Entry_Type);

   type Deserializer_Array is array (Paging.Paging_Level)
     of Entry_Deserializer;

   Deserializers : constant array
     (Paging.Paging_Mode_Type) of Deserializer_Array
     := (Paging.IA32e_Mode =>
           (1 => Paging.IA32e.Deserialize_PML4_Entry'Access,
            2 => Paging.IA32e.Deserialize_PDPT_Entry'Access,
            3 => Paging.IA32e.Deserialize_PD_Entry'Access,
            4 => Paging.IA32e.Deserialize_PT_Entry'Access),
         Paging.EPT_Mode   =>
           (1 => Paging.EPT.Deserialize_PML4_Entry'Access,
            2 => Paging.EPT.Deserialize_PDPT_Entry'Access,
            3 => Paging.EPT.Deserialize_PD_Entry'Access,
            4 => Paging.EPT.Deserialize_PT_Entry'Access),
         Paging.ARMv8a_Stage1_Mode   =>
           (1 => Paging.ARMv8a.Stage1.Deserialize_Level0_Entry'Access,
            2 => Paging.ARMv8a.Stage1.Deserialize_Level1_Entry'Access,
            3 => Paging.ARMv8a.Stage1.Deserialize_Level2_Entry'Access,
            4 => Paging.ARMv8a.Stage1.Deserialize_Level3_Entry'Access),
         Paging.ARMv8a_Stage2_Mode   =>
           (1 => Paging.ARMv8a.Stage2.Deserialize_Level0_Entry'Access,
            2 => Paging.ARMv8a.Stage2.Deserialize_Level1_Entry'Access,
            3 => Paging.ARMv8a.Stage2.Deserialize_Level2_Entry'Access,
            4 => Paging.ARMv8a.Stage2.Deserialize_Level3_Entry'Access));

   ----------------------------------------------------------------------...

   procedure Do_Walk
     (Virtual_Address :     Interfaces.Unsigned_64;
      File            :     Ada.Streams.Stream_IO.File_Type;
      PT_Pointer      :     Interfaces.Unsigned_64;
      PT_Type         :     Paging.Paging_Mode_Type;
      Level           :     Paging.Paging_Level;
      PT_Address      :     Interfaces.Unsigned_64;
      Success         : out Boolean;
      Translated_Addr : out Interfaces.Unsigned_64)
   is
      use type Ada.Streams.Stream_IO.Count;
      use type Interfaces.Unsigned_64;

      Entry_Idx : constant Paging.Entry_Range
        := Paging.Get_Index
          (Address => Virtual_Address,
           Level   => Level);

      Table_File_Idx : Ada.Streams.Stream_IO.Count;
      PT_Entry       : Paging.Entries.Table_Entry_Type;
   begin
      if PT_Address < PT_Pointer then
         Mulog.Log (Msg => "Invalid paging structure reference: Address below"
                    & " given PT pointer ("
                    & Mutools.Utils.To_Hex (Number => PT_Address) & " < "
                    & Mutools.Utils.To_Hex (Number => PT_Pointer));
         Success := False;
         Translated_Addr := 0;
         return;
      end if;

      --  Add one because file index starts at one while page table ranges
      --  start at zero.

      Table_File_Idx := Ada.Streams.Stream_IO.Count
        (PT_Address - PT_Pointer + 1) + Ada.Streams.Stream_IO.Count (Entry_Idx)
        * 8;
      if Table_File_Idx > Ada.Streams.Stream_IO.Size (File => File) then
         Mulog.Log (Msg => "Invalid paging structure reference: Address outside"
                    & " of file");
         Success := False;
         Translated_Addr := 0;
         return;
      end if;
      Ada.Streams.Stream_IO.Set_Index
        (File => File,
         To   => Table_File_Idx);

      Deserializers (PT_Type)(Level)
        (Stream      => Ada.Streams.Stream_IO.Stream (File),
         Table_Entry => PT_Entry);

      Mulog.Log (Msg => " Level" & Level'Img & ": "
                 & Mutools.Utils.To_Hex (Number => PT_Entry.Get_Dst_Address)
                 & " "
                 & (if PT_Entry.Is_Present then "P" else "-")
                 & (if PT_Entry.Is_Readable then "R" else "-")
                 & (if PT_Entry.Is_Writable then "W" else "-")
                 & (if PT_Entry.Is_Executable then "X" else "-")
                 & ", " & PT_Entry.Get_Caching'Img
                 & (if PT_Entry.Maps_Page then ", maps page" else ""));

      if not PT_Entry.Is_Present or else PT_Entry.Maps_Page
      then
         Success := PT_Entry.Is_Present and PT_Entry.Maps_Page;
         Translated_Addr
           := (if not Success then 0
               else PT_Entry.Get_Dst_Address + Paging.Get_Offset
                 (Address => Virtual_Address,
                  Level   => Level));
         return;
      end if;

      Do_Walk (Virtual_Address => Virtual_Address,
               File            => File,
               PT_Pointer      => PT_Pointer,
               PT_Type         => PT_Type,
               Level           => Level + 1,
               PT_Address      => PT_Entry.Get_Dst_Address,
               Success         => Success,
               Translated_Addr => Translated_Addr);
   end Do_Walk;

   -------------------------------------------------------------------------

   procedure Run
     (Table_File      : String;
      Table_Type      : Paging.Paging_Mode_Type;
      Table_Pointer   : Interfaces.Unsigned_64;
      Start_Level     : Paging.Paging_Level;
      Virtual_Address : Interfaces.Unsigned_64)
   is
      PT_File : Ada.Streams.Stream_IO.File_Type;
   begin
      Mulog.Log (Msg => "Using " & Table_Type'Img
                 & " pagetable file '" & Table_File & "'");
      Mutools.Files.Open (Filename => Table_File,
                          File     => PT_File,
                          Writable => False);

      Mulog.Log (Msg => "Pagetable pointer address set to "
                 & Mutools.Utils.To_Hex (Number => Table_Pointer));

      Mulog.Log (Msg => "Translation of virtual address "
                 & Mutools.Utils.To_Hex (Number => Virtual_Address));

      Mulog.Log (Msg => "Page table walk starting at level" & Start_Level'Img);

      declare
         Success     : Boolean;
         Target_Addr : Interfaces.Unsigned_64;
      begin
         Do_Walk (Virtual_Address => Virtual_Address,
                  File            => PT_File,
                  PT_Pointer      => Table_Pointer,
                  PT_Type         => Table_Type,
                  Level           => Start_Level,
                  PT_Address      => Table_Pointer,
                  Success         => Success,
                  Translated_Addr => Target_Addr);
         Ada.Streams.Stream_IO.Close (File => PT_File);

         if Success then
            Mulog.Log (Msg => "Address "
                       & Mutools.Utils.To_Hex (Number => Virtual_Address)
                       & " translates to "
                       & Mutools.Utils.To_Hex (Number => Target_Addr));
         else
            Mulog.Log (Msg => "No valid translation for address "
                       & Mutools.Utils.To_Hex (Number => Virtual_Address));
         end if;

      exception
         when others =>
            Ada.Streams.Stream_IO.Close (File => PT_File);
            raise;
      end;
   end Run;

end Ptwalk;
