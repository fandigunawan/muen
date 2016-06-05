--
--  Copyright (C) 2016  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2016  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with SK.IO;

with PS2.Constants;

package body PS2.Utils
is

   --  Wait until input buffer is ready for sending data to the PS/2
   --  controller.
   procedure Wait_Input_Ready;

   --  Wait until output buffer is ready for receiving data from the PS/2
   --  controller.
   procedure Wait_Output_Ready;

   --  Returns true if the input buffer is ready for sending data to the PS/2
   --  controller.
   procedure Send_State (Ready : out Boolean);

   --  Returns true if the output buffer is ready for receiving data from the
   --  PS/2 controller.
   procedure Is_Output_Ready (Ready : out Boolean);

   -------------------------------------------------------------------------

   procedure Is_Output_Ready (Ready : out Boolean)
   is
      Status : SK.Byte;
   begin
      SK.IO.Inb (Port  => Constants.STATUS_REGISTER,
                 Value => Status);
      Ready := SK.Bit_Test
        (Value => SK.Word64 (Status),
         Pos   => Constants.OUTPUT_BUFFER_STATUS);
   end Is_Output_Ready;

   -------------------------------------------------------------------------

   procedure Read_Data (Data : out SK.Byte)
   is
   begin
      Wait_Output_Ready;
      SK.IO.Inb (Port  => Constants.DATA_REGISTER,
                 Value => Data);
   end Read_Data;

   -------------------------------------------------------------------------

   procedure Read_Status (Status : out SK.Byte)
   is
   begin
      Wait_Output_Ready;
      SK.IO.Inb (Port  => Constants.STATUS_REGISTER,
                 Value => Status);
   end Read_Status;

   -------------------------------------------------------------------------

   procedure Send_State (Ready : out Boolean)
   is
      Status : SK.Byte;
   begin
      SK.IO.Inb (Port  => Constants.STATUS_REGISTER,
                 Value => Status);
      Ready := not SK.Bit_Test
        (Value => SK.Word64 (Status),
         Pos   => Constants.INPUT_BUFFER_STATUS);
   end Send_State;

   -------------------------------------------------------------------------

   procedure Wait_For_Ack
     (Loops    :     Natural := 1000;
      Timeout  : out Boolean)
   is
      use type SK.Byte;

      Data  : SK.Byte;
      Ready : Boolean;
   begin
      for I in 1 .. Loops loop
         Send_State (Ready => Ready);
         if Ready then
            SK.IO.Inb (Port  => Constants.DATA_REGISTER,
                       Value => Data);
            if Data = Constants.ACKNOWLEDGE then
               Timeout := False;
               return;
            end if;
         end if;
      end loop;

      Timeout := True;
   end Wait_For_Ack;

   -------------------------------------------------------------------------

   procedure Wait_Input_Ready
   is
      Ready : Boolean;
   begin
      loop
         Send_State (Ready => Ready);
         exit when Ready;
      end loop;
   end Wait_Input_Ready;

   -------------------------------------------------------------------------

   procedure Wait_Output_Ready
   is
      Ready : Boolean;
   begin
      loop
         Is_Output_Ready (Ready => Ready);
         exit when Ready;
      end loop;
   end Wait_Output_Ready;

   -------------------------------------------------------------------------

   procedure Write_Aux (Data : SK.Byte)
   is
   begin
      Write_Command (Cmd  => Constants.WRITE_TO_AUX);
      Write_Data    (Data => Data);
   end Write_Aux;

   -------------------------------------------------------------------------

   procedure Write_Command (Cmd : SK.Byte)
   is
   begin
      Wait_Input_Ready;
      SK.IO.Outb (Port  => Constants.COMMAND_REGISTER,
                  Value => Cmd);
   end Write_Command;

   -------------------------------------------------------------------------

   procedure Write_Data (Data : SK.Byte)
   is
   begin
      Wait_Input_Ready;
      SK.IO.Outb (Port  => Constants.DATA_REGISTER,
                  Value => Data);
   end Write_Data;

end PS2.Utils;
