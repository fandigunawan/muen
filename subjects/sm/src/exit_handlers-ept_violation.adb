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

with SK;

with Subject.Text_IO;

with Subject_Info;

package body Exit_Handlers.EPT_Violation
is

   use type SK.Word64;
   use Subject_Info;

   --  Type related to EPT violation specific exit qualification.

   type EPTV_Info_Type is record
      Read              : Boolean;
      Write             : Boolean;
      Instruction_Fetch : Boolean;
      Is_Readable       : Boolean;
      Is_Writable       : Boolean;
      Valid_Address     : Boolean;
      Is_Linear_Access  : Boolean;
      NMI_Blocking      : Boolean;
   end record;

   --  Return EPT violation information from exit qualification, as specified
   --  by Intel SDM Vol. 3C, section 27.2.1, table 27-7.
   function To_EPTV_Info (Qualification : SK.Word64) return EPTV_Info_Type;

   MMConf_Base_Address : constant SK.Word64 := 16#f800_0000#;
   MMConf_Size         : constant SK.Word64 := 16#0100_0000#;

   subtype MMConf_Region is SK.Word64 range
     MMConf_Base_Address .. MMConf_Base_Address + MMConf_Size - 1;

   -------------------------------------------------------------------------

   procedure Process (Halt : out Boolean)
   is
      Info : constant EPTV_Info_Type := To_EPTV_Info
        (Qualification => Subject_Info.State.Exit_Qualification);
   begin
      Halt := True;

      if State.Guest_Phys_Addr in MMConf_Region and then Info.Read then

         --  Return 16#ffff# to indicate a non-existent device.

         State.Regs.RAX := 16#ffff#;
         Halt           := False;
      else
         Subject.Text_IO.Put_String (Item => "Invalid ");
         if Info.Read then
            Subject.Text_IO.Put_String (Item => "read");
         else
            Subject.Text_IO.Put_String (Item => "write");
         end if;
         Subject.Text_IO.Put_String
           (Item => " access at guest physical address ");
         Subject.Text_IO.Put_Word64 (Item => State.Guest_Phys_Addr);
         Subject.Text_IO.New_Line;
      end if;
   end Process;

   -------------------------------------------------------------------------

   function To_EPTV_Info (Qualification : SK.Word64) return EPTV_Info_Type
   is
      Info : EPTV_Info_Type;
   begin
      Info.Read              := SK.Bit_Test (Value => Qualification,
                                             Pos   => 0);
      Info.Write             := SK.Bit_Test (Value => Qualification,
                                             Pos   => 1);
      Info.Instruction_Fetch := SK.Bit_Test (Value => Qualification,
                                             Pos   => 2);
      Info.Is_Readable       := SK.Bit_Test (Value => Qualification,
                                             Pos   => 3);
      Info.Is_Writable       := SK.Bit_Test (Value => Qualification,
                                             Pos   => 4);
      Info.Valid_Address     := SK.Bit_Test (Value => Qualification,
                                             Pos   => 7);
      Info.Is_Linear_Access  := SK.Bit_Test (Value => Qualification,
                                             Pos   => 8);
      Info.NMI_Blocking      := SK.Bit_Test (Value => Qualification,
                                             Pos   => 12);
      return Info;
   end To_EPTV_Info;

end Exit_Handlers.EPT_Violation;